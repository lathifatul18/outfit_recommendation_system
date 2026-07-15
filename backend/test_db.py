from app import app, db
from models.fashion_item import FashionItem
from models.category import Category
from models.color import Color

with app.app_context():
    try:
        db.engine.connect()
        print("Database connection OK")
        
        items_count = FashionItem.query.count()
        dataset_count = FashionItem.query.filter_by(source_type="dataset").count()
        user_count = FashionItem.query.filter_by(source_type="upload").count()
        cat_count = Category.query.count()
        col_count = Color.query.count()
        
        print(f"Total FashionItems: {items_count}")
        print(f"Dataset items: {dataset_count}")
        print(f"User uploaded items: {user_count}")
        print(f"Categories: {cat_count}")
        print(f"Colors: {col_count}")
        
    except Exception as e:
        print("Database error:")
        print(e)