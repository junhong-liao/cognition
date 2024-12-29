from flask import Flask, request, jsonify
from flask_cors import CORS
import openai
import os

app = Flask(__name__)
CORS(app)

# Set your OpenAI API key
openai.api_key = os.getenv('OPENAI_API_KEY')

@app.route("/process-image", methods=["POST"])
def process_image():
    # 1. Get image and question from request
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    image_file = request.files['file']
    question = request.form.get('question', '')
    image_path = "uploaded_image.jpg"
    image_file.save(image_path)

    try:
        # 2. Process with OpenAI Vision
        response = openai.ChatCompletion.create(
            model="gpt-4-vision-preview",
            messages=[{
                "role": "user",
                "content": [
                    {"type": "text", "text": question},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"file://{os.path.abspath(image_path)}"
                        }
                    }
                ]
            }]
        )
        
        # 3. Return the response
        answer = response.choices[0].message.content
        return jsonify({"result": answer}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5001) 