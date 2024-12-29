from abc import ABC, abstractmethod
from .models import ImageQuery, VisionResponse

class VisionService(ABC):
    @abstractmethod
    def analyze_image(self, query: ImageQuery) -> VisionResponse:
        """Analyze an image with a given question."""
        pass 