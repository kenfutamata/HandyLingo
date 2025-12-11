# Convert your existing .h5 model to API-compatible format
# Run this script once with your trained model

import tensorflow as tf
import sys

def convert_model(h5_path: str):
    """
    Convert your .h5 model to formats suitable for the API
    """
    print(f"Loading model from {h5_path}...")
    model = tf.keras.models.load_model(h5_path)
    
    # 1. Export as SavedModel (recommended for API)
    saved_model_path = "models/sign_language_savedmodel"
    model.save(saved_model_path)
    print(f"✓ SavedModel saved to {saved_model_path}")
    
    # 2. Export as TFLite (for mobile if needed)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    with open("models/sign_language_model.tflite", "wb") as f:
        f.write(tflite_model)
    print(f"✓ TFLite model saved to models/sign_language_model.tflite")
    
    # 3. Keep original H5 as backup
    print(f"\nModel conversion complete!")
    print(f"Use SavedModel format in production API")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python convert_model.py <path_to_your_model.h5>")
        sys.exit(1)
    
    convert_model(sys.argv[1])
