from flask import Blueprint
from flask import request
from flask import jsonify
from models.user import User
from extensions import db

from werkzeug.security import (generate_password_hash, check_password_hash)
from datetime import datetime

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

    nama = data.get("nama")
    username = data.get("username")
    email = data.get("email")
    password = data.get("password")

    if User.query.filter_by(username=username).first():
        return jsonify({
            "status": False,
            "message": "Username sudah digunakan"
        }), 400
    
    if User.query.filter_by(email=email).first():
        return jsonify({
            "status": False,
            "message": "Email sudah digunakan"
        }), 400
    
    new_user = User(
        nama=nama,
        username=username,
        email=email,
        password=generate_password_hash(password),
        created_at=datetime.now()
    )

    db.session.add(new_user)
    db.session.commit()

    if not username or not email or not password:
        return jsonify({
            "status": False,
            "message": "Username, email dan Password harus diisi"
    }), 400
    

    return jsonify({
        "status": True,
        "message": "Register berhasil"
    })



@auth_bp.route(
    "/login",
    methods=["POST"]
)
def login():

    data = request.json

    username = data.get("username")
    password = data.get("password")

    user = User.query.filter_by(username=username).first()

    if user is None:
        return jsonify({
            "status": False,
            "message": "Username tidak ditemukan"
        }), 404
    
    if not check_password_hash(
        user.password,
        password
    ):
        return jsonify({
            "status": False,
            "message": "Password salah"
        }), 401
    
    if not username or not password:
        return jsonify({
            "status": False,
            "message": "Username dan Password harus diisi"
    }), 400
    
    return jsonify({
        "status": True,
        "message": "Login berhasil",
        "user": {
            "id_user": user.id_user,
            "nama": user.nama,
            "username": user.username,
            "email": user.email
            }
    })