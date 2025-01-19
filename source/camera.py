import cv2
import os

def initialize_camera() -> cv2.VideoCapture:
    """Initializes the camera with predefined settings."""
    camera = cv2.VideoCapture(0)
    if not camera.isOpened():
        raise RuntimeError("Error: Unable to access the camera.")
    camera.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    camera.set(cv2.CAP_PROP_FPS, 30)
    camera.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
    return camera

def capture_photo(camera: cv2.VideoCapture, photo_path: str = "desktop_photo.jpg") -> str:
    """Captures a photo using the provided camera."""
    ret, frame = camera.read()
    if not ret:
        raise RuntimeError("Error: Failed to capture image.")
    cv2.imwrite(photo_path, frame)
    return photo_path

def cleanup_photo(photo_path: str):
    """Deletes the captured photo."""
    if os.path.exists(photo_path):
        os.remove(photo_path)
