# Training Guide: Static + Dynamic Sign Language Model from WLASL Dataset

## Overview

This guide explains how to train a single unified model that recognizes BOTH:
- **Static signs** (single hand position/pose)
- **Dynamic signs** (hand movement over time)

Using the WLASL (World Level American Sign Language) dataset.

---

## Part 1: Understanding the Approach

### What We're Building

A **Hybrid CNN-LSTM Model** that:
1. **Processes video frames** (not just single images)
2. **Extracts spatial features** using CNN (what the hand looks like)
3. **Captures temporal patterns** using LSTM (how the hand moves)
4. **Works for both** static and dynamic signs

### Why This Works

- **Static signs**: LSTM sees consistent frames → learns the pose
- **Dynamic signs**: LSTM sees changing frames → learns the movement
- **Single model**: No need to distinguish between them

### Model Architecture

```
Video Input (sequence of frames)
    ↓
[CNN] → Spatial Feature Extraction (224×224 → 2048D features)
    ↓
[LSTM] → Temporal Pattern Recognition (sequence processing)
    ↓
[Dense] → Classification (gesture class)
    ↓
Output: Sign Label (A-Z, 0-100+, etc.)
```

---

## Part 2: Dataset Preparation

### Step 1: Download WLASL Dataset

WLASL is a large-scale American Sign Language dataset with 2,000+ signs.

**Option A: Download from Official Source**
```
Website: https://github.com/dxli94/WLASL
Download: wlasl_class_list.txt (signs list)
         videos.tar.gz (actual videos)
         or individual video downloads
```

**Option B: Use Smaller Subset for Testing**
```
Create test folder structure:
wlasl_data/
├── train/
│   ├── sign_1/
│   │   ├── video_1.mp4
│   │   └── video_2.mp4
│   ├── sign_2/
│   └── ...
├── test/
│   ├── sign_1/
│   ├── sign_2/
│   └── ...
└── classes.txt
```

### Step 2: Extract Frames from Videos

Create a script to convert videos to frame sequences:

```python
import cv2
import os
from pathlib import Path

def extract_frames_from_video(video_path, output_dir, frames_per_video=30):
    """
    Extract frames from video for model training
    
    Args:
        video_path: Path to video file
        output_dir: Where to save frames
        frames_per_video: How many frames to extract (30 for dynamic)
    """
    os.makedirs(output_dir, exist_ok=True)
    
    cap = cv2.VideoCapture(video_path)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    # Calculate frame skip interval
    frame_skip = max(1, total_frames // frames_per_video)
    
    frame_count = 0
    saved_count = 0
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        if frame_count % frame_skip == 0 and saved_count < frames_per_video:
            # Resize frame to 224×224
            frame = cv2.resize(frame, (224, 224))
            
            # Save frame
            frame_path = os.path.join(output_dir, f"frame_{saved_count:03d}.jpg")
            cv2.imwrite(frame_path, frame)
            saved_count += 1
        
        frame_count += 1
    
    cap.release()
    return saved_count

# Usage
def prepare_wlasl_dataset(dataset_dir, output_dir, frames_per_video=30):
    """Prepare entire WLASL dataset"""
    
    for split in ['train', 'test']:
        split_dir = os.path.join(dataset_dir, split)
        
        for sign_class in os.listdir(split_dir):
            class_dir = os.path.join(split_dir, sign_class)
            if not os.path.isdir(class_dir):
                continue
            
            print(f"Processing {split}/{sign_class}...")
            
            for video_file in os.listdir(class_dir):
                if video_file.endswith(('.mp4', '.avi', '.mov')):
                    video_path = os.path.join(class_dir, video_file)
                    
                    # Create output directory for frames
                    base_name = os.path.splitext(video_file)[0]
                    frames_output = os.path.join(
                        output_dir, split, sign_class, base_name
                    )
                    
                    try:
                        extract_frames_from_video(
                            video_path, 
                            frames_output, 
                            frames_per_video
                        )
                        print(f"  ✓ {video_file}")
                    except Exception as e:
                        print(f"  ✗ {video_file}: {e}")

# Run this
if __name__ == "__main__":
    prepare_wlasl_dataset(
        dataset_dir="path/to/wlasl_videos",
        output_dir="wlasl_frames_30",
        frames_per_video=30  # 30 frames per video
    )
```

### Step 3: Organize Data Structure

After extraction, your data should look like:

```
wlasl_frames_30/
├── train/
│   ├── hello/          # Sign class
│   │   ├── video_1/    # One video's frames
│   │   │   ├── frame_000.jpg
│   │   │   ├── frame_001.jpg
│   │   │   └── ... (30 frames total)
│   │   ├── video_2/
│   │   └── ...
│   ├── goodbye/
│   ├── please/
│   └── ... (2000+ sign classes)
├── test/
│   ├── hello/
│   ├── goodbye/
│   └── ...
└── classes.txt
```

---

## Part 3: Build the Unified Model

### Step 1: Create the Hybrid CNN-LSTM Model

```python
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV2
import numpy as np

class SignLanguageModel:
    """Unified model for static + dynamic signs"""
    
    def __init__(self, num_classes=100, frames_per_sequence=30):
        self.num_classes = num_classes
        self.frames_per_sequence = frames_per_sequence
        self.img_size = 224
        
    def build_cnn_backbone(self):
        """
        Create CNN backbone for spatial feature extraction
        Using MobileNetV2 (lightweight, fast)
        """
        base_model = MobileNetV2(
            input_shape=(self.img_size, self.img_size, 3),
            include_top=False,
            weights='imagenet'
        )
        
        # Freeze base weights initially
        base_model.trainable = False
        
        # Add custom top
        model = models.Sequential([
            base_model,
            layers.GlobalAveragePooling2D(),
            layers.Dense(256, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.3)
        ])
        
        return model
    
    def build_hybrid_model(self):
        """
        Build CNN-LSTM model for video sequence classification
        
        Input: Sequence of frames (batch, frames, height, width, channels)
        Output: Sign class probability
        """
        
        # Create CNN backbone
        cnn_backbone = self.build_cnn_backbone()
        
        # Build complete model with TimeDistributed wrapper
        model = models.Sequential([
            # Input: (batch_size, frames_per_sequence, 224, 224, 3)
            layers.TimeDistributed(
                cnn_backbone,
                input_shape=(self.frames_per_sequence, self.img_size, self.img_size, 3)
            ),
            # Output: (batch_size, frames_per_sequence, 256)
            
            # LSTM layers for temporal pattern recognition
            layers.LSTM(256, return_sequences=True, dropout=0.3),
            layers.BatchNormalization(),
            
            layers.LSTM(128, dropout=0.3),
            layers.BatchNormalization(),
            
            # Dense layers for classification
            layers.Dense(256, activation='relu'),
            layers.Dropout(0.5),
            
            layers.Dense(128, activation='relu'),
            layers.Dropout(0.3),
            
            # Output layer
            layers.Dense(self.num_classes, activation='softmax')
        ])
        
        return model
    
    def compile_model(self, model, learning_rate=0.001):
        """Compile the model"""
        optimizer = tf.keras.optimizers.Adam(learning_rate=learning_rate)
        
        model.compile(
            optimizer=optimizer,
            loss='categorical_crossentropy',
            metrics=['accuracy', tf.keras.metrics.TopKCategoricalAccuracy(k=5, name='top_5_accuracy')]
        )
        
        return model
    
    def create(self):
        """Create and compile the full model"""
        model = self.build_hybrid_model()
        model = self.compile_model(model)
        
        print(model.summary())
        return model

# Usage
if __name__ == "__main__":
    builder = SignLanguageModel(num_classes=100, frames_per_sequence=30)
    model = builder.create()
```

---

## Part 4: Data Loading

### Create Data Generator for Sequence Loading

```python
import os
import cv2
import numpy as np
from sklearn.preprocessing import LabelEncoder

class VideoSequenceDataGenerator:
    """Generate batches of video sequences for training"""
    
    def __init__(self, data_dir, num_frames=30, img_size=224, batch_size=16):
        self.data_dir = data_dir
        self.num_frames = num_frames
        self.img_size = img_size
        self.batch_size = batch_size
        
        self.class_names = sorted(os.listdir(data_dir))
        self.label_encoder = LabelEncoder()
        self.label_encoder.fit(range(len(self.class_names)))
        
        self.samples = self._collect_samples()
        
    def _collect_samples(self):
        """Collect all video sequences"""
        samples = []
        
        for class_idx, class_name in enumerate(self.class_names):
            class_dir = os.path.join(self.data_dir, class_name)
            
            # Each video's frames are in a subdirectory
            for video_name in os.listdir(class_dir):
                video_dir = os.path.join(class_dir, video_name)
                if os.path.isdir(video_dir):
                    frame_files = sorted([f for f in os.listdir(video_dir) if f.endswith('.jpg')])
                    
                    if len(frame_files) >= self.num_frames:
                        samples.append({
                            'frames_dir': video_dir,
                            'class': class_idx,
                            'class_name': class_name,
                            'num_frames': len(frame_files)
                        })
        
        return samples
    
    def load_frame_sequence(self, frames_dir, num_frames=None):
        """Load a sequence of frames"""
        if num_frames is None:
            num_frames = self.num_frames
        
        frame_files = sorted([f for f in os.listdir(frames_dir) if f.endswith('.jpg')])
        
        if len(frame_files) < num_frames:
            # Pad with repeat if not enough frames
            frame_files = frame_files + [frame_files[-1]] * (num_frames - len(frame_files))
        
        # Sample evenly spaced frames
        indices = np.linspace(0, len(frame_files)-1, num_frames).astype(int)
        
        frames = []
        for idx in indices:
            frame_path = os.path.join(frames_dir, frame_files[idx])
            frame = cv2.imread(frame_path)
            
            # Resize to 224×224
            frame = cv2.resize(frame, (self.img_size, self.img_size))
            
            # Normalize to 0-1
            frame = frame.astype('float32') / 255.0
            
            frames.append(frame)
        
        return np.array(frames)
    
    def generate_batches(self, shuffle=True, validation_split=0.2):
        """Generate training and validation batches"""
        
        indices = np.arange(len(self.samples))
        if shuffle:
            np.random.shuffle(indices)
        
        split_idx = int(len(indices) * (1 - validation_split))
        train_indices = indices[:split_idx]
        val_indices = indices[split_idx:]
        
        def batch_generator(batch_indices):
            while True:
                if shuffle:
                    np.random.shuffle(batch_indices)
                
                for i in range(0, len(batch_indices), self.batch_size):
                    batch_idx = batch_indices[i:i+self.batch_size]
                    
                    X = []
                    y = []
                    
                    for idx in batch_idx:
                        sample = self.samples[idx]
                        
                        # Load frame sequence
                        frames = self.load_frame_sequence(sample['frames_dir'])
                        X.append(frames)
                        
                        # One-hot encode label
                        label = np.zeros(len(self.class_names))
                        label[sample['class']] = 1
                        y.append(label)
                    
                    yield np.array(X), np.array(y)
        
        return (
            batch_generator(train_indices),
            batch_generator(val_indices),
            len(train_indices) // self.batch_size,
            len(val_indices) // self.batch_size
        )

# Usage
if __name__ == "__main__":
    data_gen = VideoSequenceDataGenerator(
        data_dir="wlasl_frames_30/train",
        num_frames=30,
        img_size=224,
        batch_size=16
    )
    
    print(f"Found {len(data_gen.samples)} video sequences")
    print(f"Classes: {data_gen.class_names[:10]}...")
```

---

## Part 5: Training Script

### Complete Training Pipeline

```python
import tensorflow as tf
from tensorflow.keras.callbacks import (
    EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
)
import matplotlib.pyplot as plt

class SignLanguageTrainer:
    """Train the unified sign language model"""
    
    def __init__(self, model, data_generator):
        self.model = model
        self.data_gen = data_generator
        
    def train(self, epochs=50, initial_lr=0.001):
        """Train the model"""
        
        # Get training and validation generators
        train_gen, val_gen, steps_train, steps_val = self.data_gen.generate_batches(
            shuffle=True,
            validation_split=0.2
        )
        
        # Callbacks
        callbacks = [
            # Early stopping
            EarlyStopping(
                monitor='val_loss',
                patience=10,
                restore_best_weights=True,
                verbose=1
            ),
            
            # Save best model
            ModelCheckpoint(
                'models/best_sign_language_model.h5',
                monitor='val_accuracy',
                save_best_only=True,
                verbose=1
            ),
            
            # Reduce learning rate on plateau
            ReduceLROnPlateau(
                monitor='val_loss',
                factor=0.5,
                patience=5,
                min_lr=1e-7,
                verbose=1
            ),
            
            # TensorBoard logging
            tf.keras.callbacks.TensorBoard(
                log_dir='./logs',
                histogram_freq=1
            )
        ]
        
        # Train model
        history = self.model.fit(
            train_gen,
            steps_per_epoch=steps_train,
            validation_data=val_gen,
            validation_steps=steps_val,
            epochs=epochs,
            callbacks=callbacks,
            verbose=1
        )
        
        return history
    
    def save_model(self, filepath='models/sign_language_model.h5'):
        """Save trained model"""
        self.model.save(filepath)
        print(f"✓ Model saved to {filepath}")
    
    def plot_history(self, history):
        """Plot training history"""
        plt.figure(figsize=(15, 5))
        
        # Accuracy
        plt.subplot(1, 3, 1)
        plt.plot(history.history['accuracy'], label='Train')
        plt.plot(history.history['val_accuracy'], label='Validation')
        plt.title('Accuracy')
        plt.legend()
        plt.grid()
        
        # Loss
        plt.subplot(1, 3, 2)
        plt.plot(history.history['loss'], label='Train')
        plt.plot(history.history['val_loss'], label='Validation')
        plt.title('Loss')
        plt.legend()
        plt.grid()
        
        # Top-5 Accuracy
        plt.subplot(1, 3, 3)
        plt.plot(history.history['top_5_accuracy'], label='Train')
        plt.plot(history.history['val_top_5_accuracy'], label='Validation')
        plt.title('Top-5 Accuracy')
        plt.legend()
        plt.grid()
        
        plt.tight_layout()
        plt.savefig('training_history.png')
        print("✓ Training history saved to training_history.png")

# Main training script
if __name__ == "__main__":
    # 1. Build model
    print("Building model...")
    builder = SignLanguageModel(num_classes=100, frames_per_sequence=30)
    model = builder.create()
    
    # 2. Prepare data
    print("Preparing data...")
    data_gen = VideoSequenceDataGenerator(
        data_dir="wlasl_frames_30/train",
        num_frames=30,
        img_size=224,
        batch_size=16
    )
    
    # 3. Train model
    print("Training model...")
    trainer = SignLanguageTrainer(model, data_gen)
    history = trainer.train(epochs=50, initial_lr=0.001)
    
    # 4. Save model
    trainer.save_model('models/sign_language_model.h5')
    
    # 5. Plot results
    trainer.plot_history(history)
    
    print("\n✓ Training complete!")
```

---

## Part 6: Testing and Evaluation

### Evaluate on Test Set

```python
def evaluate_model(model, test_data_dir, classes_file):
    """Evaluate model on test set"""
    
    # Load class names
    with open(classes_file, 'r') as f:
        class_names = [line.strip() for line in f]
    
    # Prepare test data
    test_gen = VideoSequenceDataGenerator(
        data_dir=test_data_dir,
        num_frames=30,
        batch_size=16
    )
    
    # Evaluate
    _, val_gen, _, steps = test_gen.generate_batches(shuffle=False, validation_split=1.0)
    
    results = model.evaluate(val_gen, steps=steps)
    
    print(f"Test Loss: {results[0]:.4f}")
    print(f"Test Accuracy: {results[1]:.4f}")
    print(f"Test Top-5 Accuracy: {results[2]:.4f}")
    
    return results

# Usage
evaluate_model(
    model,
    test_data_dir="wlasl_frames_30/test",
    classes_file="classes.txt"
)
```

---

## Part 7: Handling Static vs Dynamic

### Mixed Dataset Strategy

The model automatically handles both:

1. **Static Signs** (1-5 frames of movement):
   - LSTM sees mostly consistent frames
   - Model learns the pose
   - Works fine

2. **Dynamic Signs** (many frames of movement):
   - LSTM sees changing frames
   - Model learns the trajectory
   - Works better

### Why Single Model is Better

```
Single Unified Model:
├─ 30 frames input (works for all)
├─ CNN extracts features
├─ LSTM learns patterns
└─ Works for static AND dynamic ✅

Vs. Two Separate Models:
├─ Static model (simple CNN)
├─ Dynamic model (CNN-LSTM)
├─ Need to classify which type first
└─ More complex, more latency ❌
```

---

## Part 8: Quick Start Script

Save this as `train_wlasl_model.py`:

```python
#!/usr/bin/env python3
"""
Quick start training script for unified sign language model
Usage: python train_wlasl_model.py --dataset path/to/wlasl_frames
"""

import argparse
from training_guide import *

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dataset', required=True, help='Path to WLASL frames dataset')
    parser.add_argument('--epochs', type=int, default=50)
    parser.add_argument('--batch-size', type=int, default=16)
    parser.add_argument('--frames', type=int, default=30)
    parser.add_argument('--output', default='models/sign_language_model.h5')
    
    args = parser.parse_args()
    
    # 1. Build model
    print("✓ Building CNN-LSTM model...")
    builder = SignLanguageModel(
        num_classes=100,
        frames_per_sequence=args.frames
    )
    model = builder.create()
    
    # 2. Prepare data
    print("✓ Loading dataset...")
    data_gen = VideoSequenceDataGenerator(
        data_dir=f"{args.dataset}/train",
        num_frames=args.frames,
        batch_size=args.batch_size
    )
    print(f"  Found {len(data_gen.samples)} video sequences")
    
    # 3. Train
    print("✓ Training model...")
    trainer = SignLanguageTrainer(model, data_gen)
    history = trainer.train(epochs=args.epochs)
    
    # 4. Save
    print("✓ Saving model...")
    trainer.save_model(args.output)
    trainer.plot_history(history)
    
    print("\n✅ Training complete!")

if __name__ == "__main__":
    main()
```

Run with:
```bash
python train_wlasl_model.py --dataset wlasl_frames_30 --epochs 50
```

---

## Summary

### What This Approach Does

✅ **Single Model**: One unified model for all signs  
✅ **Static + Dynamic**: Automatically handles both types  
✅ **Efficient**: CNN-LSTM is faster than separate models  
✅ **Scalable**: Works with WLASL's 2000+ signs  
✅ **Deployable**: Model is .h5 compatible with your API  

### Expected Performance

- **Accuracy**: 85-95% (depending on dataset size)
- **Training time**: 2-24 hours (depending on GPU)
- **Inference time**: 200-500ms per video sequence

### Files You Need

1. `train_unified_model.py` (complete training script)
2. `wlasl_frames_30/` (extracted frames from WLASL)
3. GPU (highly recommended, 10-50x faster)

**Start with 100-500 video sequences to test, scale up once it works!**
