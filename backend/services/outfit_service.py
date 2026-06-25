from models.fashion_item import FashionItem
from sqlalchemy.sql.expression import func
from services.outfit_rules import OUTFIT_RULES


def get_item_by_subcategory(subcategories):

    return FashionItem.query.filter(
        FashionItem.sub_category.in_(subcategories)
    ).order_by(
        func.rand()
    ).first()

def generate_outfit(item_id):

    item = FashionItem.query.get(item_id)

    if item is None:
        return None
    
    outfit = {
        "selected_item": {
            "id_item": item.id_item,
            "nama_item": item.nama_item
        }
    }

    rule = OUTFIT_RULES.get(
        item.sub_category
    )
    
    if rule is None:
        return {
            "error": "Rule tidak ditemukan"
        }
    
    outfit = {
        "selected_item": {
            "id_item": item.id_item,
            "nama_item": item.nama_item,
            "sub_category": item.sub_category
        }
    }

    if "bottomwear" in rule:

        bottomwear = get_item_by_subcategory(
            rule["bottomwear"]
        )

        outfit["bottomwear"] = {
            "id_item": bottomwear.id_item,
            "nama_item": bottomwear.nama_item
        }

    if "footwear" in rule:

        footwear = get_item_by_subcategory(
            rule["footwear"]
        )

        outfit["footwear"] = {
            "id_item": footwear.id_item,
            "nama_item": footwear.nama_item
        }

    if "accessories" in rule:

        accessories = get_item_by_subcategory(
            rule["accessories"]
        )

        outfit["accessories"] = {
            "id_item": accessories.id_item,
            "nama_item": accessories.nama_item
        }

    return outfit