import logging
import traceback
import os
import json
import numpy as np

from flask import Blueprint, request, jsonify
from werkzeug.utils import secure_filename
from models.fashion_item import FashionItem
from extensions import db
from services.embedding_service import extract_embedding

logger = logging.getLogger(__name__)

fashion_bp = Blueprint(
    "fashion",
    __name__
)

UPLOAD_FOLDER = os.path.join(os.getcwd(), "uploads")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp", "gif", "bmp"}

# Memory cache for fast dataset classification
_DATASET_CACHE = None


def allowed_file(filename):
    """Cek apakah extension file diizinkan."""
    return (
        "." in filename
        and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS
    )


def get_dataset_embeddings():
    """
    Load representative dataset embeddings ke memory cache untuk
    auto-classification (kecepatan tinggi).
    
    Optimized: single batch query, reduced sample size (20 per sub_category).
    """
    global _DATASET_CACHE
    if _DATASET_CACHE is not None:
        return _DATASET_CACHE

    import time as _time
    t_start = _time.time()
    logger.info("[fashion] Loading dataset embeddings ke memory cache...")

    # Query dalam satu batch — ambil 20 per sub_category (cukup untuk classification)
    SAMPLE_PER_SUB = 20

    sub_cats = [
        "bag", "dress", "flats", "hat", "heels",
        "jacket", "pants", "shirt", "shoes",
        "shorts", "skirt", "sneakers", "tshirt"
    ]

    categories = []
    sub_categories = []
    colors = []
    patterns = []
    vectors = []

    for sub in sub_cats:
        t_sub = _time.time()
        # Hanya ambil kolom yang diperlukan (tanpa embedding_vector dulu)
        # lalu ambil embedding_vector secara terpisah untuk mengurangi memory
        results = db.session.query(
            FashionItem.id_category,
            FashionItem.sub_category,
            FashionItem.id_color,
            FashionItem.pattern,
            FashionItem.embedding_vector
        ).filter(
            FashionItem.source_type == "dataset",
            FashionItem.sub_category == sub,
            FashionItem.embedding_vector.isnot(None)
        ).limit(SAMPLE_PER_SUB).all()

        parsed_count = 0
        for row in results:
            try:
                vec = json.loads(row.embedding_vector)
                if len(vec) == 2048:
                    vectors.append(vec)
                    categories.append(row.id_category)
                    sub_categories.append(row.sub_category)
                    colors.append(row.id_color)
                    patterns.append(row.pattern)
                    parsed_count += 1
            except Exception:
                continue

        logger.info(
            f"[fashion]   sub={sub}: {parsed_count}/{len(results)} items "
            f"parsed in {_time.time() - t_sub:.2f}s"
        )

    if vectors:
        t_norm = _time.time()
        vectors_matrix = np.array(vectors, dtype=np.float32)
        norms = np.linalg.norm(vectors_matrix, axis=1, keepdims=True)
        norms = np.where(norms == 0, 1.0, norms)
        normalized_matrix = vectors_matrix / norms

        _DATASET_CACHE = (
            normalized_matrix,
            categories,
            sub_categories,
            colors,
            patterns
        )
        logger.info(f"[fashion]   Normalization done in {_time.time() - t_norm:.2f}s")
    else:
        logger.warning("[fashion] Dataset embeddings tidak tersedia. Auto-classification tidak aktif.")
        _DATASET_CACHE = (None, [], [], [], [])

    total_time = _time.time() - t_start
    logger.info(f"[fashion] Loaded {len(categories)} dataset items ke cache in {total_time:.2f}s")
    return _DATASET_CACHE


@fashion_bp.route("/upload", methods=["POST"])
def upload_fashion():
    """
    Upload gambar pakaian dari pengguna.
    Sistem otomatis:
    1. Simpan gambar dengan nama aman (secure_filename)
    2. Ekstrak embedding menggunakan ResNet50
    3. Auto-classify category, sub_category, color, pattern
       menggunakan cosine similarity ke dataset
    4. Simpan ke database
    5. Return id_item untuk generate outfit
    """
    logger.info("[upload] Menerima request upload gambar")

    image = request.files.get("image")

    if image is None:
        logger.warning("[upload] Tidak ada file gambar dalam request")
        return jsonify({
            "status": False,
            "message": "Tidak ada file gambar. Pastikan field 'image' diisi."
        }), 400

    if image.filename == "":
        logger.warning("[upload] Filename kosong")
        return jsonify({
            "status": False,
            "message": "Nama file tidak valid."
        }), 400

    if not allowed_file(image.filename):
        logger.warning(f"[upload] Extension tidak diizinkan: {image.filename}")
        return jsonify({
            "status": False,
            "message": f"Format file tidak didukung. Gunakan: {', '.join(ALLOWED_EXTENSIONS)}"
        }), 400

    try:
        safe_name = secure_filename(image.filename)
        import time
        base, ext = os.path.splitext(safe_name)
        safe_name = f"{base}_{int(time.time() * 1000)}{ext}"

        filepath = os.path.join(UPLOAD_FOLDER, safe_name)
        image.save(filepath)
        logger.info(f"[upload] Gambar disimpan: {filepath}")

        logger.info("[upload] Mengekstrak embedding ResNet50...")
        vector = extract_embedding(filepath)
        logger.info(f"[upload] Embedding berhasil diekstrak, shape={vector.shape}")

        nama_item = request.form.get("nama_item", "")
        source_type = request.form.get("source_type") or "upload"

        id_category = request.form.get("id_category")
        sub_category = request.form.get("sub_category")
        id_color = request.form.get("id_color")
        pattern = request.form.get("pattern")

        if not all([id_category, sub_category, id_color, pattern]):
            logger.info("[upload] Metadata tidak lengkap, menjalankan auto-classification...")
            try:
                normalized_matrix, categories, sub_categories, colors, patterns = get_dataset_embeddings()

                if normalized_matrix is not None and len(categories) > 0:
                    input_norm = np.linalg.norm(vector)
                    input_norm = 1.0 if input_norm == 0 else input_norm
                    normalized_input = (vector / input_norm).astype(np.float32)

                    similarities = np.dot(normalized_matrix, normalized_input)
                    best_idx = int(np.argmax(similarities))
                    best_score = float(similarities[best_idx])

                    id_category = id_category or categories[best_idx]
                    sub_category = sub_category or sub_categories[best_idx]
                    id_color = id_color or colors[best_idx]
                    pattern = pattern or patterns[best_idx]

                    logger.info(
                        f"[upload] Auto-classified: category={id_category}, "
                        f"sub={sub_category}, color={id_color}, "
                        f"pattern={pattern}, score={best_score:.4f}"
                    )
                else:
                    id_category = id_category or 1
                    sub_category = sub_category or "tshirt"
                    id_color = id_color or 1
                    pattern = pattern or "Solid"
                    logger.warning("[upload] Auto-classification tidak aktif, pakai nilai default")
            except Exception as e:
                logger.error(f"[upload] Auto-classification error: {e}")
                id_category = id_category or 1
                sub_category = sub_category or "tshirt"
                id_color = id_color or 1
                pattern = pattern or "Solid"

        if not nama_item:
            name_map = {
                "jacket": "Jaket Saya",
                "shirt": "Kemeja Saya",
                "tshirt": "Kaos Saya",
                "dress": "Dress Saya",
                "pants": "Celana Saya",
                "shorts": "Celana Pendek Saya",
                "skirt": "Rok Saya",
                "flats": "Sepatu Flats Saya",
                "heels": "High Heels Saya",
                "shoes": "Sepatu Saya",
                "sneakers": "Sepatu Sneakers Saya",
                "bag": "Tas Saya",
                "hat": "Topi Saya"
            }
            nama_item = name_map.get(str(sub_category), "Pakaian Saya")

        logger.info(
            f"[upload] Menyimpan item: nama={nama_item}, "
            f"sub={sub_category}, cat={id_category}"
        )

        new_item = FashionItem(
            nama_item=nama_item,
            source_type=source_type,
            gambar=filepath,
            id_category=int(id_category),
            sub_category=str(sub_category),
            id_color=int(id_color),
            pattern=str(pattern),
            id_user=1,
            embedding_vector=json.dumps(vector.tolist())
        )

        db.session.add(new_item)
        db.session.commit()

        logger.info(f"[upload] Item berhasil disimpan dengan id_item={new_item.id_item}")

        return jsonify({
            "status": True,
            "message": "Fashion item berhasil ditambahkan",
            "data": {
                "id_item": new_item.id_item,
                "nama_item": new_item.nama_item,
                "sub_category": new_item.sub_category,
                "gambar": new_item.gambar
            }
        }), 201

    except Exception as e:
        logger.error(f"[upload] Exception: {e}")
        logger.error(traceback.format_exc())
        # Coba hapus file yang sudah tersimpan jika DB error
        try:
            if 'filepath' in locals() and os.path.exists(filepath):
                os.remove(filepath)
        except Exception:
            pass
        return jsonify({
            "status": False,
            "message": f"Upload gagal: {str(e)}"
        }), 500


@fashion_bp.route("/inspirations", methods=["GET"])
def get_inspirations():
    """
    Ambil random sample fashion items dari dataset untuk InspirationGrid.
    Mengembalikan gambar dengan URL yang siap pakai oleh frontend.
    """
    import random as _random

    BASE_FOLDER = os.path.join(os.getcwd(), "outfit_items_dataset")
    UPLOAD_FOLDER_LOCAL = os.path.join(os.getcwd(), "uploads")

    limit = request.args.get("limit", 12, type=int)

    try:
        items = FashionItem.query.filter(
            FashionItem.source_type == "dataset"
        ).all()

        if not items:
            return jsonify({"status": True, "data": []})

        # Random sample agar berbeda setiap kali dimuat
        sample_size = min(limit, len(items))
        sampled = _random.sample(items, sample_size)

        data = []
        for item in sampled:
            # Build image URL
            gambar = item.gambar or ""
            if os.path.isabs(gambar):
                if UPLOAD_FOLDER_LOCAL in gambar or "uploads" in gambar.lower():
                    image_url = f"/api/images/uploads/{os.path.basename(gambar)}"
                else:
                    try:
                        rel = os.path.relpath(gambar, BASE_FOLDER).replace("\\", "/")
                        image_url = f"/api/images/{rel}"
                    except ValueError:
                        image_url = f"/api/images/uploads/{os.path.basename(gambar)}"
            else:
                clean = gambar.replace("\\", "/")
                image_url = f"/api/images/{clean}" if clean else ""

            data.append({
                "id_item": item.id_item,
                "nama_item": item.nama_item,
                "sub_category": item.sub_category or "clothing",
                "gambar": image_url
            })

        logger.info(f"[inspirations] Mengembalikan {len(data)} item inspirasi")
        return jsonify({"status": True, "data": data})

    except Exception as e:
        logger.error(f"[inspirations] Error: {e}")
        return jsonify({"status": False, "message": str(e)}), 500


@fashion_bp.route("/", methods=["GET"])
def get_fashion_items():
    items = FashionItem.query.all()
    data = []
    for item in items:
        data.append({
            "id_item": item.id_item,
            "nama_item": item.nama_item,
            "sub_category": item.sub_category or "",
            "source_type": item.source_type,
            "gambar": item.gambar,
            "id_category": item.id_category,
            "id_color": item.id_color,
            "id_user": item.id_user,
            "pattern": item.pattern
        })
    return jsonify({"status": True, "data": data})


@fashion_bp.route("/<int:id>", methods=["GET"])
def get_fashion_by_id(id):
    item = db.session.get(FashionItem, id)
    if item is None:
        return jsonify({
            "status": False,
            "message": "item tidak ditemukan"
        }), 404

    return jsonify({
        "status": True,
        "data": {
            "id_item": item.id_item,
            "nama_item": item.nama_item,
            "sub_category": item.sub_category or "",
            "source_type": item.source_type,
            "gambar": item.gambar,
            "id_category": item.id_category,
            "id_color": item.id_color,
            "id_user": item.id_user,
            "pattern": item.pattern
        }
    })


@fashion_bp.route("/category/<int:id>", methods=["GET"])
def get_fashion_by_category(id):
    items = FashionItem.query.filter_by(id_category=id).all()
    data = []
    for item in items:
        data.append({
            "id_item": item.id_item,
            "nama_item": item.nama_item,
            "gambar": item.gambar,
            "pattern": item.pattern
        })
    return jsonify({"status": True, "data": data})


@fashion_bp.route("/color/<int:id>", methods=["GET"])
def get_by_color(id):
    items = FashionItem.query.filter_by(id_color=id).all()
    data = []
    for item in items:
        data.append({
            "id_item": item.id_item,
            "nama_item": item.nama_item,
            "gambar": item.gambar
        })
    return jsonify({"status": True, "data": data})