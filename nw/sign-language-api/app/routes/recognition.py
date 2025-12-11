from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from app.utils.model_loader import get_model
from app.utils.image_processor import ImageProcessor
from app.utils.constants import get_sign_text, get_animation_data
from app.utils.tts_service import get_tts_service
import numpy as np

router = APIRouter()

# Response models
class SignRecognitionResponse(BaseModel):
    """Response from sign recognition endpoint"""
    recognized_text: str
    confidence: float
    class_index: int
    animation_data: dict
    timestamp: str

class TextToAnimationResponse(BaseModel):
    """Response from text to animation endpoint"""
    input_text: str
    animation_frames: list
    audio_url: str

@router.post("/recognize-sign", response_model=SignRecognitionResponse)
async def recognize_sign(file: UploadFile = File(...)):
    """
    Recognize sign language from image
    
    Input: Image file (JPG, PNG)
    Output: Recognized text + confidence + animation data
    """
    try:
        # Read image
        image_data = await file.read()
        
        # Process image
        processed_image = ImageProcessor.process_image(image_data)
        
        # Get model and make prediction
        model = get_model()
        predictions = model.predict(processed_image, verbose=0)
        
        # Get top prediction
        class_index = np.argmax(predictions[0])
        confidence = float(predictions[0][class_index])
        recognized_text = get_sign_text(class_index)
        
        # Get animation data
        animation_data = get_animation_data(recognized_text)
        
        # Generate TTS (optional)
        tts = get_tts_service()
        tts.speak(recognized_text)
        
        from datetime import datetime
        
        return SignRecognitionResponse(
            recognized_text=recognized_text,
            confidence=confidence,
            class_index=class_index,
            animation_data=animation_data,
            timestamp=datetime.now().isoformat()
        )
    
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing image: {str(e)}")

@router.post("/text-to-animation")
async def text_to_animation(text: str):
    """
    Convert text to sign language animation
    (Similar to Hand Talk app)
    
    Input: Text string
    Output: Animation frames + audio
    """
    try:
        animation_frames = []
        
        # Process each character
        for char in text.upper():
            if char.isalpha():
                animation = get_animation_data(char)
                animation['character'] = char
                animation_frames.append(animation)
        
        if not animation_frames:
            raise ValueError("No valid characters in input text")
        
        return TextToAnimationResponse(
            input_text=text,
            animation_frames=animation_frames,
            audio_url="/api/v1/audio/placeholder.mp3"  # Placeholder
        )
    
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing text: {str(e)}")

@router.get("/classes")
async def get_available_classes():
    """Get list of all available sign language classes"""
    from app.utils.constants import SIGN_LANGUAGE_CLASSES
    return {
        "total_classes": len(SIGN_LANGUAGE_CLASSES),
        "classes": SIGN_LANGUAGE_CLASSES
    }

@router.post("/batch-recognize")
async def batch_recognize(files: list[UploadFile] = File(...)):
    """
    Recognize multiple images at once (for better performance)
    Useful for processing video frames in sequence
    """
    try:
        results = []
        
        for file in files:
            image_data = await file.read()
            processed_image = ImageProcessor.process_image(image_data)
            
            model = get_model()
            predictions = model.predict(processed_image, verbose=0)
            
            class_index = np.argmax(predictions[0])
            confidence = float(predictions[0][class_index])
            
            results.append({
                "filename": file.filename,
                "recognized_text": get_sign_text(class_index),
                "confidence": confidence
            })
        
        return {"results": results, "total_processed": len(results)}
    
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Batch processing error: {str(e)}")
