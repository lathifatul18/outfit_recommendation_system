from flask_mail import Message
from extensions import mail

def send_verification_email(email, token):

    verify_link = f"http://127.0.0.1:5000/api/auth/verify/{token}"

    message = Message(
        subject = "Verifikasi akun Outfit Recommendation",
        recipients = [email]
    )

    message.body = f"""

Halo, 

Terima kasih telah mendaftar.

Silahkan klik link berikut untuk mengaktifkan akun kamu :

{verify_link}
    
Jika kamu tidak merasa mendaftar, abaikan email ini.

Terima Kasih.
"""
    
    mail.send(message)