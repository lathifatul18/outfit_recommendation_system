import logging
import os
import mimetypes

from flask import Blueprint, send_from_directory, abort

logger = logging.getLogger(__name__)

image_bp = Blueprint(
    "image",
    __name__
)

BASE_FOLDER = os.path.join(
    os.getcwd(),
    "outfit_items_dataset"
)

UPLOAD_FOLDER = os.path.join(
    os.getcwd(),
    "uploads"
)

os.makedirs(UPLOAD_FOLDER, exist_ok=True)


@image_bp.after_request
def add_headers(response):
    """
    Header untuk Flutter.
    Tidak perlu menambahkan Connection: close secara manual.
    """
    response.headers["Cache-Control"] = "public, max-age=86400"
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Accept-Ranges"] = "bytes"
    return response


@image_bp.route("/uploads/<path:filename>")
def serve_upload(filename):
    """
    URL:
    /api/images/uploads/<filename>
    """

    full_path = os.path.join(UPLOAD_FOLDER, filename)

    logger.debug(f"[image] Upload: {full_path}")

    if not os.path.isfile(full_path):
        logger.warning(f"[image] Upload tidak ditemukan: {full_path}")
        abort(404)

    return send_from_directory(
        UPLOAD_FOLDER,
        filename,
        mimetype=_get_mimetype(filename),
        conditional=False,
        as_attachment=False,
        max_age=86400
    )


@image_bp.route("/<path:filename>")
def serve_dataset(filename):
    """
    URL:
    /api/images/<relative_path>
    """

    full_path = os.path.join(BASE_FOLDER, filename)

    logger.debug(f"[image] Dataset: {full_path}")

    if not os.path.isfile(full_path):
        logger.warning(f"[image] Dataset tidak ditemukan: {full_path}")
        abort(404)

    directory = os.path.dirname(full_path)
    file_name = os.path.basename(full_path)

    return send_from_directory(
        directory,
        file_name,
        mimetype=_get_mimetype(file_name),
        conditional=False,
        as_attachment=False,
        max_age=86400
    )


def _get_mimetype(filename):
    ext = os.path.splitext(filename)[1].lower()

    mime_map = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".gif": "image/gif",
        ".bmp": "image/bmp",
        ".webp": "image/webp",
    }

    return (
        mime_map.get(ext)
        or mimetypes.guess_type(filename)[0]
        or "application/octet-stream"
    )