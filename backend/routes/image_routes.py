from flask import Blueprint
from flask import send_from_directory

import os

image_bp = Blueprint(
    "image",
    __name__
)

BASE_FOLDER = os.path.join(
    os.getcwd(),
    "outfit_items_dataset"
)

@image_bp.route("/<path:filename>")
def get_image(filename):

    return send_from_directory(
        BASE_FOLDER,
        filename
    )