from flask import Flask
from LLM_process import LLM_proc
import json
from flask import jsonify, request
from flask_cors import CORS
import base64
from ultralytics import YOLO

app=Flask(__name__)
CORS(app)


def string_to_img(web_data):
    image_data = base64.b64decode(web_data)
    file_path = "output_image.png"
    with open(file_path, "wb") as f:
        f.write(image_data)
    return file_path

def convert_to_distance(p):
    d = (p/1000)*2
    return d

def plot_direction(x, y, frame_width, frame_height):
    # use the midpoint to see how it is relative to the coordinates of the phone screen 7.7 width 16.2 height
    width_third = frame_width / 3
    height_third = frame_height / 3

    # horizontal coordinate
    if x < width_third:
        horizontal = "left"
    elif x > 2 * width_third:
        horizontal = "right"
    else:
        horizontal = "center"
    
    # vertical coordinate 
    if y < height_third:
        vertical = "top"
    elif y > 2 * height_third:
        vertical = "bottom"
    else:
        vertical = "center"
    
    # combine positions
    if horizontal == "center" and vertical == "center":
        return "center"
    elif horizontal == "center":
        return f"center {vertical}"
    elif vertical == "center":
        return f"{horizontal} center"
    else:
        return f"{horizontal} {vertical}"
    
def detect_object(image_path, frame_width, frame_height):
    model_path = "trackjob-best.pt"
    model = YOLO(model_path) 

    results = model(image_path)

    for r in results:
        boxes = r.boxes
        for box in boxes:
            cls = int(box.cls[0])
            cls_name = model.names[cls]

            x1, y1, x2, y2 = box.xyxy[0]
            x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)
            w, h = x2-x1, y2-y1

            perimeter = 2*w + 2*h
            mid_x, mid_y = ((x1+x2)/2), ((y1+y2)/2)

            distance_in_meters = convert_to_distance(perimeter)
            direction = plot_direction(mid_x, mid_y, frame_width, frame_height)

            print(f"Perimeter: {perimeter}")
            print(f"Midpoint: {mid_x:.1f}, {mid_y:.1f}")
            print(f"Distance in meters: {distance_in_meters}")
            print(f"Direction: {direction}")
            print("-" * 30)
            return cls_name, distance_in_meters, direction

@app.route("/",methods = ["POST"])
def webcam():
    req = request.json
    if not req or "img" not in req or "user" not in req:
        return jsonify({"msg":"Invalid input"}),400
    
    web_data = req.get("img")
    user_req = req.get("user")
    frame_height = req.get("frameHeight")
    frame_width = req.get("frameWidth")

    image_path = string_to_img(web_data)

    print(f"Frame dimensions: {frame_width} x {frame_height}")
    
    obj, distance, direction = detect_object(image_path, frame_width, frame_height)
    
    data = f"object detect is {obj}, Direction is {direction}, Distance {distance}"

    try:
        print(LLM_proc(data,user_req))
        result= LLM_proc(data,user_req)
        return jsonify({"msg":result}),200
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"msg":"Server error"}),500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
