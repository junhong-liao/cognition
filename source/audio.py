import speech_recognition as sr
import pygame
import asyncio
from lmnt.api import Speech

def listen_for_question(timeout: int = 100, phrase_time_limit: int = 100) -> str:
    """Listens for a question and converts it to text."""
    r = sr.Recognizer()
    with sr.Microphone() as source:
        print("Please ask your question...")
        audio = r.listen(source, timeout=timeout, phrase_time_limit=phrase_time_limit)

    try:
        return r.recognize_google(audio)
    except sr.UnknownValueError:
        raise RuntimeError("Speech recognition could not understand audio.")
    except sr.RequestError as e:
        raise RuntimeError(f"Speech recognition request failed: {e}")

async def speak_with_lmnt(api_key: str, text: str):
    """Synthesizes speech using LMNT and plays it."""
    if not api_key:
        print("[Warning] No LMNT API key provided. Skipping TTS.")
        return

    try:
        async with Speech(api_key) as speech:
            synthesis = await speech.synthesize(text=text, voice='lily', format='mp3', speed=1.1)
            output_file = "response_temp.mp3"
            with open(output_file, 'wb') as f:
                f.write(synthesis['audio'])

            pygame.mixer.init()
            pygame.mixer.music.load(output_file)
            pygame.mixer.music.play()
            while pygame.mixer.music.get_busy():
                await asyncio.sleep(0.1)
            os.remove(output_file)
    except Exception as e:
        print(f"[Error in TTS synthesis] {e}")
