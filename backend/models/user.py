from extensions import db


class User(db.Model):

    __tablename__ = "users"

    id_user = db.Column(db.Integer, primary_key=True)
    nama = db.Column(db.String(25))
    username = db.Column(db.String(20), unique=True)
    email = db.Column(db.String(30), unique=True)
    password = db.Column(db.String(255))
    created_at = db.Column(db.DateTime)