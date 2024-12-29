from ..domain.models import ImageQuery, VisionResponse
from ..domain.interfaces import VisionService

class ProcessImageUseCase:
    def __init__(self, vision_service: VisionService):
        self._vision_service = vision_service

    async def execute(self, image_path: str, question: str) -> VisionResponse:
        query = ImageQuery(image_path=image_path, question=question)
        return await self._vision_service.analyze_image(query) 