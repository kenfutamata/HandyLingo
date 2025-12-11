from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import recognition
from app.utils.model_loader import load_model
import uvicorn

# Initialize FastAPI app
app = FastAPI(
    title="Sign Language Recognition API",
    description="Real-time sign language to text conversion",
    version="1.0.0"
)

# Add CORS middleware for Flutter/Android app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes
app.include_router(recognition.router, prefix="/api/v1", tags=["recognition"])

@app.on_event("startup")
async def startup_event():
    """Load model on startup"""
    print("Loading sign language model...")
    load_model()
    print("Model loaded successfully!")

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "service": "Sign Language API"}

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Sign Language Recognition API",
        "docs": "/docs",
        "health": "/health"
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
