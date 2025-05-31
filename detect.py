import cv2
from ultralytics import YOLO

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


def main():
    model_path = "best.pt"
    model = YOLO(model_path)

    cap = cv2.VideoCapture(0)
    while cap.isOpened():
        ret, frame = cap.read()
        
        if not ret:
            break

        frame_height, frame_width = frame.shape[:2]
        print(f"Frame dimensions: {frame_width} x {frame_height}")

        results = model(frame)

        annotated_frame = results[0].plot() 

        for r in results:
            boxes = r.boxes
            for box in boxes:
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


        cv2.imshow("YOLOv8 Detection", annotated_frame)

        if cv2.waitKey(10) & 0xFF == ord('q'):
            break
            
    cap.release()
    cv2.destroyAllWindows()
    
if __name__ == "__main__":
    main()