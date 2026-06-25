from extensions import db

class Category(db.Model):

    __tablename__ = "category"

    id_category = db.Column(
        db.Integer,
        primary_key = True
    )

    nama_category = db.Column(
        db.String(20),
        nullable = False
    )