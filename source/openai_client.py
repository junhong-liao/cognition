import base64
import openai

def encode_image(image_path: str) -> str:
    """Encodes an image to Base64 format."""
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode("utf-8")

def process_image_and_question(api_key: str, image_path: str, question: str) -> str:
    """Sends the image and question to OpenAI GPT and retrieves the response."""
    openai.api_key = api_key
    base64_image = encode_image(image_path)
    system_context = "You are Son, a concise yet informative vision assistant for the visually impaired. Start descriptions with 'I see.'"

    response = openai.ChatCompletion.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": system_context},
            {"role": "user", "content": question},
            {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}", "detail": "low"}}
        ],
        max_tokens=300
    )
    return response.choices[0].message.content
