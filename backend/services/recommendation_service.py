import json
import numpy as np
import os

from sklearn.metrics.pairwise import cosine_similarity
from models.fashion_item import FashionItem


BASE_FOLDER = os.path.join(
    os.getcwd(),
    "outfit_items_dataset"
)

def calculate_similarity(
        source_vector,
        target_vector
):
    score = cosine_similarity(
        [source_vector],
        [target_vector]
    )
    return score[0][0]

def get_recommendation(
        item_id
):
    
    item = FashionItem.query.get(
        item_id
    )
    
    if item is None:

        return []
    
    if not item.embedding_vector:
        return {
            "status": False,
            "message": "Item tidak memiliki embedding vector"
        }
    
    source_vector = json.loads(
        item.embedding_vector
    )

    items = FashionItem.query.all()

    results = []

    for other in items:

        if other.id_item == item.id_item:
            continue

        if not other.embedding_vector:
            continue

        if other.id_category != item.id_category:
            continue

        if other.sub_category != item.sub_category:
            continue
        
        other_vector = json.loads(
            other.embedding_vector
        )

        score = calculate_similarity(
            source_vector,
            other_vector
        )

        relative_path = os.path.relpath(
            other.gambar,
            "outfit_items_dataset"
        )

        relative_path = relative_path.replace("\\", "/")

        results.append({
            "id_item": other.id_item,
            "nama_item": other.nama_item,
            "gambar": f"/api/images/{relative_path}",
            "score": float(score)
        })
    
    results.sort(
        key=lambda x: x["score"],
        reverse=True
    )

    return results[:10]