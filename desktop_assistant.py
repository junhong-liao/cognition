import os
import openai
import lmnt
import cv2
import pygame
import speech_recognition as sr
import tkinter as tk
import threading

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "YOUR_OPENAI_API_KEY")
LMNT_API_KEY = os.getenv("LMNT_API_KEY", "YOUR_LMNT_API_KEY")
openai.api_key = OPENAI_API_KEY

# If you're using a local backend or a different server, replace this
BACKEND_URL = "http://127.0.0.1:5000/process-image"

# ------------------------------------------------------------------------------
# GUI Setup
# ------------------------------------------------------------------------------

def create_gui():
    root = tk.Tk()
    root.title("Desktop Assistant")
    label = tk.Label(root, text="Desktop Assistant is running...", font=("Helvetica", 16))
    label.pack(padx=20, pady=20)
    root.geometry("300x100")
    root.mainloop()

# ------------------------------------------------------------------------------
# Helper: Speak with LMNT
# ------------------------------------------------------------------------------

def speak_with_lmnt(text: str):
    """
    Convert text to speech using LMNT and play it using Pygame.
    """
    if not LMNT_API_KEY or LMNT_API_KEY == "YOUR_LMNT_API_KEY":
        print("[Warning] No valid LMNT_API_KEY found. Skipping TTS.")
        return

    lmnt_client = lmnt.Client(api_key=LMNT_API_KEY)
    speech = lmnt_client.synthesize(
        text=text,
        voice="your_preferred_voice",  # Adjust voice name if needed
        speed=1.0
    )

    # Save to a temp file and play with pygame
    speech.save("response_temp.mp3")

    pygame.mixer.init()
    pygame.mixer.music.load("response_temp.mp3")
    pygame.mixer.music.play()

    # Wait until playback completes
    while pygame.mixer.music.get_busy():
        pass

    # Optionally remove the temp file after playback
    if os.path.exists("response_temp.mp3"):
        os.remove("response_temp.mp3")


# ------------------------------------------------------------------------------
# Helper: Capture Photo with OpenCV
# ------------------------------------------------------------------------------

def capture_photo() -> str:
    """
    Capture a photo using the computer's webcam, save it to disk,
    and return the path. Return None on failure.
    """
    cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
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
    return photo_path


# ------------------------------------------------------------------------------
# Helper: Recognize Speech
# ------------------------------------------------------------------------------

def listen_for_question(timeout: int = 100, phrase_time_limit: int = 60) -> str:
    """
    Use the microphone to capture audio and convert it to text.
    Returns the recognized text or raises an exception if recognition fails.
    """
    r = sr.Recognizer()
    with sr.Microphone() as source:
        print("Please ask your question. Listening for up to 100 seconds...")
        audio = r.listen(source, timeout=timeout, phrase_time_limit=phrase_time_limit)

    # Use Google's free speech API or a different one if you prefer
    try:
        recognized_text = r.recognize_google(audio)
        print(f"Recognized text: '{recognized_text}'")
        return recognized_text
    except sr.UnknownValueError:
        raise RuntimeError("Speech recognition could not understand audio.")
    except sr.RequestError as e:
        raise RuntimeError(f"Could not request results from speech recognition service; {e}")


# ------------------------------------------------------------------------------
# Helper: Send to OpenAI or Custom Backend
# ------------------------------------------------------------------------------

def process_image_and_question_with_openai(image_path: str, question: str) -> str:
    """
    Stub function showing how to call OpenAI's GPT or a custom backend to process
    the question + image. If you have a local backend, you can do a requests.post
    to BACKEND_URL. Below is an example of directly calling GPT with text alone.
    """
    # If you have a custom server that processes images, do something like:
    #
    #   with open(image_path, "rb") as img_file:
    #       files = {"file": img_file}
    #       data = {"question": question}
    #       response = requests.post(BACKEND_URL, files=files, data=data)
    #       ...
    #
    # For a simple text-based GPT request:
    prompt = (
        f"You see an image (imagine it’s attached). The user asks: \"{question}\"\n"
        "What do you see in the image, and how would you answer that question?"
    )
    completion = openai.Completion.create(
        engine="text-davinci-003",
        prompt=prompt,
        max_tokens=200
    )

    text_response = completion.choices[0].text.strip()
    return text_response


# ------------------------------------------------------------------------------
# Main Desktop Workflow
# ------------------------------------------------------------------------------

def main():
    # Start the GUI in a separate thread
    gui_thread = threading.Thread(target=create_gui)
    gui_thread.start()

    try:
        # 1) Listen for a question
        question = listen_for_question()

        # 2) Capture a photo
        photo_path = capture_photo()
        if not photo_path:
            print("[Error] Could not capture photo. Exiting.")
            return

        print(f"Photo saved to '{photo_path}'.")

        # 3) Process with OpenAI or your backend
        answer = process_image_and_question_with_openai(photo_path, question)
        print(f"Answer: {answer}")

        # 4) Use LMNT TTS
        speak_with_lmnt(answer)

    except Exception as e:
        print(f"[Error] {e}")

# ------------------------------------------------------------------------------
# Entry point
# ------------------------------------------------------------------------------
if __name__ == "__main__":
    main() 