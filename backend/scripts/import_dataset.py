import os
import sys

BASE_DIR = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )    
)

sys.path.append(BASE_DIR)

from app import app
from extensions import db
from models.fashion_item import FashionItem
from models.category import Category

DATASET_PATH = os.path.join(
    BASE_DIR,
    "outfit_items_dataset"
)

with app.app_context():

    for category_name in os.listdir(DATASET_PATH):

        category_path = os.path.join(
            DATASET_PATH,
            category_name
        )

        if not os.path.isdir(category_path):
            continue

        category = Category.query.filter_by(
            nama_category=category_name
        ).first()

        if category is None:
            print(f"Kategori {category_name} tidak ditemukan")
            continue

        for subcategory_name in os.listdir(category_path):

            subcategory_path = os.path.join(
                category_path,
                subcategory_name
            )

            if not os.path.isdir(subcategory_path):
                continue

            for filename in os.listdir(subcategory_path):

                image_path = os.path.join(
                    subcategory_path,
                    filename
                )

                item = FashionItem(
                    nama_item=os.path.splitext(filename)[0],
                    source_type="dataset",
                    gambar=image_path,
                    id_category=category.id_category,
                    sub_category=subcategory_name,
                    id_color=1,
                    pattern="Solid",
                    id_user=None
                )

                db.session.add(item)

        db.session.commit()

        print(
            f"{category_name} berhasil diimport"
        )