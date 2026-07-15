from flask import Blueprint
from flask import request

from services.favorite_service import add_favorite
from services.favorite_service import get_favorite
from services.favorite_service import delete_favorite 


favorite_bp = Blueprint(
    "favorite",
    __name__
)


@favorite_bp.route("", methods=["POST"])
def add():
    
    data = request.json

    user_id = data.get("user_id")
    item_id = data.get("item_id")

    if not user_id or not item_id:
        return {
            "status": False,
            "message": "user_id dan item_id harus diisi"
        }, 400

    status = add_favorite(
        user_id, 
        item_id
    )

    if not status:
        return {
            "status": False,
            "message": "Item sudah ada di favorit"
        }, 400
    
    return {
        "status": True,
        "message": "Berhasil ditambahkan ke favorit"
    }

@favorite_bp.route("/<int:user_id>", methods=["GET"])
def get_user(user_id):
    
    data = get_favorite(user_id)

    return {
            "status": True,
            "data": data
    }

@favorite_bp.route("", methods=["DELETE"])
def delete():

    data = request.json

    user_id = data.get("user_id")
    item_id = data.get("item_id")

    if not user_id or not item_id:
        return {
            "status": False,
            "message": "user_id dan item_id harus diisi"
        }, 400

    status = delete_favorite(
        user_id,
        item_id
    )

    if not status:
        return{
            "status": False,
            "message": "Favorite tidak ditemukan"
        }, 404
    
    return {
        "status": True,
        "message": "Berhasil dihapus dari favorit"
    }
