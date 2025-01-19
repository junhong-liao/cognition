import asyncio
from datetime import datetime
from dotenv import load_dotenv
import os
from camera import initialize_camera, capture_photo, cleanup_photo
from audio import listen_for_question, speak_with_lmnt
from openai_client import process_image_and_question
from utils import log_timing

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "YOUR_OPENAI_API_KEY")
LMNT_API_KEY = os.getenv("LMNT_API_KEY", "YOUR_LMNT_API_KEY")

async def main():
    try:
        camera = initialize_camera()
        print("Assistant ready! Say 'stop' to exit.")
        await speak_with_lmnt(LMNT_API_KEY, "Hi! I'm Son. I'm here to help you navigate the world.")
        
        while True:
            iteration_start = datetime.now()
            question = listen_for_question()
            if question.lower() == "stop":
                break

            photo_path = capture_photo(camera)
            answer = process_image_and_question(OPENAI_API_KEY, photo_path, question)
            await speak_with_lmnt(LMNT_API_KEY, answer)
            cleanup_photo(photo_path)
            log_timing("Total iteration", iteration_start)

    except Exception as e:
        print(f"[Critical Error] {e}")
    finally:
        print("Goodbye!")
        await speak_with_lmnt(LMNT_API_KEY, "Goodbye!")

if __name__ == "__main__":
    asyncio.run(main())
