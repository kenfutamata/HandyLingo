import cv2
import numpy as np
from PIL import Image
from io import BytesIO

class ImageProcessor:
    """Process and preprocess images for sign language model"""
    
    TARGET_SIZE = (224, 224)
    
    @staticmethod
    def process_image(image_data: bytes) -> np.ndarray:
        """
        Process raw image bytes to model input format
        
        Args:
            image_data: Raw image bytes
            
        Returns:
            Preprocessed image array ready for inference
        """
        # Decode image
        img = Image.open(BytesIO(image_data))
        img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
        
        # Resize
        img = cv2.resize(img, ImageProcessor.TARGET_SIZE)
        
        # Normalize
        img = img.astype('float32') / 255.0
        
        # Add batch dimension
        img = np.expand_dims(img, axis=0)
        
        return img
    
    @staticmethod
    def process_video_frame(frame: np.ndarray) -> np.ndarray:
        """
        Process a single video frame from camera
        
        Args:
            frame: OpenCV frame
            
        Returns:
            Preprocessed frame
        """
        # Resize
        frame = cv2.resize(frame, ImageProcessor.TARGET_SIZE)
        
        # Normalize
        frame = frame.astype('float32') / 255.0
        
        # Add batch dimension
        frame = np.expand_dims(frame, axis=0)
        
        return frame
    
    @staticmethod
    def extract_hand_region(frame: np.ndarray, confidence_threshold: float = 0.5):
        """
        Extract hand region using MediaPipe (optional enhancement)
        This helps focus on hands only, improving accuracy
        """
        try:
            import mediapipe as mp
            
            hands = mp.solutions.hands.Hands(
                static_image_mode=False,
                max_num_hands=2,
                min_detection_confidence=confidence_threshold
            )
            
            results = hands.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            return results.multi_hand_landmarks
        except ImportError:
            print("MediaPipe not installed. Skipping hand extraction.")
            return None
