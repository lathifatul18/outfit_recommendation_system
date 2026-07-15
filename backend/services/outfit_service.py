import os
import json
import logging
import numpy as np
import random
import traceback

from extensions import db
from models.fashion_item import FashionItem
from services.outfit_rules import OUTFIT_RULES
from sklearn.metrics.pairwise import cosine_similarity
from services.dataset_cache import DATASET_CACHE

logger = logging.getLogger(__name__)

BASE_FOLDER = os.path.join(
    os.getcwd(),
    "outfit_items_dataset"
)

UPLOAD_FOLDER = os.path.join(
    os.getcwd(),
    "uploads"
)


def _build_image_path(item, is_upload=False):
    """
    Helper untuk build URL gambar relatif ke API.
    Support:
    - FashionItem object
    - dictionary dari DATASET_CACHE
    """

    # Ambil path gambar
    if isinstance(item, dict):
        gambar_path = item.get("gambar")
    else:
        gambar_path = item.gambar

    if not gambar_path:
        return ""

    # Jika sudah URL API, jangan convert lagi
    if gambar_path.startswith("/api/images"):
        return gambar_path

    # Upload item
    if is_upload:
        upload_filename = os.path.basename(gambar_path)
        return f"/api/images/uploads/{upload_filename}"

    # Dataset absolute path
    if os.path.isabs(gambar_path):
        try:
            relative = os.path.relpath(
                gambar_path,
                BASE_FOLDER
            ).replace("\\", "/")

            return f"/api/images/{relative}"

        except ValueError:
            upload_filename = os.path.basename(gambar_path)
            return f"/api/images/uploads/{upload_filename}"

    # Dataset relative path
    clean = gambar_path.replace("\\", "/")

    if clean.startswith("uploads/"):
        return f"/api/images/{clean}"

    return f"/api/images/{clean}"

def get_best_match(reference_item, subcategories):
    """
    reference_item = FashionItem ATAU dict recommendation.
    return = dict dataset item
    """

    if reference_item is None:
        return None, 0.0

    try:
        if isinstance(reference_item, FashionItem):
            embedding_json = reference_item.embedding_vector

        else:
            embedding_json = reference_item.get("embedding_vector")

        if embedding_json is None:
            return None, 0.0

        reference_vector = np.array(
            json.loads(embedding_json),
            dtype=np.float32
        )

    except Exception:
        return None, 0.0

    candidates = []

    for sub in subcategories:
        candidates.extend(DATASET_CACHE.get(sub, []))

    if not candidates:
        return None, 0.0

    vectors = np.array(
        [c["vector"] for c in candidates],
        dtype=np.float32
    )

    ref_norm = np.linalg.norm(reference_vector)
    if ref_norm > 0:
        reference_vector /= ref_norm

    row_norms = np.linalg.norm(
        vectors,
        axis=1,
        keepdims=True
    )

    row_norms[row_norms == 0] = 1

    vectors /= row_norms

    similarities = vectors.dot(reference_vector)

    idx = np.argmax(similarities)

    return candidates[idx], float(similarities[idx])

def generate_outfit(item_id):
    """
    Generate outfit recommendation lengkap dari item yang diupload.

    Returns dict dengan:
    - uploaded_item
    - matched_item (+ similarity_score)
    - upperwear / bottomwear / footwear / accessories (sesuai rule)

    Atau dict {"error": "..."} jika terjadi kesalahan.
    """
    logger.info(f"[generate_outfit] Memulai untuk item_id={item_id}")

    # 1. Dapatkan uploaded item
    item = db.session.get(FashionItem, item_id)

    if item is None:
        msg = f"Item dengan id={item_id} tidak ditemukan di database"
        logger.error(f"[generate_outfit] {msg}")
        return {"error": msg}

    if not item.embedding_vector:
        msg = f"Item id={item_id} tidak memiliki embedding_vector. Upload mungkin gagal."
        logger.error(f"[generate_outfit] {msg}")
        return {"error": msg}

    logger.info(
        f"[generate_outfit] Item ditemukan: id={item.id_item}, "
        f"nama={item.nama_item}, sub_category={item.sub_category}"
    )

    # 2. Cari item dataset yang paling mirip (cosine similarity)
    from services.recommendation_service import get_recommendation_items

    recommendations = get_recommendation_items(item)

    matched_item = None
    matched_score = 0.0

    if recommendations:
        matched_item = recommendations[0]
        matched_score = matched_item["score"]

        logger.info(
            f"[generate_outfit] Matched item: "
            f"id={matched_item['id_item']}, "
            f"nama={matched_item['nama_item']}, "
            f"score={matched_score:.4f}"
        )
    else:
        return {
            "error": "Tidak ada recommendation ditemukan."
        }

    # 3. Tentukan sub_category untuk rule lookup
    sub_cat = matched_item["sub_category"]
    if not sub_cat:
        # Fallback: coba dari uploaded item
        sub_cat = matched_item["sub_category"]

    if not sub_cat:
        msg = "sub_category tidak ditemukan pada item"
        logger.error(f"[generate_outfit] {msg}")
        return {"error": msg}

    rule = OUTFIT_RULES.get(sub_cat)

    if rule is None:
        sub_cat_clean = sub_cat.strip().lower()
        rule = OUTFIT_RULES.get(sub_cat_clean)
        if rule is None:
            logger.warning(
                f"[generate_outfit] Rule tidak ditemukan untuk sub_category='{sub_cat}'. "
                f"Outfit akan hanya berisi uploaded & matched item."
            )

    # 4. Bangun outfit response
    outfit = {
        "uploaded_item": {
            "id_item": item.id_item,
            "nama_item": item.nama_item,
            "sub_category": item.sub_category or "unknown",
            "gambar": _build_image_path(item, is_upload=True)
        },
        "matched_item": {
            "id_item": matched_item["id_item"],
            "nama_item": matched_item["nama_item"],
            "sub_category": matched_item["sub_category"],
            "gambar": matched_item["gambar"],
            "score": round(float(matched_score), 4)
        }
    }

    logger.info(f"[generate_outfit] uploaded_item gambar: {outfit['uploaded_item']['gambar']}")
    logger.info(f"[generate_outfit] matched_item gambar: {outfit['matched_item']['gambar']}")

    if rule is None:
        logger.info(f"[generate_outfit] Tidak ada rule, hanya uploaded_item + matched_item")
        return outfit

    if "upperwear" in rule:
        try:
            result_item, score = get_best_match(item, rule["upperwear"])
            if result_item is not None:
                outfit["upperwear"] = {
                    "id_item": result_item["id_item"],
                    "nama_item": result_item["nama_item"],
                    "sub_category": result_item["sub_category"],
                    "gambar": _build_image_path(result_item, False),
                    "score": round(score, 4)
                }
                logger.info(f"[generate_outfit] upperwear: {result_item['nama_item']} ({score:.4f})")
        except Exception as e:
            logger.error(f"[generate_outfit] Error get_best_match upperwear: {e}")

    if "bottomwear" in rule:
        try:
            result_item, score = get_best_match(item, rule["bottomwear"])
            if result_item is not None:
                outfit["bottomwear"] = {
                    "id_item": result_item["id_item"],
                    "nama_item": result_item["nama_item"],
                    "sub_category": result_item["sub_category"],
                    "gambar": _build_image_path(result_item, False),
                    "score": round(score, 4)
                }
                logger.info(f"[generate_outfit] bottomwear: {result_item['nama_item']} ({score:.4f})")
        except Exception as e:
            logger.error(f"[generate_outfit] Error get_best_match bottomwear: {e}")

    if "footwear" in rule:
        try:
            result_item, score = get_best_match(item, rule["footwear"])
            if result_item is not None:
                outfit["footwear"] = {
                    "id_item": result_item["id_item"],
                    "nama_item": result_item["nama_item"],
                    "sub_category": result_item["sub_category"],
                    "gambar": _build_image_path(result_item, False),
                    "score": round(score, 4)
                }
                logger.info(f"[generate_outfit] footwear: {result_item['nama_item']} ({score:.4f})")
        except Exception as e:
            logger.error(f"[generate_outfit] Error get_best_match footwear: {e}")

    if "accessories" in rule:
        try:
            result_item, score = get_best_match(item, rule["accessories"])
            if result_item is not None:
                outfit["accessories"] = {
                    "id_item": result_item["id_item"],
                    "nama_item": result_item["nama_item"],
                    "sub_category": result_item["sub_category"],
                    "gambar": _build_image_path(result_item, False),
                    "score": round(score, 4)
                }
                logger.info(f"[generate_outfit] accessories: {result_item['nama_item']} ({score:.4f})")
        except Exception as e:
            logger.error(f"[generate_outfit] Error get_best_match accessories: {e}")

    logger.info(f"[generate_outfit] Selesai. Keys outfit: {list(outfit.keys())}")
    return outfit

def _build_dataset_image_url(path):
    """
    Convert absolute dataset path menjadi API URL
    """

    if not path:
        return ""

    try:
        if os.path.isabs(path):
            relative = os.path.relpath(
                path,
                BASE_FOLDER
            ).replace("\\", "/")

            return f"/api/images/{relative}"

        clean = path.replace("\\", "/")

        if clean.startswith("/api/images"):
            return clean

        return f"/api/images/{clean}"

    except Exception as e:
        logger.error(f"Build image url error: {e}")
        return ""