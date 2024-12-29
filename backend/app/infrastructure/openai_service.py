import openai
from ..domain.models import ImageQuery, VisionResponse
from ..domain.interfaces import VisionService
import os

class OpenAIVisionService(VisionService):
    def __init__(self, api_key: str):
        openai.api_key = api_key

    async def analyze_image(self, query: ImageQuery) -> VisionResponse:
        try:
            response = openai.ChatCompletion.create(
                model="gpt-4-vision-preview",
                messages=[{
                    "role": "user",
                    "content": [
                        {"type": "text", "text": query.question},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"file://{os.path.abspath(query.image_path)}"
                            }
                        }
                    ]
                }]
            )
            return VisionResponse(result=response.choices[0].message.content)
        except Exception as e:
            return VisionResponse(result="", error=str(e)) 