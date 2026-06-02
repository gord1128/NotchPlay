import cv2
import numpy as np

def find_platter_center(image_path, is_black=True):
    img = cv2.imread(image_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # Technics is dark grey, let's just find the circle using HoughCircles
    circles = cv2.HoughCircles(gray, cv2.HOUGH_GRADIENT, 1, 20, param1=50, param2=30, minRadius=200, maxRadius=400)
    
    if circles is not None:
        circles = np.uint16(np.around(circles))
        for i in circles[0, :]:
            cx, cy, r = i[0], i[1], i[2]
            scale = 140.0 / img.shape[1]
            return (cx * scale, cy * scale, r * 2 * scale)
    return None

print("Technics:")
print(find_platter_center("/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay/NotchPlay.app/Contents/Resources/turntable_bg.png", is_black=True))
