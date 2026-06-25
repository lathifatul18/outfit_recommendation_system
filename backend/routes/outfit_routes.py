from flask import Blueprint
from services.outfit_service import generate_outfit

outfit_bp = Blueprint(
    "outfit",
    __name__
)

@outfit_bp.route("/generate/<int:item_id>", methods=["GET"])

def generate(item_id):

    result = generate_outfit(item_id)

    return {
        "status": True,
        "outfit": result
    }