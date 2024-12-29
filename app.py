from flask import Flask, request, jsonify
import openai
import os

app = Flask(__name__)

# Set your OpenAI API key
openai.api_key = "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"

@app.route("/")
def home():
    return "Flask backend is running! Use the /process-image endpoint to process images."
@app.route("/process-image", methods=["POST"])

def process_image():
    # Check if an image file was included in the request
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    # Get the image and question from the request
    image_file = request.files['file']
    question = request.form.get('question', '')  # Gets the question, empty string if none provided
    image_path = "uploaded_image.jpg"
    image_file.save(image_path)

    try:
        # Use OpenAI's GPT-4 Vision API
        response = openai.ChatCompletion.create(
            model="gpt-4-vision-preview",  # GPT-4 with vision capabilities
            messages=[
                {
                    "role": "user",
                    "content": [
                        # Include both the question and image in the prompt
                        {"type": "text", "text": question},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"file://{os.path.abspath(image_path)}"
                            }
                        }
                    ]
                }
            ]
        )
        
        # Get the AI's response and send it back
        answer = response.choices[0].message.content
        return jsonify({"result": answer}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5001)
