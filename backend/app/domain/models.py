from dataclasses import dataclass
from typing import Optional
from pathlib import Path

@dataclass
class ImageQuery:
    image_path: Path
    question: str

    def __post_init__(self):
        if not self.image_path.exists():
            raise ValueError(f"Image file does not exist: {self.image_path}")
        if not self.question.strip():
            raise ValueError("Question cannot be empty")

@dataclass
class VisionResponse:
    result: str
    error: Optional[str] = None

    def __post_init__(self):
        if not self.result and not self.error:
            raise ValueError("Either result or error must be provided") 