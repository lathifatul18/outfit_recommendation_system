from flask import Flask
from extensions import db
from config import Config
from routes.category_routes import category_bp
from routes.color_routes import color_bp

from routes.auth_routes import auth_bp
from routes.fashion_routes import fashion_bp
from routes.recommendation_routes import recommendation_bp

app = Flask(__name__)

app.config.from_object(Config)
db.init_app(app)

@app.route("/api")
def home():

    return {
        "message": "Backend Outfit Recommendation System"
    }

app.register_blueprint(
    auth_bp,
    url_prefix="/api/auth"
)

app.register_blueprint(
    category_bp,
    url_prefix= "/api/categories"
)

app.register_blueprint(
    color_bp,
    url_prefix="/api/colors"
)

app.register_blueprint(
    fashion_bp,
    url_prefix="/api/fashion"
)

app.register_blueprint(
    recommendation_bp,
    url_prefix="/api/recommendation"
)

if __name__ == "__main__":
    app.run(debug=True)


