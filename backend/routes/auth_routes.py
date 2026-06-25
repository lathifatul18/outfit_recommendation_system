from flask import Blueprint
from flask import request
from flask import jsonify

auth_bp = Blueprint(
    "auth",
    __name__
)

# REGISTER
@auth_bp.route(
    "/register",
    methods=["POST"]
)
def register():

    data = request.json

    return jsonify({
        "status": True,
        "message": "Register berhasil",
        "data": data
    })



@auth_bp.route(
    "/login",
    methods=["POST"]
)
def login():

    data = request.json

    email = data.get("email")
    password = data.get("password")

    return jsonify({
        "status": True,
        "message": "Login berhasil",
        "email": email
    })