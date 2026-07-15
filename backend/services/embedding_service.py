import logging
import threading
import numpy as np

logger = logging.getLogger(__name__)

model = None
predict_lock = threading.Lock()

def _get_model():
    global model
    if model is None:
        logger.info("[embedding] Lazily initializing ResNet50 model...")
        from tensorflow.keras.applications import ResNet50
        model = ResNet50(
            weights='imagenet', 
            include_top=False, 
            pooling='avg'
        )
        logger.info("[embedding] ResNet50 model loaded successfully.")
    return model

def extract_embedding(img_path):
    logger.info(f"[embedding] Loading image: {img_path}")
    from tensorflow.keras.preprocessing import image
    from tensorflow.keras.applications.resnet50 import preprocess_input

    img = image.load_img(img_path, target_size=(224, 224))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array = preprocess_input(img_array)
    
    logger.info("[embedding] Acquiring lock for prediction...")
    with predict_lock:
        logger.info("[embedding] Lock acquired. Loading model...")
        net = _get_model()
        logger.info("[embedding] Running model forward pass (direct tensor call)...")

        embedding_tensor = net(img_array, training=False)
        embedding = embedding_tensor.numpy()
        logger.info("[embedding] Prediction completed. Releasing lock.")

    return embedding.flatten()


