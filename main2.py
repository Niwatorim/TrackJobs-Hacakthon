from flask import Flask, jsonify, request
from flask_cors import CORS
from ultralytics import YOLO
import base64, io
from PIL import Image
import numpy as np
from LLM_process import LLM_proc  # assuming it returns a string
app = Flask(__name__)
CORS(app)

from langchain_ollama import OllamaLLM
from langchain_core.prompts import ChatPromptTemplate

model = OllamaLLM(model="gemma:2b")
template = ChatPromptTemplate.from_template("""
You are assistance to blind people, and need to answer questions about the object.
Details: {data}
Extra information: {response}
Here is the user request: {user}
**RETURN NOTHING ELSE BUT THE RESPONSE TO USER QUERY**
**DONT RETURN A DISTANCE UNLESS ASKED EXPLICITLY**
""")
chain = template | model

# Load YOLO once
model = YOLO("trackjob-best.pt")
class Detectedobj():
    def __init__(self,cls_name, distance_in_meters, direction):
        self.cls=cls_name
        self.distance=distance_in_meters
        self.direction=direction

def base64_to_image_array(base64_str):
    image_data = base64.b64decode(base64_str)
    image = Image.open(io.BytesIO(image_data)).convert("RGB")
    return np.array(image)

def convert_to_distance(p):
    return (p / 1000) * 2

def plot_direction(x, y, frame_width, frame_height):
    width_third = frame_width / 3
    height_third = frame_height / 3
    horizontal = "left" if x < width_third else "right" if x > 2 * width_third else "center"
    vertical = "top" if y < height_third else "bottom" if y > 2 * height_third else "center"
    return f"{horizontal} {vertical}" if horizontal != "center" or vertical != "center" else "center"

def detect_object(img_array, frame_width, frame_height):
    results = model.predict(img_array)
    all=[]

    for r in results:

        for box in r.boxes:
            cls = int(box.cls[0])
            cls_name = model.names[cls]

            x1, y1, x2, y2 = map(int, box.xyxy[0])
            w, h = x2 - x1, y2 - y1
            perimeter = 2 * (w + h)
            mid_x, mid_y = (x1 + x2) / 2, (y1 + y2) / 2

            distance = convert_to_distance(perimeter)
            direction = plot_direction(mid_x, mid_y, frame_width, frame_height)
            obj= Detectedobj(cls_name,distance,direction)
            all.append(obj)
            

    return all


@app.route("/find", methods=["POST"])
def find():
    req = request.json
    if not req or "img" not in req or "user" not in req:
        return jsonify({"msg": "Invalid input"}), 400
    print("req obtained")

    frame_width = int(req.get("frameWidth"))
    frame_height = int(req.get("frameHeight"))
    img_array = base64_to_image_array(req["img"])

    objects = detect_object(img_array, frame_width, frame_height)

    if not objects:
        return jsonify({"msg": "No object detected"}), 200

    # Find the object with the minimum distance
    closest_obj = min(objects, key=lambda o: o.distance)
    direction = closest_obj.direction
    distance = closest_obj.distance

    # Build response message
    if direction != "center":
        text = f"It is to your {direction}. "
    else:
        text = "It is right in front of you. "

    if distance >= 0.6:
        text += "It's still a bit far, please go a bit more forward."
    elif distance <= 0.5:
        text += "It's within arm's reach!"
    text += " It's " + str(round(float(distance), 2)) + " meters away."


    print("completed object")
    debug_info = f"Closest object is {closest_obj.cls}, Direction is {direction}, Distance {distance}"
    print(debug_info)

    return jsonify({"msg": text})


@app.route("/", methods=["POST"])
def webcam():

    req = request.json
    if not req or "img" not in req or "user" not in req:
        return jsonify({"msg": "Invalid input"}), 400
    print("req obtained")

    frame_width = int(req.get("frameWidth"))
    frame_height = int(req.get("frameHeight"))
    img_array = base64_to_image_array(req["img"])

    objects = detect_object(img_array, frame_width, frame_height)
    obj=objects[0].cls
    direction=objects[0].direction
    distance=objects[0].distance
    
    if not obj:
            return jsonify({"msg": "No object detected"}), 200
    
    obj=objects[0].cls
    direction=objects[0].direction
    distance=objects[0].distance
    if distance<= 0.5:
        reach="Its within arms reach!"
    elif distance>0.6 or distance < 1.5:
        reach = "its a few steps away"
    else:
        reach = "its far"
    data = f"object detect is {obj}, Direction is {direction}, Distance {distance}, {reach}"


    # if len(objects)==1:
    #     obj=objects[0].cls
    #     direction=objects[0].direction
    #     distance=objects[0].distance
    #     data = f"object detect is {obj}, Direction is {direction}, Distance {distance}"
    # else:
    #     data="There are multiple objects\n"
    #     for o in objects:
    #         objeck = o.cls
    #         direction = o.direction
    #         distance = o.distance
    #         data += f"object detected is {objeck}, Direction is {direction}, Distance {distance}\n"

    print("completed object")

    print(data)

    try:
        result = LLM_proc(data, req["user"],chain)
        print("completed LLM")
        return jsonify({"msg": result}), 200
    except Exception as e:
        print(f"LLM error: {e}")
        return jsonify({"msg": "Server error"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
