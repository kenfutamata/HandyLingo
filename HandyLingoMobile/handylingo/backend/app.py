import os
import time

os.environ['PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION'] = 'python'

import cv2
import math
import numpy as np
from ultralytics import YOLO
import mediapipe as mp

# 1. VERIFICATION CHECK
try:
    mp_holistic = mp.solutions.holistic
    mp_drawing = mp.solutions.drawing_utils
    print("SUCCESS: MediaPipe loaded correctly!")
except AttributeError:
    print("ERROR: MediaPipe attribute error.")
    exit()

# --- SIGN LANGUAGE MODEL SETUP ---
MODEL_PATH = "best.pt"
try:
    model = YOLO(MODEL_PATH)
    print("SUCCESS: YOLOv8 Classification model loaded!")
    print("CURRENT MODEL LABELS:", model.names)
except Exception as e:
    print(f"ERROR: Could not load YOLO model: {e}")
    exit()

# --- SETTINGS ---
MOVE_THRESHOLD = 0.02
# Lowered threshold to 0.3 to make detection easier for tricky signs like "Please"
CONFIDENCE_THRESHOLD = 0.3


def calculate_distance(p1, p2):
    return math.sqrt((p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2)


def main():
    cap = cv2.VideoCapture(0)
    prev_pos = {'head': None, 'chest': None}
    predicted_text = "Waiting..."
    confidence_score = 0
    window_opened = False

    # Recording variables
    is_recording = False
    record_start_time = 0
    video_writer = None

    with mp_holistic.Holistic(min_detection_confidence=0.5, min_tracking_confidence=0.5) as holistic:
        while cap.isOpened():
            success, frame = cap.read()
            if not success: break

            frame = cv2.flip(frame, 1)
            h, w, _ = frame.shape
            display_frame = frame.copy()

            # --- 1. MEDIA PIPE PROCESSING ---
            results = holistic.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))

            # --- 2. SMART SIGN-ZONE CROPPING ---
            x_min, y_min, x_max, y_max = 0, 0, 0, 0
            found_zone = False

            # PRIORITY 1: Hand Landmarks (Most accurate)
            hand_lms = results.right_hand_landmarks or results.left_hand_landmarks
            if hand_lms:
                landmarks = hand_lms.landmark
                padding = 80
                x_min = int(min([lm.x for lm in landmarks]) * w) - padding
                x_max = int(max([lm.x for lm in landmarks]) * w) + padding
                y_min = int(min([lm.y for lm in landmarks]) * h) - padding
                y_max = int(max([lm.y for lm in landmarks]) * h) + padding
                found_zone = True

            # PRIORITY 2: Pose Fallback (Best for "Please" where hand touches chest)
            elif results.pose_landmarks:
                # Use Shoulders (11, 12) to create a "Chest Zone"
                l_sh = results.pose_landmarks.landmark[11]
                r_sh = results.pose_landmarks.landmark[12]
                if l_sh.visibility > 0.5 and r_sh.visibility > 0.5:
                    # Create a box around the chest area
                    x_center = int((l_sh.x + r_sh.x) / 2 * w)
                    y_center = int((l_sh.y + r_sh.y) / 2 * h)
                    box_size = 250  # Larger box to catch the hand on the chest
                    x_min, x_max = x_center - box_size, x_center + box_size
                    y_min, y_max = y_center - box_size, y_center + box_size
                    found_zone = True

            # --- 3. PREDICTION ---
            if found_zone:
                x_min, y_min = max(0, x_min), max(0, y_min)
                x_max, y_max = min(w, x_max), min(h, y_max)

                if x_max > x_min and y_max > y_min:
                    crop = frame[y_min:y_max, x_min:x_max]
                    crop_resized = cv2.resize(crop, (224, 224))
                    cv2.imshow('YOLO_INPUT_VIEW', crop_resized)
                    window_opened = True

                    yolo_results = model(crop_resized, stream=True, verbose=False)
                    for r in yolo_results:
                        if r.probs is not None:
                            top_idx = r.probs.top1
                            confidence_score = r.probs.top1conf.item()
                            if confidence_score > CONFIDENCE_THRESHOLD:
                                predicted_text = r.names[top_idx]
                            else:
                                predicted_text = "Analyzing..."
                    cv2.rectangle(display_frame, (x_min, y_min), (x_max, y_max), (0, 255, 255), 2)
            else:
                predicted_text = "Show Sign..."
                confidence_score = 0

            # --- 4. MOVEMENT DETECTION & DRAWING ---
            status = []
            if results.pose_landmarks:
                nose = results.pose_landmarks.landmark[0]
                if prev_pos['head'] and calculate_distance(nose, prev_pos['head']) > MOVE_THRESHOLD:
                    status.append("Head Moving")
                prev_pos['head'] = nose
                mp_drawing.draw_landmarks(display_frame, results.pose_landmarks, mp_holistic.POSE_CONNECTIONS)

            if hand_lms:
                mp_drawing.draw_landmarks(display_frame, hand_lms, mp_holistic.HAND_CONNECTIONS)

            # --- 5. UI & RECORDING ---
            # Header Bar
            cv2.rectangle(display_frame, (0, 0), (w, 60), (245, 117, 16), -1)
            display_str = f"SIGN: {predicted_text.upper()} ({confidence_score:.2f})"
            cv2.putText(display_frame, display_str, (10, 40), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)

            key = cv2.waitKey(1)
            if key & 0xFF == ord('r') and not is_recording:
                is_recording = True
                record_start_time = time.time()
                fourcc = cv2.VideoWriter_fourcc(*'mp4v')
                video_writer = cv2.VideoWriter('sign_recording.mp4', fourcc, 20.0, (w, h))
                print("Recording...")

            if is_recording:
                elapsed = time.time() - record_start_time
                if elapsed <= 5:
                    cv2.circle(display_frame, (w - 30, 30), 10, (0, 0, 255), -1)
                    cv2.putText(display_frame, f"REC {int(5 - elapsed)}s", (w - 120, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.7,
                                (0, 0, 255), 2)
                    video_writer.write(display_frame)
                else:
                    is_recording = False
                    video_writer.release()
                    print("Saved.")

            cv2.imshow('HandyLingo', display_frame)
            if key & 0xFF == 27: break

    cap.release()
    if video_writer: video_writer.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()