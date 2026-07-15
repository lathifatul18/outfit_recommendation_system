import logging
import sys

from flask_mail import Message
from extensions import mail
from flask import current_app

logger = logging.getLogger(__name__)


def send_verification_email(email: str, token: str):
    """
    Kirim email verifikasi menggunakan Flask-Mail (SMTP Gmail).

    Selalu mencetak link verifikasi ke console backend sebagai fallback
    sehingga developer bisa verifikasi manual jika SMTP bermasalah.

    Raises Exception jika SMTP benar-benar gagal (untuk logging di caller).
    """
    verify_link_local = f"http://127.0.0.1:5000/api/auth/verify/{token}"
    verify_link_emulator = f"http://10.0.2.2:5000/api/auth/verify/{token}"

    # ── Fallback console output ──────────────────────────────────────────────
    print("\n" + "=" * 80)
    print("\x1b[1;33m[OUTFITKU] EMAIL VERIFICATION FALLBACK\x1b[0m")
    print(f"  Email    : \x1b[1;36m{email}\x1b[0m")
    print(f"  Browser  : \x1b[1;32m{verify_link_local}\x1b[0m")
    print(f"  Emulator : \x1b[1;32m{verify_link_emulator}\x1b[0m")
    print("=" * 80 + "\n")
    sys.stdout.flush()

    # ── Coba kirim via SMTP ──────────────────────────────────────────────────
    sender_email = (
        current_app.config.get("MAIL_DEFAULT_SENDER")
        or current_app.config.get("MAIL_USERNAME")
    )

    if not sender_email:
        logger.error("[email] MAIL_DEFAULT_SENDER / MAIL_USERNAME tidak dikonfigurasi di .env")
        raise ValueError("Email sender tidak dikonfigurasi")

    message = Message(
        subject="Verifikasi Akun OutfitKu 👗",
        recipients=[email],
        sender=sender_email
    )

    message.body = f"""Halo,

Terima kasih telah mendaftar di OutfitKu — Aplikasi Rekomendasi Outfit Cerdas!

Silakan klik link berikut untuk mengaktifkan akun Anda:

{verify_link_local}

Link ini hanya berlaku satu kali.

Jika Anda tidak merasa mendaftar, abaikan email ini.

Salam,
Tim OutfitKu
"""

    message.html = f"""
<html>
<body style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; padding: 20px;">
  <div style="text-align: center; margin-bottom: 32px;">
    <h1 style="color: #7C4DFF; font-size: 28px; margin: 0;">OutfitKu</h1>
    <p style="color: #666; margin: 4px 0 0;">Rekomendasi Outfit Cerdas</p>
  </div>

  <h2 style="color: #1A1A2E; font-size: 20px;">Verifikasi Akun Anda</h2>
  <p style="color: #555; line-height: 1.6;">
    Halo! Terima kasih telah mendaftar di <strong>OutfitKu</strong>.
    Klik tombol di bawah ini untuk mengaktifkan akun Anda:
  </p>

  <div style="text-align: center; margin: 32px 0;">
    <a href="{verify_link_local}"
       style="background: #7C4DFF; color: white; padding: 14px 32px;
              border-radius: 12px; text-decoration: none; font-size: 16px;
              font-weight: bold; display: inline-block;">
      ✅ Verifikasi Email Saya
    </a>
  </div>

  <p style="color: #888; font-size: 13px; line-height: 1.5;">
    Jika tombol tidak berfungsi, salin dan tempel link berikut di browser:<br>
    <a href="{verify_link_local}" style="color: #7C4DFF; word-break: break-all;">
      {verify_link_local}
    </a>
  </p>

  <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">
  <p style="color: #aaa; font-size: 12px; text-align: center;">
    Jika Anda tidak merasa mendaftar, abaikan email ini.<br>
    &copy; 2024 OutfitKu
  </p>
</body>
</html>
"""

    try:
        mail.send(message)
        logger.info(f"[email] ✅ Email verifikasi berhasil dikirim ke {email}")
    except Exception as e:
        logger.error(f"[email] ❌ SMTP gagal kirim ke {email}: {type(e).__name__}: {e}")
        raise