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

    status = add_favorite(
        data["user_id"], 
        data["item_id"]
    )

    if not status:
        return {
            "status": False,
            "message": "item sudah ada di favorit"
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

    status = delete_favorite(
        data["user_id"],
        data["item_id"]
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


