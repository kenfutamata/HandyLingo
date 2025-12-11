# Quick test script to verify API is working

import requests
import cv2
import numpy as np
from pathlib import Path

API_URL = "http://localhost:8000/api/v1"

def test_health():
    """Test if API is running"""
    try:
        response = requests.get("http://localhost:8000/health")
        print(f"✓ API Health: {response.json()}")
        return True
    except Exception as e:
        print(f"✗ API not responding: {e}")
        return False

def test_classes():
    """Get available sign classes"""
    try:
        response = requests.get(f"{API_URL}/classes")
        print(f"✓ Available classes: {response.json()['total_classes']}")
    except Exception as e:
        print(f"✗ Error: {e}")

def test_image_recognition(image_path: str):
    """Test sign recognition with an image"""
    try:
        with open(image_path, "rb") as f:
            files = {"file": f}
            response = requests.post(f"{API_URL}/recognize-sign", files=files)
            result = response.json()
            print(f"✓ Recognized: {result['recognized_text']}")
            print(f"  Confidence: {result['confidence']:.2%}")
            print(f"  Animation: {result['animation_data']}")
    except Exception as e:
        print(f"✗ Error: {e}")

def test_text_to_animation(text: str):
    """Test text to animation conversion"""
    try:
        response = requests.post(f"{API_URL}/text-to-animation", params={"text": text})
        result = response.json()
        print(f"✓ Animation frames for '{text}':")
        for frame in result['animation_frames']:
            print(f"  {frame}")
    except Exception as e:
        print(f"✗ Error: {e}")

if __name__ == "__main__":
    print("=== Sign Language API Test Suite ===\n")
    
    print("1. Testing health endpoint...")
    if not test_health():
        print("Start the API first: python main.py")
        exit(1)
    
    print("\n2. Getting available classes...")
    test_classes()
    
    print("\n3. Testing text-to-animation...")
    test_text_to_animation("HELLO")
    
    print("\n✓ Basic tests complete!")
