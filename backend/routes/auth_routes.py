import secrets
import logging
import traceback

from flask import Blueprint, request, jsonify
from models.user import User
from extensions import db
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
from services.email_service import send_verification_email
from email_validator import validate_email, EmailNotValidError

logger = logging.getLogger(__name__)

auth_bp = Blueprint(
    "auth",
    __name__
)


# ======== REGISTER ========

@auth_bp.route("/register", methods=["POST"])
def register():
    """
    Register akun baru.
    - Kirim email verifikasi setelah registrasi berhasil.
    - Jika email gagal terkirim, response tetap sukses tapi
      ada field 'email_sent': false agar frontend bisa menampilkan pesan.
    """
    data = request.json

    if not data:
        return jsonify({
            "status": False,
            "message": "Request body tidak valid"
        }), 400

    nama = data.get("nama", "").strip()
    username = data.get("username", "").strip()
    email = data.get("email", "").strip()
    password = data.get("password", "")

    if not nama or not username or not email or not password:
        return jsonify({
            "status": False,
            "message": "Nama, username, email, dan password harus diisi"
        }), 400

    try:
        validate_email(email)
    except EmailNotValidError as e:
        return jsonify({
            "status": False,
            "message": f"Format email tidak valid: {str(e)}"
        }), 400

    if User.query.filter_by(username=username).first():
        return jsonify({
            "status": False,
            "message": "Username sudah digunakan"
        }), 400

    if User.query.filter_by(email=email).first():
        return jsonify({
            "status": False,
            "message": "Email sudah terdaftar"
        }), 400

    token = secrets.token_urlsafe(32)

    new_user = User(
        nama=nama,
        username=username,
        email=email,
        password=generate_password_hash(password),
        created_at=datetime.now(),
        is_verified=False,
        verification_token=token
    )

    try:
        db.session.add(new_user)
        db.session.commit()
        logger.info(f"[register] User baru: username={username}, email={email}")
    except Exception as e:
        db.session.rollback()
        logger.error(f"[register] DB error: {e}")
        logger.error(traceback.format_exc())
        return jsonify({
            "status": False,
            "message": "Gagal menyimpan data user. Silakan coba lagi."
        }), 500

    email_sent = False
    try:
        send_verification_email(email, token)
        email_sent = True
        logger.info(f"[register] Email verifikasi dikirim ke {email}")
    except Exception as e:
        logger.error(f"[register] GAGAL kirim email ke {email}: {e}")
        logger.error(traceback.format_exc())
        # Tetap lanjut — link verifikasi ada di console

    message = "Registrasi berhasil! Silakan cek email Anda untuk verifikasi akun."
    if not email_sent:
        message = (
            "Registrasi berhasil! "
            "Email verifikasi gagal dikirim otomatis. "
            "Hubungi admin atau gunakan link yang ada di console backend."
        )

    return jsonify({
        "status": True,
        "message": message,
        "email_sent": email_sent
    })


# ======== LOGIN ========

@auth_bp.route("/login", methods=["POST"])
def login():
    """
    Login dengan username dan password.
    Email harus sudah diverifikasi sebelum dapat login.
    """
    data = request.json

    if not data:
        return jsonify({
            "status": False,
            "message": "Request body tidak valid"
        }), 400

    username = data.get("username", "").strip()
    password = data.get("password", "")

    if not username or not password:
        return jsonify({
            "status": False,
            "message": "Username dan password harus diisi"
        }), 400

    user = User.query.filter_by(username=username).first()

    if user is None:
        logger.warning(f"[login] Username tidak ditemukan: {username}")
        return jsonify({
            "status": False,
            "message": "Username tidak terdaftar"
        }), 404

    if not user.is_verified:
        logger.warning(f"[login] User belum verifikasi email: {username}")
        return jsonify({
            "status": False,
            "message": "Email belum diverifikasi. Silakan cek email Anda dan klik link verifikasi."
        }), 403

    if not check_password_hash(user.password, password):
        logger.warning(f"[login] Password salah untuk username: {username}")
        return jsonify({
            "status": False,
            "message": "Password salah"
        }), 401

    logger.info(f"[login] Login berhasil: username={username}, id={user.id_user}")

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


# ======== VERIFY EMAIL ========

@auth_bp.route("/verify/<token>", methods=["GET"])
def verify_email(token):
    """
    Verifikasi email melalui link yang dikirimkan.
    Setelah verifikasi, user bisa login.
    """
    user = User.query.filter_by(verification_token=token).first()

    if user is None:
        logger.warning(f"[verify] Token tidak ditemukan: {token[:10]}...")
        return jsonify({
            "status": False,
            "message": "Link verifikasi tidak valid atau sudah digunakan."
        }), 404

    if user.is_verified:
        return jsonify({
            "status": True,
            "message": "Email sudah diverifikasi sebelumnya. Silakan login."
        })

    user.is_verified = True
    user.verification_token = None

    try:
        db.session.commit()
        logger.info(f"[verify] Email berhasil diverifikasi: username={user.username}")
    except Exception as e:
        db.session.rollback()
        logger.error(f"[verify] DB error saat verifikasi: {e}")
        return jsonify({
            "status": False,
            "message": "Gagal memverifikasi email. Silakan coba lagi."
        }), 500

    return jsonify({
        "status": True,
        "message": "Email berhasil diverifikasi! Silakan login ke aplikasi OutfitKu."
    })


# ======== RESEND VERIFICATION ========

@auth_bp.route("/resend-verification", methods=["POST"])
def resend_verification():
    """
    Kirim ulang email verifikasi ke email yang terdaftar.
    """
    data = request.json or {}
    email = data.get("email", "").strip()

    if not email:
        return jsonify({
            "status": False,
            "message": "Email harus diisi"
        }), 400

    user = User.query.filter_by(email=email).first()

    if user is None:
        return jsonify({
            "status": False,
            "message": "Email tidak terdaftar"
        }), 404

    if user.is_verified:
        return jsonify({
            "status": False,
            "message": "Email sudah diverifikasi. Silakan langsung login."
        }), 400

    # Buat token baru
    token = secrets.token_urlsafe(32)
    user.verification_token = token
    db.session.commit()

    try:
        send_verification_email(email, token)
        logger.info(f"[resend] Email verifikasi dikirim ulang ke {email}")
        return jsonify({
            "status": True,
            "message": "Email verifikasi berhasil dikirim ulang."
        })
    except Exception as e:
        logger.error(f"[resend] Gagal kirim email ke {email}: {e}")
        return jsonify({
            "status": False,
            "message": "Gagal mengirim email. Periksa koneksi internet."
        }), 500