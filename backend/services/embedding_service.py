import numpy as np

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
