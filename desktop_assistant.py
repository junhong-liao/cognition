from dotenv import load_dotenv

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

    system_context = """Your name is Son and you are a helpful AI vision assistant for the blind and visually impaired. 
    When answering questions about images, be detailed but concise in your observations. 
    Focus on the most relevant aspects of the image that relate to the user's question. Your goal is to help the blind user userstand the images."""

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
                    {
                        "type": "text",
                        "text": question,
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{base64_image}",
                            "detail": "high"
                        }
                    }
                ]
            }
        ],
        max_tokens=100
    )

    # Return the content of the first choice
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
            # Synthesize the text to speech
            synthesis = await speech.synthesize(
                text=text,
                voice='lily',  # or your preferred voice
                format='mp3'
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

async def main():
    camera = None
    photo_path = None
    try:
        # Initialize and warm up camera
        camera = cv2.VideoCapture(0)
        if not camera.isOpened():
            print("Error: Unable to access the camera.")
            return

        # Set camera properties for better exposure
        camera.set(cv2.CAP_PROP_AUTO_EXPOSURE, 0.75)
        camera.set(cv2.CAP_PROP_BRIGHTNESS, 128)
        
        # Warm up the camera by capturing a few frames
        for _ in range(5):
            camera.read()
            time.sleep(0.1)

        # 1) Listen for the user's question
        question = listen_for_question()

        # 2) Capture a photo
        ret, frame = camera.read()
        if not ret:
            print("Error: Failed to capture image.")
            return

        photo_path = "desktop_photo.jpg"
        cv2.imwrite(photo_path, frame)
        print(f"Captured photo and saved to '{photo_path}'.")

        # 3) Send the question & image to OpenAI
        answer = process_image_and_question(photo_path, question)
        print(f"Answer: {answer}")

        # 4) Speak the response with LMNT
        await speak_with_lmnt(answer)

    except Exception as e:
        print(f"[Error] {e}")
    finally:
        # Cleanup: Release camera and delete temporary photo
        if camera is not None:
            camera.release()
        if photo_path and os.path.exists(photo_path):
            os.remove(photo_path)
            print(f"Deleted temporary photo: {photo_path}")

# ------------------------------------------------------------------------------
# Entry Point
# ------------------------------------------------------------------------------
if __name__ == "__main__":
    asyncio.run(main()) 