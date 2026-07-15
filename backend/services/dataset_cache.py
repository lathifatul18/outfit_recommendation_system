import json
import numpy as np
import os

from models.fashion_item import FashionItem


DATASET_CACHE = {}

BASE_FOLDER = os.path.join(
    os.getcwd(),
    "outfit_items_dataset"
)


def build_image_url(path):
    """
    Convert local dataset path menjadi API image URL
    """

    if not path:
        return ""

    try:
        if path.startswith("/api/images"):
            return path

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

    except Exception:
        return ""


def load_dataset_cache():
    global DATASET_CACHE

    DATASET_CACHE.clear()

    items = FashionItem.query.filter(
        FashionItem.source_type == "dataset",
        FashionItem.embedding_vector.isnot(None)
    ).all()

    print(f"Loading {len(items)} dataset items...")

    for item in items:
        try:
            vector = np.array(
                json.loads(item.embedding_vector),
                dtype=np.float32
            )

            DATASET_CACHE.setdefault(
                item.sub_category,
                []
            ).append({
                "id_item": item.id_item,
                "nama_item": item.nama_item,
                "gambar": build_image_url(item.gambar),
                "sub_category": item.sub_category,
                "vector": vector
            })
        except Exception as e:
            print(
                f"Skip item {item.id_item}: {e}"
            )
            continue


    print("=" * 60)
    print("CACHE READY")
    print("Subcategory :", len(DATASET_CACHE))
    print(
        "Total Item :",
        sum(len(v) for v in DATASET_CACHE.values())
    )
    print("=" * 60)