import os
import requests
import speech_recognition as sr
import pygame
import cv2
import lmnt

BACKEND_URL = "http://127.0.0.1:5000/process-image"
LMNT_API_KEY = "your_lmnt_api_key"

def speak(text):
    """Convert text to speech using LMNT and play it."""
    lmnt_client = lmnt.Client(api_key=LMNT_API_KEY)
    
    speech = lmnt_client.synthesize(
        text=text,
        voice="your_preferred_voice",
        speed=1.0
    )
    
    speech.save("response.mp3")
    
    pygame.mixer.init()
    pygame.mixer.music.load("response.mp3")
    pygame.mixer.music.play()
    while pygame.mixer.music.get_busy():
        continue

def capture_photo():
    """Capture a new photo using the computer's webcam."""
    print("Capturing photo using webcam...")
    camera = cv2.VideoCapture(0)  # Open webcam (camera index 0)
    
    if not camera.isOpened():
        print("Error: Unable to access the camera.")
        return None
    
    ret, frame = camera.read()  # Capture a frame
    if ret:
        photo_path = "new_photo.jpg"  # Save captured photo as 'new_photo.jpg'
        cv2.imwrite(photo_path, frame)
        print(f"Photo saved to {photo_path}")
        camera.release()
        return photo_path
    else:
        print("Error: Failed to capture image.")
        camera.release()
        return None

def upload_photo(photo_path, question):
    """Upload the photo and question to the backend for processing."""
    if not photo_path:
        speak("Error: No photo to upload.")
        return

    with open(photo_path, "rb") as image_file:
        response = requests.post(
            BACKEND_URL, 
            files={"file": image_file},
            data={"question": question}  # Send the question along with the image
        )
        if response.status_code == 200:
            result = response.json().get("result", {})
            speak(result)  # Speak the response directly
        else:
            speak(f"Error: {response.json().get('error', 'Unknown error')}")

def listen_for_command():
    """Listen for questions about the environment."""
    recognizer = sr.Recognizer()
    
    # Step 1: Capture audio from the microphone
    with sr.Microphone() as source:
        print("Listening for your question...")
        audio = recognizer.listen(source)

    try:
        # Step 2: Convert audio to text (recognize the questi