from flask import Flask
from flask_cors import CORS
from LLM_process import LLM_proc
from flask import jsonify, request
import asyncio
import base64

app = Flask(__name__)
CORS(app)

def string_to_img(web_data):
    image_data = base64.b64decode(web_data)

    with open("output_image.png", "wb") as image_file:
        image_file.write(image_data)

@app.route("/", methods=["POST"])
def webcam():
    req = request.json
    if not req or "img" not in req or "user" not in req:
        return jsonify({"message": "Invalid input"}), 400
    img = req.get("img")
    string_to_img(img)
    user = req.get("user")
    frame_height = req.get("frameHeight")
    frame_width = req.get("frameWidth")
    # Simulated object detection
    obj, direction, distance = "spoon", "forward", "3 meters"
    data = f"object detected is {obj}, Direction is: {direction}, At a distance of: {distance}, with frame {frame_height} x {frame_width}"
    print(data)
    try:
        # Pass the coroutine to asyncio.run
        result = LLM_proc(data,user)
        return jsonify({"msg": result}), 200
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"msg": "Error occurred"}), 500
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)