from dataclasses import dataclass
import os
from typing import Optional

@dataclass
class AppConfig:
    # API Keys
    OPENAI_API_KEY: str = os.getenv('OPENAI_API_KEY', '')
    LMNT_API_KEY: str = os.getenv('LMNT_API_KEY', '')
    
    # Server Configuration
    BACKEND_URL: str = os.getenv('BACKEND_URL', 'http://127.0.0.1:5000')
    
    # LMNT Configuration
    LMNT_VOICE: str = os.getenv('LMNT_VOICE', 'default')
    LMNT_SPEED: float = float(os.getenv('LMNT_SPEED', '1.0'))
    
    # OpenAI Configuration
    OPENAI_MODEL: str = os.getenv('OPENAI_MODEL', 'gpt-4-vision-preview')
    
    # Audio Configuration
    AUDIO_TIMEOUT: int = int(os.getenv('AUDIO_TIMEOUT', '5'))
    PHRASE_TIME_LIMIT: int = int(os.getenv('PHRASE_TIME_LIMIT', '10'))
    
    # File Paths
    TEMP_PHOTO_PATH: str = os.getenv('TEMP_PHOTO_PATH', 'desktop_photo.jpg')
    TEMP_AUDIO_PATH: str = os.getenv('TEMP_AUDIO_PATH', 'response_temp.mp3')

    def validate(self) -> Optional[str]:
        """Validate the configuration and return error message if invalid."""
        if not self.OPENAI_API_KEY:
            return "OpenAI API key is required"
        if not self.LMNT_API_KEY:
            return "LMNT API key is required"
        return None

config = AppConfig() 