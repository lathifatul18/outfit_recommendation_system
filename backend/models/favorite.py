from extensions import db

class Favorite(db.Model):

    __tablename__ = "favorit"

    id_favorit = db.Column(
        db.Integer,
        primary_key = True
    )

    user_id = db.Column(
        db.Integer,
        db.ForeignKey("users.id_user")
    )

    item_id = db.Column(
        db.Integer,
        db.ForeignKey("fashion_items.id_item")
    )