import logging
import os

from flask import Flask, jsonify
from flask_cors import CORS
from extensions import db, mail
from config import Config
from routes.category_routes import category_bp
from routes.color_routes import color_bp
from routes.auth_routes import auth_bp
from routes.fashion_routes import fashion_bp
from routes.recommendation_routes import recommendation_bp
from routes.outfit_routes import outfit_bp
from routes.image_routes import image_bp
from routes.favorite_routes import favorite_bp
from services.dataset_cache import load_dataset_cache


# ── Logging Setup ────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(os.path.join(os.getcwd(), "flask_app.log"), encoding='utf-8')
    ]
)
logger = logging.getLogger(__name__)



# ── App Factory ──────────────────────────────────────────────────────────────
app = Flask(__name__)
app.config.from_object(Config)

# Enable CORS untuk Flutter (Android Emulator → 10.0.2.2)
CORS(app, resources={r"/api/*": {"origins": "*"}})

db.init_app(app)
mail.init_app(app)

with app.app_context():
    load_dataset_cache()

# ── Global Response Headers ──────────────────────────────────────────────────
@app.after_request
def after_request(response):
    """
    Connection: close mencegah keep-alive issues antara
    Flask dev server dan Android emulator.
    """
    return response


# ── Routes ───────────────────────────────────────────────────────────────────
@app.route("/api")
def home():
    return jsonify({
        "message": "Backend OutfitKu — Hybrid Recommendation System",
        "version": "2.0",
        "status": "running"
    })


@app.route("/api/health")
def health():
    """Health check endpoint."""
    return jsonify({"status": True, "message": "OK"})


# Register Blueprints
app.register_blueprint(auth_bp, url_prefix="/api/auth")
app.register_blueprint(category_bp, url_prefix="/api/categories")
app.register_blueprint(color_bp, url_prefix="/api/colors")
app.register_blueprint(fashion_bp, url_prefix="/api/fashion")
app.register_blueprint(recommendation_bp, url_prefix="/api/recommendation")
app.register_blueprint(outfit_bp, url_prefix="/api/outfit")
app.register_blueprint(image_bp, url_prefix="/api/images")
app.register_blueprint(favorite_bp, url_prefix="/api/favorite")


# ── Error Handlers ───────────────────────────────────────────────────────────
@app.errorhandler(400)
def bad_request(error):
    return jsonify({
        "status": False,
        "message": str(error.description) if hasattr(error, "description") else "Bad request"
    }), 400


@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "status": False,
        "message": str(error.description) if hasattr(error, "description") else "Resource tidak ditemukan"
    }), 404


@app.errorhandler(413)
def too_large(error):
    return jsonify({
        "status": False,
        "message": "File terlalu besar. Maksimum 16MB."
    }), 413


@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {error}")
    return jsonify({
        "status": False,
        "message": "Internal server error. Periksa log backend."
    }), 500


# ── Entry Point ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    logger.info("=" * 60)
    logger.info("OutfitKu Backend Starting...")
    logger.info("=" * 60)
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True,
        threaded=True,
        use_reloader=False  # PENTING: reloader menghapus _DATASET_CACHE & memuat TF dua kali
    )
