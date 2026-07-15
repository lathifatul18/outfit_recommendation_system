import logging
import os

from models.favorite import Favorite
from models.fashion_item import FashionItem
from extensions import db

logger = logging.getLogger(__name__)

BASE_FOLDER = os.path.join(
    os.getcwd(),
    "outfit_items_dataset"
)

UPLOAD_FOLDER = os.path.join(
    os.getcwd(),
    "uploads"
)


def _build_image_url(item):
    """
    Build URL gambar yang konsisten untuk response API.
    - Upload item (source_type='upload'): /api/images/uploads/<filename>
    - Dataset item: /api/images/<relative_path>
    """
    if item.source_type == "upload":
        filename = os.path.basename(item.gambar)
        return f"/api/images/uploads/{filename}"

    # Dataset item — gambar bisa berupa path absolut atau relatif
    gambar = item.gambar
    if os.path.isabs(gambar):
        try:
            relative = os.path.relpath(gambar, BASE_FOLDER).replace("\\", "/")
            # Pastikan tidak keluar dari BASE_FOLDER (relatif ke atas)
            if relative.startswith(".."):
                # Fallback: ambil bagian setelah BASE_FOLDER
                filename = os.path.basename(gambar)
                return f"/api/images/uploads/{filename}"
            return f"/api/images/{relative}"
        except ValueError:
            # Windows: beda drive
            filename = os.path.basename(gambar)
            return f"/api/images/uploads/{filename}"
    else:
        # Path relatif — bersihkan backslash
        clean = gambar.replace("\\", "/")
        if clean.startswith("uploads/"):
            return f"/api/images/{clean}"
        return f"/api/images/{clean}"


def add_favorite(user_id, item_id):
    """
    Tambahkan item ke favorit user.
    Returns True jika berhasil, False jika sudah ada.
    """
    existing = Favorite.query.filter_by(
        user_id=user_id,
        item_id=item_id
    ).first()

    if existing:
        logger.info(f"[favorite] Item id={item_id} sudah di favorit user id={user_id}")
        return False

    new_favorite = Favorite(
        user_id=user_id,
        item_id=item_id
    )

    db.session.add(new_favorite)
    db.session.commit()

    logger.info(f"[favorite] Item id={item_id} berhasil ditambahkan ke favorit user id={user_id}")
    return True


def get_favorite(user_id):
    """
    Dapatkan semua item favorit user beserta detail item.
    """
    favorites = Favorite.query.filter_by(user_id=user_id).all()

    result = []

    for favorite in favorites:
        item = db.session.get(FashionItem, favorite.item_id)

        if item is None:
            logger.warning(
                f"[favorite] Item id={favorite.item_id} tidak ditemukan, skip"
            )
            continue

        image_url = _build_image_url(item)

        result.append({
            "id_favorit": favorite.id_favorit,
            "id_item": favorite.item_id,
            "nama_item": item.nama_item,
            "sub_category": item.sub_category,
            "gambar": image_url
        })

    logger.info(f"[favorite] User id={user_id} memiliki {len(result)} favorit")
    return result


def delete_favorite(user_id, item_id):
    """
    Hapus item dari favorit user.
    Returns True jika berhasil, False jika tidak ditemukan.
    """
    favorite = Favorite.query.filter_by(
        user_id=user_id,
        item_id=item_id
    ).first()

    if favorite is None:
        logger.warning(f"[favorite] Favorit tidak ditemukan: user={user_id}, item={item_id}")
        return False

    db.session.delete(favorite)
    db.session.commit()

    logger.info(f"[favorite] Item id={item_id} dihapus dari favorit user id={user_id}")
    return True