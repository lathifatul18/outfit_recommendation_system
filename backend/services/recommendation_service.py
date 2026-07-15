import json
import logging
import numpy as np
import os

from sklearn.metrics.pairwise import cosine_similarity
from extensions import db
from models.fashion_item import FashionItem
from services.dataset_cache import DATASET_CACHE


logger = logging.getLogger(__name__)

BASE_FOLDER = os.path.join(
    os.getcwd(),
    "outfit_items_dataset"
)


def calculate_similarity(source_vector, target_vector):
    """Hitung cosine similarity antara dua vector."""
    score = cosine_similarity(
        [source_vector],
        [target_vector]
    )
    return score[0][0]


def get_recommendation_items(item):
    """
    Cari item dataset yang paling mirip dengan item yang diberikan
    menggunakan cosine similarity.

    Menerima FashionItem object langsung (bukan item_id) untuk menghindari
    query ulang yang tidak perlu.

    Returns: list of dicts [{"id_item": ..., "nama_item": ..., "gambar": ..., "score": ...}]
    """
    if item is None:
        logger.error("[recommendation] Item is None")
        return []

    if not item.embedding_vector:
        logger.error(f"[recommendation] Item id={item.id_item} tidak memiliki embedding_vector")
        return []

    try:
        source_vector = np.array(
            json.loads(item.embedding_vector),
            dtype=np.float32
        )
    except (json.JSONDecodeError, TypeError) as e:
        logger.error(f"[recommendation] Gagal parse embedding item id={item.id_item}: {e}")
        return []

    logger.info(
        f"[recommendation] Mencari item mirip untuk id={item.id_item}, "
        f"sub_category={item.sub_category}"
    )

    dataset_items = DATASET_CACHE.get(
    item.sub_category,
    []
)

    if not dataset_items:
        logger.warning(
            f"[recommendation] Tidak ada dataset item untuk sub_category={item.sub_category}"
        )
        return []

    logger.info(f"[recommendation] Membandingkan dengan {len(dataset_items)} dataset items")

    valid_items = []
    vectors = []

    for other in dataset_items:
            vec = other["vector"]
            
            if len(vec) == len(source_vector):
                valid_items.append(other)
                vectors.append(vec)

    if not vectors:
        logger.warning("[recommendation] Tidak ada item dengan embedding valid")
        return []

    vectors_matrix = np.array(vectors, dtype=np.float32)

    src_norm = np.linalg.norm(source_vector)
    if src_norm > 0:
        normalized_source = source_vector / src_norm
    else:
        normalized_source = source_vector

    row_norms = np.linalg.norm(vectors_matrix, axis=1, keepdims=True)
    row_norms = np.where(row_norms == 0, 1.0, row_norms)
    normalized_matrix = vectors_matrix / row_norms

    similarities = normalized_matrix.dot(normalized_source)

    results = []
    for i, other in enumerate(valid_items):
        score = float(similarities[i])

        # Build image URL
        gambar = other["gambar"]

        try:
            if gambar.startswith("/api/images"):
                image_url = gambar

            elif os.path.isabs(gambar):
                relative_path = os.path.relpath(
                    gambar,
                    BASE_FOLDER
                ).replace("\\", "/")

                image_url = f"/api/images/{relative_path}"

            else:
                clean_path = gambar.replace("\\", "/")
                image_url = f"/api/images/{clean_path}"

        except Exception as e:
            logger.error(f"[recommendation] Error build image URL: {e}")
            image_url = ""

        results.append({
            "id_item": other["id_item"],
            "nama_item": other["nama_item"],
            "sub_category": other["sub_category"],
            "gambar": image_url,
            "embedding_vector": json.dumps(
                other["vector"].tolist()
            ),
            "score": score
        })

    results.sort(key=lambda x: x["score"], reverse=True)

    logger.info(
        f"[recommendation] Top result: id={results[0]['id_item']}, "
        f"score={results[0]['score']:.4f}"
    ) if results else None

    return results[:10]


def get_recommendation(item_id):
    """
    Versi lama — tetap dipertahankan untuk backward compatibility.
    Menerima item_id, query item dari DB, lalu panggil get_recommendation_items.
    """
    item = db.session.get(FashionItem, item_id)

    if item is None:
        logger.error(f"[recommendation] Item id={item_id} tidak ditemukan")
        return []

    return get_recommendation_items(item)