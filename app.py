from flask import Flask, request, jsonify
import openai

app = Flask(__name__)

# Set your OpenAI API key
openai.api_key = "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"

@app.route("/")
def home():
    return "Flask backend is running! Use the /process-image endpoint to process images."
@app.route("/process-image", methods=["POST"])

def process_image():
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    image_file = request.files['file']
    image_path = "uploaded_image.jpg"
    image_file.save(image_path)

    try:
        # Example image analysis using OpenAI
        response = openai.Image.create(
            model="image-alpha-001",  # Replace with the appropriate model
            file=open(image_path, "rb")
        )
        return jsonify({"result": response}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5001)
