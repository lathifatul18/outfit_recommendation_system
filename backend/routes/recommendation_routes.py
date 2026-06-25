from flask import Blueprint
from services.recommendation_service import (
    get_recommendation
)

recommendation_bp = Blueprint(
    "recommendation",
    __name__
)

@recommendation_bp.route("/item/<int:item_id>", methods=["GET"])

def generate_recommendation(item_id):

    data = get_recommendation(item_id)

    return {
        "status": True,
        "recommendation": data
    }