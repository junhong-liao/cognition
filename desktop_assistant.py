from dotenv import load_dotenv
from datetime import datetime

# Load environment variables from .env file
load_dotenv()

import os
import openai
import lmnt
import cv2
import pygame
import speech_recognition as sr
import requests
import time
import base64
from openai import OpenAI
import asyncio
from lmnt.api import Speech

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "YOUR_OPENAI_API_KEY")
LMNT_API_KEY = os.getenv("LMNT_API_KEY", "YOUR_LMNT_API_KEY")
openai.api_key = OPENAI_API_KEY

# Initialize the OpenAI client
client = OpenAI()

# If you have a local or specialized endpoint (replace or remove this if not needed):
BACKEND_URL = "http://127.0.0.1:5000/process-image"

# ------------------------------------------------------------------------------
# Helper: Listen for Question
# ------------------------------------------------------------------------------

def listen_for_question(timeout: int = 100, phrase_time_limit: int = 100) -> str:
    r = sr.Recognizer()
    with sr.Microphone() as source:
        print("Please ask your question. Listening for up to 100 seconds...")
        audio = r.listen(source, timeout=timeout, phrase_time_limit=phrase_time_limit)

    try:
        recognized_text = r.recognize_google(audio)
        print(f"Recognized text: '{recognized_text}'")
        return recognized_text
    except sr.UnknownValueError:
        raise RuntimeError("Speech recognition could not understand audio.")
    except sr.RequestError as e:
        raise RuntimeError(f"Could not request results from speech recognition service; {e}")

# ------------------------------------------------------------------------------
# Helper: Capture Photo
# ------------------------------------------------------------------------------

def capture_photo() -> str:
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Unable to access the camera.")
        return None

    ret, frame = cap.read()
    if not ret:
        print("Error: Failed to capture image.")
        cap.release()
        return None

    photo_path = "desktop_photo.jpg"
    cv2.imwrite(photo_path, frame)
    cap.release()
    print(f"Captured photo and saved to '{photo_path}'.")
    
    return photo_path

# ------------------------------------------------------------------------------
# Helper: Process with OpenAI (Image-Capable Endpoint)
# ------------------------------------------------------------------------------

def encode_image(image_path: str) -> str:
    """
    Read an image from disk and return a base64-encoded string of its binary data.
    """
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode("utf-8")

def process_image_and_question(image_path: str, question: str) -> str:
    """
    Use the GPT-4o-mini model with additional context prompt.
    """
    base64_image = encode_image(image_path)
    
    # Shorter system context
    system_context = """You are Son, a concise yet informative vision assistant for the visually impaired. Start descriptions with 'I see'""
"""

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": system_context
            },
            {
                "role": "user", 
                "content": [
                    {"type": "text", "text": question},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{base64_image}",
                            "detail": "low"  # Change to low unless high detail is needed
                        }
                    }
                ]
            }
        ],
        max_tokens=300  # Reduced from 500
    )

    return response.choices[0].message.content

# ------------------------------------------------------------------------------
# Helper: Speak with LMNT
# ------------------------------------------------------------------------------

async def speak_with_lmnt(text: str):
    """
    Use LMNT's async API to synthesize speech from text and play it.
    """
    if not LMNT_API_KEY or LMNT_API_KEY == "YOUR_LMNT_API_KEY":
        print("[Warning] No valid LMNT_API_KEY found. Skipping TTS.")
        return

    try:
        async with Speech(LMNT_API_KEY) as speech:
            synthesis = await speech.synthesize(
                text=text,
                voice='lily',
                format='mp3',
                speed=1.1  # I currently like this speed 
            )

            # Save the audio to a temporary file
            output_file = "response_temp.mp3"
            with open(output_file, 'wb') as f:
                f.write(synthesis['audio'])

            # Play the audio using pygame
            pygame.mixer.init()
            pygame.mixer.music.load(output_file)
            pygame.mixer.music.play()

            # Wait for playback to finish
            while pygame.mixer.music.get_busy():
                await asyncio.sleep(0.1)

            # Cleanup
            if os.path.exists(output_file):
                os.remove(output_file)

    except Exception as e:
        print(f"[Error] LMNT TTS synthesis failed: {e}")

# ------------------------------------------------------------------------------
# Main Workflow
# ------------------------------------------------------------------------------

def log_timing(operation: str, start_time: datetime) -> float:    # for figuringout latency issues. biggest hurdle rn is openai api
    """Calculate and log the duration of an operation."""
    duration = (datetime.now() - start_time).total_seconds()
    print(f"{operation}: {duration:.2f} seconds")
    return duration

async def main():
    camera = None
    photo_path = None
    running = True

    try:
        total_start_time = datetime.now()
        # Initialize and warm up camera
        camera_start = datetime.now()
        camera = cv2.VideoCapture(0)
        if not camera.isOpened():
            print("Error: Unable to access the camera.")
            return

        # Camera setup and warmup
        camera.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        camera.set(cv2.CAP_PROP_FPS, 30)
        camera.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        
        for _ in range(2):
            camera.read()
            await asyncio.sleep(0.05)
        
        log_timing("Camera initialization", camera_start)

        print("Son is ready! Say 'stop' to exit.")
        await speak_with_lmnt("Hi! I'm Son. I'm here to help you navigate the world")
        
        while running:   # while loop so it wont stop after one request
            try:
                iteration_start = datetime.now()
                
                # 1) Listen for the user's question
                listen_start = datetime.now()
                question = listen_for_question()
                listen_duration = log_timing("Speech recognition", listen_start)
                
                # Check if user wants to stop
                if question.lower().strip() == "stop":
                    print("Stopping the assistant...")
                    break

                # 2) Capture a photo
                photo_start = datetime.now()
                ret, frame = camera.read()
                if not ret:
                    print("Error: Failed to capture image.")
                    continue

                # Delete previous photo if it exists
                if photo_path and os.path.exists(photo_path):
                    os.remove(photo_path)

                photo_path = "desktop_photo.jpg"
                cv2.imwrite(photo_path, frame)
                photo_duration = log_timing("Photo capture", photo_start)

                # 3) Send the question & image to OpenAI
                gpt_start = datetime.now()
                answer = process_image_and_question(photo_path, question)
                gpt_duration = log_timing("GPT processing", gpt_start)

                # 4) Speak the response with LMNT
                speech_start = datetime.now()
                await speak_with_lmnt(answer)
                speech_duration = log_timing("Speech synthesis and playback", speech_start)

                # Log total iteration time
                total_duration = log_timing("Total iteration", iteration_start)
                print(f"\nBreakdown for this iteration:")
                print(f"Speech Recognition: {listen_duration:.2f}s ({(listen_duration/total_duration)*100:.1f}%)")
                print(f"Photo Capture: {photo_duration:.2f}s ({(photo_duration/total_duration)*100:.1f}%)")
                print(f"GPT Processing: {gpt_duration:.2f}s ({(gpt_duration/total_duration)*100:.1f}%)")
                print(f"Speech Synthesis: {speech_duration:.2f}s ({(speech_duration/total_duration)*100:.1f}%)")
                print(f"Total Time: {total_duration:.2f}s\n")

                # Clean up photo after each successful interaction
                if photo_path and os.path.exists(photo_path):
                    os.remove(photo_path)

            except Exception as e:
                print(f"[Error in interaction] {e}")
                print("Ready for next question...")
                continue

    except Exception as e:
        print(f"[Critical Error] {e}")
    finally:
        # Cleanup and log total runtime
        if camera is not None:
            camera.release()
        if photo_path and os.path.exists(photo_path):
            os.remove(photo_path)
        total_runtime = log_timing("Total runtime", total_start_time)
        print("Assistant stopped. Goodbye!")
        await speak_with_lmnt("Goodbye")
# ------------------------------------------------------------------------------
# Entry Point
# ------------------------------------------------------------------------------
if __name__ == "__main__":
    asyncio.run(main())