from models.favorite import Favorite
from models.fashion_item import FashionItem
from extensions import db
import os

BASE_FOLDER = os.path.join(
    os.getcwd(),
    "outfit_items_dataset"
)

def add_favorite(user_id, item_id):

    favorite = Favorite.query.filter_by(
        user_id=user_id,
        item_id=item_id
    ).first()

    if favorite:
        return False
    
    new_favorite = Favorite(
        user_id=user_id,
        item_id=item_id
    )

    db.session.add(new_favorite)
    db.session.commit()

    return True

def get_favorite(user_id):

    favorites = Favorite.query.filter_by(
        user_id=user_id
    ).all()

    result = []

    for favorite  in favorites:

        item = FashionItem.query.get(
            favorite.item_id
        )

        image_path = os.path.relpath(
            item.gambar,
            BASE_FOLDER
        ).replace("\\", "/")

        result.append({
            "id_favorit": favorite.id_favorit,
            "id_item": favorite.item_id,
            "nama_item": item.nama_item,
            "sub_category": item.sub_category,
            "gambar": f"/api/images/{image_path}"
        })

    return result

def delete_favorite(user_id, item_id):

    favorite = Favorite.query.filter_by(
        user_id=user_id,
        item_id=item_id
    ).first()

    if favorite is None:
        return False
    
    db.session.delete(favorite)
    db.session.commit()

    return True
        