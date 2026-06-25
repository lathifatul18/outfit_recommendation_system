from flask import Blueprint
from flask import request
from models.fashion_item import FashionItem
from extensions import db
import os

fashion_bp = Blueprint(
    "fashion",
    __name__
)

UPLOAD_FOLDER = "uploads"

os.makedirs("UPLOAD_FOLDER", exist_ok=True)

@fashion_bp.route("/upload", methods=["POST"])
def upload_fashion():

    image = request.files.get("image")

    if image is None:
        
        return {
            "status": False,
            "message": "tidak ada gambar"
        }, 400
    
    nama_item = request.form.get("nama_item")
    source_type = request.form.get("source_type")
    id_category = request.form.get("id_category")
    id_color = request.form.get("id_color")
    pattern = request.form.get("pattern")

    if not all([
        nama_item,
        source_type,
        id_category,
        id_color,
        pattern
    ]):
        return {
            "status": False,
            "message": "data tidak lengkap"
        }, 400
    
    filepath = os.path.join(UPLOAD_FOLDER, image.filename)

    image.save(filepath)

    new_item = FashionItem(
        nama_item=nama_item,
        source_type=source_type,
        gambar=filepath,
        id_category=int(id_category),
        id_color=int(id_color),
        pattern=pattern,
        id_user=None
    )

    db.session.add(new_item)
    db.session.commit()

    return {
        "status": True,
        "message": "Fashion item berhasil ditambahkan",
        "data": {
            "id_item": new_item.id_item,
            "nama_item": new_item.nama_item,
            "gambar": new_item.gambar
        }
    }, 201

@fashion_bp.route("/", methods=["GET"])

def get_fashion_items():

    items = FashionItem.query.all()

    data = []

    for item in items:

        data.append({
            "id_item": item.id_item,
            "nama_item": item.nama_item,
            "source_type": item.source_type,
            "gambar": item.gambar,
            "id_category": item.id_category,
            "id_color": item.id_color,
            "id_user": item.id_user,
            "pattern": item.pattern
        })

    return {
        "status": True,
        "data": data
    }

@fashion_bp.route("/<int:id>", methods=["GET"])
def get_fashion_by_id(id):

    item = FashionItem.query.get(id)

    if item is None:

        return {
            "status": False,
            "message": "item tidak ditemukan"
        }, 404
    
    return {
        "status": True,
        "data": {
            "id_item": item.id_item,
            "nama_item": item.nama_item,
            "source_type": item.source_type,
            "gambar": item.gambar,
            "id_category": item.id_category,
            "id_color": item.id_color,
            "id_user": item.id_user,
            "pattern": item.pattern
        }
    }

@fashion_bp.route("/category/<int:id>", methods=["GET"])
def get_fashion_by_category(id):

    items = FashionItem.query.filter_by(id_category=id).all()

    data = []

    for item in items:

        data.append({
            "id_item": item.id_item,
            "nama_item": item.nama_item,
            "gambar": item.gambar,
            "pattern": item.pattern
        })

    return {
        "status": True,
        "data": data
    }

@fashion_bp.route("/color/<int:id>", methods=["GET"])
def get_by_color(id):

    items = FashionItem.query.filter_by(id_color=id).all()

    data = []

    for item in items:

        data.append({
            "id_item": item.id_item,
            "nama_item": item.nama_item,
            "gambar": item.gambar
        })
    
    return {
        "status": True,
        "data": data
    }