import logging
import traceback
from flask import Blueprint, jsonify
from services.recommendation_service import get_recommendation

logger = logging.getLogger(__name__)

recommendation_bp = Blueprint(
    "recommendation",
    __name__
)


@recommendation_bp.route("/item/<int:item_id>", methods=["GET"])
def generate_recommendation(item_id):
    """
    Endpoint rekomendasi item berdasarkan cosine similarity.
    Mengembalikan daftar item dataset yang paling mirip dengan item_id.
    """
    try:
        logger.info(f"[recommendation] Request untuk item_id={item_id}")
        data = get_recommendation(item_id)
        logger.info(f"[recommendation] Ditemukan {len(data)} item mirip")
        return jsonify({
            "status": True,
            "recommendation": data
        })
    except Exception as e:
        logger.error(f"[recommendation] Exception untuk item_id={item_id}: {e}")
        logger.error(traceback.format_exc())
        return jsonify({
            "status": False,
            "message": f"Error saat mencari rekomendasi: {str(e)}"
        }), 500