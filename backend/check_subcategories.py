from app import app, db
from models.fashion_item import FashionItem
from sqlalchemy import func

with app.app_context():
    try:
        # Query distinct sub_category values and their counts for dataset items
        results = db.session.query(
            FashionItem.sub_category,
            func.count(FashionItem.id_item)
        ).filter(
            FashionItem.source_type == "dataset"
        ).group_by(
            FashionItem.sub_category
        ).all()
        
        print("Distinct subcategories in database:")
        for sub, count in results:
            print(f"- '{sub}': {count} items")
            
    except Exception as e:
        print("Error checking subcategories:")
        print(e)
