from flask import Blueprint
from flask import send_file

image_bp = Blueprint(
    "image",
    __name__
)

@image_bp.route("/<path:image_name>")
def get_image(filepath):

    return send_file(filepath)