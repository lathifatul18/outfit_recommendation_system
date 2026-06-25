import json
import numpy as np

from sklearn.metrics.pairwise import cosine_similarity
from models.fashion_item import FashionItem


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
    
    source_vector = json.loads(
        item.embedding_vector
    )

    items = FashionItem.query.all()

    results = []

    for other in items:

        if other.id_item == item.id_item:
            continue

        other_vector = json.loads(
            other.embedding_vector
        )

        score = calculate_similarity(
            source_vector,
            other_vector
        )

        results.append({
            "id_item": other.id_item,
            "nama_item": other.nama_item,
            "gambar": other.gambar,
            "score": float(score)
        })
    
    results.sort(
        key=lambda x: x["score"],
        reverse=True
    )

    return results[:10]