from app import app, db
from routes.fashion_routes import get_dataset_embeddings
from services.embedding_service import extract_embedding
from services.outfit_service import generate_outfit
from models.fashion_item import FashionItem
import os
import json
import numpy as np

# We'll use one of the dataset images as our upload image
test_image_path = os.path.join(
    os.getcwd(),
    "outfit_items_dataset",
    "upperwear",
    "tshirt",
    "upperwear_tshirt1.png"
)

print(f"Checking if test image exists: {os.path.exists(test_image_path)}")

with app.app_context():
    try:
        # Extract embedding
        print("Extracting embedding...")
        vector = extract_embedding(test_image_path)
        print(f"Extracted vector shape: {vector.shape}")
        
        # Classify
        print("Classifying...")
        normalized_matrix, categories, sub_categories, colors, patterns = get_dataset_embeddings()
        
        if normalized_matrix is not None:
            input_norm = np.linalg.norm(vector)
            input_norm = 1.0 if input_norm == 0 else input_norm
            normalized_input = (vector / input_norm).astype(np.float32)
            
            similarities = np.dot(normalized_matrix, normalized_input)
            best_idx = np.argmax(similarities)
            
            id_cat = categories[best_idx]
            sub_cat = sub_categories[best_idx]
            id_col = colors[best_idx]
            pat = patterns[best_idx]
            print(f"Predicted: cat={id_cat}, sub={sub_cat}, col={id_col}, pat={pat} with score {similarities[best_idx]}")
            
            # Insert temp user item
            temp_item = FashionItem(
                nama_item="Test Kaos",
                source_type="upload",
                gambar=test_image_path,
                id_category=int(id_cat),
                sub_category=sub_cat,
                id_color=int(id_col),
                pattern=pat,
                id_user=1,
                embedding_vector=json.dumps(vector.tolist())
            )
            db.session.add(temp_item)
            db.session.commit()
            print(f"Added temp item with ID: {temp_item.id_item}")
            
            # Generate outfit
            print("Generating outfit...")
            outfit = generate_outfit(temp_item.id_item)
            print("Successfully generated outfit:")
            print(json.dumps(outfit, indent=2))
            
            # Clean up
            db.session.delete(temp_item)
            db.session.commit()
            print("Cleaned up temp item.")
            
        else:
            print("Normalized matrix is None!")
            
    except Exception as e:
        print("Error during recommendation test:")
        import traceback
        traceback.print_exc()
