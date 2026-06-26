import os
import json
import numpy as np
import random

from models.fashion_item import FashionItem
from sqlalchemy.sql.expression import func
from services.outfit_rules import OUTFIT_RULES
from services.recommendation_service import get_recommendation
from sklearn.metrics.pairwise import cosine_similarity


BASE_FOLDER = os.path.join(
    os.getcwd(),
    "outfit_items_dataset"
)

def get_best_match(reference_item, subcategories):

    reference_vector = np.array(
        json.loads(reference_item.embedding_vector)
    )

    candidates = FashionItem.query.filter(
        FashionItem.sub_category.in_(subcategories)
    ).all()

    scored_items = []

    for item in candidates:

        if not item.embedding_vector:
            continue

        item_vector = np.array(
            json.loads(item.embedding_vector)
        )

        score = cosine_similarity(
            [reference_vector],
            [item_vector]
        )[0][0]

        scored_items.append(
            (item,score)
        )
    scored_items.sort(
        key=lambda x: x[1],
        reverse=True
    )

    top_items = scored_items[:5]

    if not top_items:
        return None
    
    selected_item, selected_score = random.choice(top_items)
    
    return selected_item, float(selected_score)

def generate_outfit(item_id):

    item = FashionItem.query.get(item_id)

    if item is None:
        return None
    
    recommendations = get_recommendation(item_id)

    reference_item = item

    if recommendations:
        first_recommendation = recommendations[0]

        reference_item = FashionItem.query.get(
            first_recommendation["id_item"]
        )

    rule = OUTFIT_RULES.get(
        reference_item.sub_category
    )
    
    if rule is None:
        return {
            "error": "Rule tidak ditemukan"
        }
    
    selected_path = os.path.relpath(
        item.gambar,
        BASE_FOLDER
    ).replace("\\", "/")

    outfit = {
        "selected_item": {
            "id_item": item.id_item,
            "nama_item": item.nama_item,
            "sub_category": item.sub_category,
            "gambar": f"/api/images/{selected_path}"
        }
    }

    reference_path = os.path.relpath(
            reference_item.gambar,
            BASE_FOLDER
        ).replace("\\", "/")

    outfit["reference_item"] = {
            "id_item": reference_item.id_item,
            "nama_item": reference_item.nama_item,
            "sub_category": reference_item.sub_category,
            "gambar": f"/api/images/{reference_path}"
        }

    if "bottomwear" in rule:

        bottomwear, bottomwear_score = get_best_match(
            reference_item,
            rule["bottomwear"]
        )

        bottomwear_path = os.path.relpath(
            bottomwear.gambar,
            BASE_FOLDER
        ).replace("\\", "/")

        outfit["bottomwear"] = {
            "id_item": bottomwear.id_item,
            "nama_item": bottomwear.nama_item,
            "gambar": f"/api/images/{bottomwear_path}",
            "score": round(bottomwear_score, 4)
        }

    if "footwear" in rule:

        footwear, footwear_score = get_best_match(
            reference_item,
            rule["footwear"]
        )

        footwear_path = os.path.relpath(
            footwear.gambar,
            BASE_FOLDER
        ).replace("\\", "/")

        outfit["footwear"] = {
            "id_item": footwear.id_item,
            "nama_item": footwear.nama_item,
            "gambar": f"/api/images/{footwear_path}",
            "score": round(footwear_score, 4)
        }

    if "accessories" in rule:

        accessories, accessories_score = get_best_match(
            reference_item,
            rule["accessories"]
        )

        accessories_path = os.path.relpath(
            accessories.gambar,
            BASE_FOLDER
        ).replace("\\", "/")

        outfit["accessories"] = {
            "id_item": accessories.id_item,
            "nama_item": accessories.nama_item,
            "gambar": f"/api/images/{accessories_path}",
            "score": round(accessories_score, 4)
        }

    return outfit