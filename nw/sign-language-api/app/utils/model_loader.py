import tensorflow as tf
import numpy as np
import os

# Global model variable
MODEL = None

def load_model():
    """Load the trained sign language model"""
    global MODEL
    
    model_path = "models/sign_language_model.h5"
    
    # Check if model exists
    if not os.path.exists(model_path):
        print(f"⚠️  Model not found at {model_path}")
        print("Creating a dummy model for testing...")
        # Create a simple model for testing
        MODEL = create_dummy_model()
    else:
        try:
            MODEL = tf.keras.models.load_model(model_path)
            print(f"✓ Model loaded from {model_path}")
        except Exception as e:
            print(f"Error loading model: {e}")
            MODEL = create_dummy_model()
    
    return MODEL

def create_dummy_model():
    """Create a simple model for testing (replace with your actual model)"""
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(224, 224, 3)),
        tf.keras.layers.Conv2D(32, (3, 3), activation='relu'),
        tf.keras.layers.MaxPooling2D((2, 2)),
        tf.keras.layers.Flatten(),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dropout(0.5),
        tf.keras.layers.Dense(26, activation='softmax')  # 26 letters A-Z
    ])
    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
    return model

def get_model():
    """Get the loaded model"""
    global MODEL
    if MODEL is None:
        load_model()
    return MODEL

def export_model_to_tflite(h5_path: str, output_path: str = "models/model.tflite"):
    """
    Convert your .h5 model to TensorFlow Lite for mobile deployment
    Run this once to prepare the model for Flutter
    """
    model = tf.keras.models.load_model(h5_path)
    
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"✓ Model exported to {output_path}")

def export_model_to_savedmodel(h5_path: str, output_path: str = "models/sign_language_savedmodel"):
    """
    Convert .h5 to SavedModel format for TensorFlow Serving
    This is the recommended format for production APIs
    """
    model = tf.keras.models.load_model(h5_path)
    model.save(output_path)
    print(f"✓ Model exported to {output_path}")
