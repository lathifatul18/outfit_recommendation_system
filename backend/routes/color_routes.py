from flask import Blueprint
from models.color import Color

color_bp = Blueprint(
    "color",
    __name__
)

@color_bp.route("/", methods=["GET"])
def get_colors():

    colors = Color.query.all()

    data = []

    for color in colors:
         
         data.append({
              "id_color": color.id_color,
              "color_name": color.color_name
         })
         
    return {
        "status": True,
        "data": data
    }