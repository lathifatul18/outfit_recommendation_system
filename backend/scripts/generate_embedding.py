import os 
import sys
import json
import numpy as np

BASE_DIR = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

sys.path.append(BASE_DIR)

from app import app
from extensions import db
from models.fashion_item import FashionItem

from tensorflow.keras.applications import ResNet50
from tensorflow.keras.applications.resnet50 import preprocess_input
from tensorflow.keras.preprocessing import image

model = ResNet50(
    weights='imagenet', 
    include_top=False, 
    pooling='avg'
)

def extract_embedding(img_path):
    img = image.load_img(img_path, target_size=(224, 224))

    img_array = image.img_to_array(img)

    img_array = np.expand_dims(img_array, axis=0)
    
    img_array = preprocess_input(img_array)

    embedding = model.predict(img_array, verbose=0)

    return embedding.flatten()

with app.app_context():

    items = FashionItem.query.all()

    print(
        f"{len(items)} item ditemukan"
    )

    for item in items:

        if item.embedding_vector:
            continue

        try:
            vector = extract_embedding(item.gambar)

            item.embedding_vector = json.dumps(vector.tolist())

            db.session.commit()

            print(
                f"Embedding {item.id_item} selesai"
            )

        except Exception as e:

            print(
                f"Error {item.id_item}: {e}"
            )
