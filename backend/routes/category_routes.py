from flask import Blueprint
from models.category import Category

category_bp = Blueprint(
    "category",
    __name__
)

@category_bp.route("/", methods=["GET"])
def get_categories():

    categories = Category.query.all()

    data = []
    
    for category in categories:

        data.append({
            "id_category": category.id_category,
            "nama_category": category.nama_category
        })

    return {
        "status": True,
        "data": data
    }