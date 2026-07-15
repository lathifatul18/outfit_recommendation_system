import logging
import traceback
from flask import Blueprint, jsonify
from services.outfit_service import generate_outfit

logger = logging.getLogger(__name__)

outfit_bp = Blueprint(
    "outfit",
    __name__
)


@outfit_bp.route("/generate/<int:item_id>", methods=["GET"])
def generate(item_id):
    """
    Generate outfit recommendation lengkap untuk item yang diupload.
    Mengembalikan struktur:
    {
        "status": true,
        "outfit": {
            "uploaded_item": {...},
            "matched_item": {...},
            "bottomwear": {...},   
            "footwear": {...},     
            "accessories": {...}  
        }
    }
    """
    try:
        logger.info(f"[OUTFIT] Generate outfit for item_id={item_id}")

        result = generate_outfit(item_id)

        if isinstance(result, dict) and "error" in result:
            error_msg = result["error"]
            logger.error(f"[OUTFIT] generate_outfit() returned error: {error_msg}")
            return jsonify({
                "status": False,
                "message": error_msg
            }), 400

        if not isinstance(result, dict) or "uploaded_item" not in result:
            logger.error(f"[OUTFIT] Invalid outfit result: {result}")
            return jsonify({
                "status": False,
                "message": "Gagal membuat rekomendasi outfit. Data tidak valid."
            }), 500

        logger.info(f"[OUTFIT] Outfit berhasil dibuat untuk item_id={item_id}")
        return jsonify({
            "status": True,
            "outfit": result
        })

    except ValueError as e:
        logger.error(f"[OUTFIT] ValueError untuk item_id={item_id}: {e}")
        return jsonify({
            "status": False,
            "message": f"Item tidak valid: {str(e)}"
        }), 400

    except Exception as e:
        logger.error(f"[OUTFIT] Exception untuk item_id={item_id}: {e}")
        logger.error(traceback.format_exc())
        return jsonify({
            "status": False,
            "message": f"Server error saat generate outfit: {str(e)}"
        }), 500