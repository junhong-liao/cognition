import os
import requests
import speech_recognition as sr
from gtts import gTTS
import pygame
import cv2

BACKEND_URL = "http://127.0.0.1:5000/process-image"

def speak(text):
    """Convert text to speech and play it."""
    tts = gTTS(text, lang="en")
    tts.save("response.mp3")
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

def upload_photo(photo_path):
    """Upload the photo to the backend for processing."""
    if not photo_path:
        speak("Error: No photo to upload.")
        return

    with open(photo_path, "rb") as image_file:
        response = requests.post(
            BACKEND_URL, 
            files={"file": image_file}
        )
        if response.status_code == 200:
            result = response.json().get("result", {})
            speak(f"The photo contains: {result}")
        else:
            speak(f"Error: {response.json().get('error', 'Unknown error')}")

def listen_for_command():
    """Listen for voice commands."""
    recognizer = sr.Recognizer()
    with sr.Microphone() as source:
        print("Listening for command...")
        audio = recognizer.listen(source)

    try:
        command = recognizer.recognize_google(audio)
        print(f"Command heard: {command}")
        if "photo" in command.lower():
            photo_path = capture_photo()
            upload_photo(photo_path)
        else:
            speak("I didn't understand the command.")
    except Exception as e:
        print(f"Error: {e}")
        speak("Sorry, I couldn't understand you.")

if __name__ == "__main__":
    listen_for_command()
