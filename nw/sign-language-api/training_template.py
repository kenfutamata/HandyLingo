# Training script template for Sign Language Recognition Model
# This creates a model compatible with the API

import tensorflow as tf
import numpy as np
from pathlib import Path
import cv2

class SignLanguageTrainer:
    """Train a sign language recognition model"""
    
    def __init__(self, img_size=224, num_classes=26):
        self.img_size = img_size
        self.num_classes = num_classes  # A-Z
        self.model = None
    
    def create_model(self):
        """Create CNN model for sign recognition"""
        model = tf.keras.Sequential([
            # Input layer
            tf.keras.layers.Input(shape=(self.img_size, self.img_size, 3)),
            
            # Data augmentation (helps with overfitting)
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.1),
            tf.keras.layers.RandomZoom(0.1),
            
            # Block 1
            tf.keras.layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.MaxPooling2D((2, 2)),
            tf.keras.layers.Dropout(0.25),
            
            # Block 2
            tf.keras.layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.MaxPooling2D((2, 2)),
            tf.keras.layers.Dropout(0.25),
            
            # Block 3
            tf.keras.layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.MaxPooling2D((2, 2)),
            tf.keras.layers.Dropout(0.25),
            
            # Fully connected layers
            tf.keras.layers.Flatten(),
            tf.keras.layers.Dense(512, activation='relu'),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.Dropout(0.5),
            tf.keras.layers.Dense(256, activation='relu'),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.Dropout(0.5),
            
            # Output layer
            tf.keras.layers.Dense(self.num_classes, activation='softmax')
        ])
        
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        
        self.model = model
        return model
    
    def load_training_data(self, data_dir: str, validation_split=0.2):
        """
        Load training data from directory structure:
        data_dir/
          A/
            image1.jpg
            image2.jpg
          B/
            image1.jpg
            ...
        """
        
        train_datagen = tf.keras.preprocessing.image.ImageDataGenerator(
            rescale=1./255,
            rotation_range=20,
            width_shift_range=0.2,
            height_shift_range=0.2,
            shear_range=0.2,
            zoom_range=0.2,
            horizontal_flip=True,
            validation_split=validation_split
        )
        
        train_generator = train_datagen.flow_from_directory(
            data_dir,
            target_size=(self.img_size, self.img_size),
            batch_size=32,
            class_mode='categorical',
            subset='training'
        )
        
        validation_generator = train_datagen.flow_from_directory(
            data_dir,
            target_size=(self.img_size, self.img_size),
            batch_size=32,
            class_mode='categorical',
            subset='validation'
        )
        
        return train_generator, validation_generator
    
    def train(self, train_dir: str, epochs=50, validation_split=0.2):
        """Train the model"""
        
        self.create_model()
        
        train_gen, val_gen = self.load_training_data(train_dir, validation_split)
        
        # Callbacks
        callbacks = [
            tf.keras.callbacks.EarlyStopping(
                monitor='val_loss',
                patience=10,
                restore_best_weights=True
            ),
            tf.keras.callbacks.ReduceLROnPlateau(
                monitor='val_loss',
                factor=0.5,
                patience=5,
                min_lr=1e-7
            ),
            tf.keras.callbacks.ModelCheckpoint(
                'models/best_model.h5',
                monitor='val_accuracy',
                save_best_only=True
            )
        ]
        
        history = self.model.fit(
            train_gen,
            validation_data=val_gen,
            epochs=epochs,
            callbacks=callbacks
        )
        
        return history
    
    def save_model(self, filepath: str = "models/sign_language_model.h5"):
        """Save model in H5 format"""
        if self.model is None:
            raise ValueError("Model not trained yet")
        
        Path(filepath).parent.mkdir(parents=True, exist_ok=True)
        self.model.save(filepath)
        print(f"✓ Model saved to {filepath}")
    
    def evaluate(self, test_dir: str):
        """Evaluate model on test set"""
        test_datagen = tf.keras.preprocessing.image.ImageDataGenerator(rescale=1./255)
        
        test_generator = test_datagen.flow_from_directory(
            test_dir,
            target_size=(self.img_size, self.img_size),
            batch_size=32,
            class_mode='categorical'
        )
        
        results = self.model.evaluate(test_generator)
        print(f"Test Loss: {results[0]:.4f}")
        print(f"Test Accuracy: {results[1]:.4f}")
        
        return results

# Usage example:
if __name__ == "__main__":
    # 1. Create trainer
    trainer = SignLanguageTrainer(img_size=224, num_classes=26)
    
    # 2. Train model (adjust paths to your dataset)
    print("Training model...")
    trainer.train(
        train_dir="datasets/sign_language/train",
        epochs=50,
        validation_split=0.2
    )
    
    # 3. Evaluate on test set
    print("\nEvaluating model...")
    trainer.evaluate("datasets/sign_language/test")
    
    # 4. Save model (automatically in H5 format)
    trainer.save_model("models/sign_language_model.h5")
    
    print("\n✓ Training complete!")
    print("Next step: Run convert_model.py to prepare for API deployment")
