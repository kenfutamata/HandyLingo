# Sign Language Recognition API - Setup Guide

## Quick Start (5 minutes)

### Step 1: Install Dependencies
```powershell
cd c:\Users\Chaos\Desktop\nw\sign-language-api
pip install -r requirements.txt
```

### Step 2: Prepare Your Model
If you have a trained `.h5` model:
```powershell
python convert_model.py path/to/your/model.h5
```

This will create optimized versions of your model in the `models/` folder.

### Step 3: Start the API Server
```powershell
python main.py
```

You'll see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Press CTRL+C to quit
```

### Step 4: Test the API
In a new PowerShell window:
```powershell
python test_api.py
```

Visit the interactive docs:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## API Endpoints Reference

### 1. **Health Check**
```
GET /health
```
Verify the API is running.

### 2. **Recognize Sign from Image**
```
POST /api/v1/recognize-sign
Content-Type: multipart/form-data

Body: file (image file)
```

**Response:**
```json
{
  "recognized_text": "A",
  "confidence": 0.95,
  "class_index": 0,
  "animation_data": {
    "pose": "hand_closed",
    "movement": "static"
  },
  "timestamp": "2025-12-11T10:30:00"
}
```

### 3. **Text to Animation**
```
POST /api/v1/text-to-animation?text=HELLO
```

**Response:**
```json
{
  "input_text": "HELLO",
  "animation_frames": [
    {"character": "H", "pose": "...", "movement": "..."},
    {"character": "E", "pose": "...", "movement": "..."},
    ...
  ],
  "audio_url": "/api/v1/audio/placeholder.mp3"
}
```

### 4. **Batch Recognition**
```
POST /api/v1/batch-recognize
Content-Type: multipart/form-data

Body: files (multiple image files)
```

Great for processing video frames efficiently.

### 5. **Get Available Classes**
```
GET /api/v1/classes
```

Returns all sign language classes your model recognizes.

---

## Integration with Flutter/Dart App

### Example Flutter Client Code

```dart
import 'package:http/http.dart' as http;
import 'dart:io';

class SignLanguageClient {
  final String apiUrl = 'http://192.168.1.100:8000'; // Your server IP
  
  // Recognize sign from image
  Future<Map<String, dynamic>> recognizeSign(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiUrl/api/v1/recognize-sign'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    
    var response = await request.send();
    var decoded = jsonDecode(await response.stream.bytesToString());
    return decoded;
  }
  
  // Convert text to animation
  Future<Map<String, dynamic>> textToAnimation(String text) async {
    final response = await http.post(
      Uri.parse('$apiUrl/api/v1/text-to-animation?text=$text'),
    );
    return jsonDecode(response.body);
  }
}
```

---

## Deployment Options

### Option A: Local Development
- Run on your laptop with GPU
- Perfect for testing
- Start: `python main.py`

### Option B: Docker (Recommended)
```powershell
docker-compose up --build
```

### Option C: Cloud Deployment

**Google Cloud Run** (free tier available):
```powershell
gcloud run deploy sign-language-api `
  --source . `
  --platform managed `
  --region us-central1 `
  --allow-unauthenticated
```

**AWS Lambda** + API Gateway:
- Package app with dependencies
- Deploy as serverless function
- Scales automatically

**Heroku** (simple):
```powershell
heroku create your-app-name
heroku container:push web
heroku container:release web
```

---

## Performance Optimization Checklist

- [ ] **Input Reduction**: Send 224×224 images (not full 1080p)
- [ ] **Batch Processing**: Send multiple frames at once
- [ ] **Caching**: Cache results for common signs
- [ ] **Compression**: Compress images before sending
- [ ] **GPU Server**: Deploy on GPU instance for 10-50x speedup
- [ ] **Model Quantization**: Use quantized models for faster inference
- [ ] **Load Balancing**: Use multiple API instances
- [ ] **CDN**: Cache responses at edge

---

## Next Steps

1. **Replace Dummy Model**: Copy your trained `.h5` model to `models/sign_language_model.h5`
2. **Run Conversion Script**: `python convert_model.py models/sign_language_model.h5`
3. **Test Endpoints**: Use `test_api.py` or visit `/docs`
4. **Build Flutter App**: Use the example client code above
5. **Deploy**: Follow deployment option of your choice
6. **Monitor**: Check logs for errors and performance

---

## Troubleshooting

### API Won't Start
```powershell
# Check if port 8000 is in use
netstat -ano | findstr :8000
# Kill the process or use different port
# python main.py --port 8001
```

### Model Not Loading
- Ensure `models/sign_language_model.h5` exists
- Check model format is valid: `python -c "import tensorflow as tf; tf.keras.models.load_model('models/sign_language_model.h5')"`

### Slow Inference
- Check if GPU is being used (should see GPU memory in logs)
- Reduce image size input
- Use batch processing
- Upgrade to GPU server

### CORS Errors in Flutter
- API already has `CORSMiddleware` enabled
- If still issues, add to Flutter: `headers: {'Content-Type': 'application/json'}`

---

## Support & Resources

- FastAPI Docs: https://fastapi.tiangolo.com
- TensorFlow Lite Guide: https://www.tensorflow.org/lite/guide
- Flutter HTTP: https://pub.dev/packages/http
- MediaPipe Hands: https://google.github.io/mediapipe/solutions/hands.html

---

**Happy Building! 🚀**
