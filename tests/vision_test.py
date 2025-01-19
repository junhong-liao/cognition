import cv2

try:
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        raise RuntimeError("Unable to access the camera.")
    
    while True:
        ret, frame = cap.read()
        if not ret:
            raise RuntimeError("Failed to capture frame from camera.")
            
        try:
            cv2.imshow("Camera Test", frame)
            key = cv2.waitKey(1)  # Wait 1ms between frames
            if key == ord('q'):  # Allow quitting with 'q' key
                print("Test terminated by user")
                break
        except Exception as e:
            print(f"Error displaying image: {str(e)}")
            break
            
except Exception as e:
    print(f"Camera error: {str(e)}")
finally:
    if 'cap' in locals():
        cap.release()
        cv2.destroyAllWindows()