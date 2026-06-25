from  extensions import db
from sqlalchemy import Enum

class FashionItem(db.Model):

    __tablename__ = "fashion_items"

    id_item = db.Column(
        db.Integer, 
        primary_key=True
    )

    nama_item = db.Column(
        db.String(30),
        nullable=False
    )

    source_type = db.Column(
        db.String(30),
        nullable=False
    )

    gambar = db.Column(
        db.String(255),
        nullable=False
    )
    embedding_vector = db.Column(
        db.Text,
        nullable=True
    )
    id_category = db.Column(
        db.Integer,
        db.ForeignKey('category.id_category'),
        nullable=False
    )
    sub_category = db.Column(
        db.String(50),
        nullable=True
    )
    id_color = db.Column(
        db.Integer,
        db.ForeignKey('color.id_color'),
        nullable=False
    )
    id_user = db.Column(
        db.Integer,
        nullable=False
    )
    pattern = db.Column(
        Enum(
            "Solid",
            "Floral",
            "Plaid",
            "Striped",
            "Graphic",
            "Abstract",
            "Polka Dot",
            "Batik",
            name="pattern_enum"
        ),
        nullable=False
    )

    