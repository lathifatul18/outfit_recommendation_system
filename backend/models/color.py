from extensions import db

class Color(db.Model):

    __tablename__ = "color"

    id_color = db.Column(
        db.Integer,
        primary_key = True
    )

    color_name = db.Column(
        db.String(20),
        nullable = False
    )