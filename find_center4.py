import cv2
import numpy as np

def find_platter_center(image_path, is_black=True):
    img = cv2.imread(image_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    if is_black:
        # Threshold for black platter
        _, thresh = cv2.threshold(gray, 30, 255, cv2.THRESH_BINARY_INV)
    else:
        # Threshold for white platter (Braun)
        _, thresh = cv2.threshold(gray, 230, 255, cv2.THRESH_BINARY)
        
    # Find contours
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Find the largest contour
    if not contours:
        return None
        
    largest_contour = max(contours, key=cv2.contourArea)
    
    # Get bounding box of the largest contour
    x, y, w, h = cv2.boundingRect(largest_contour)
    
    # Calculate center
    cx = x + w / 2.0
    cy = y + h / 2.0
    
    # Scale to 140x140
    width = img.shape[1]
    scale = 140.0 / width
    return (cx * scale, cy * scale, w * scale, h * scale)

print("Rega:")
print(find_platter_center("/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay/NotchPlay.app/Contents/Resources/turntable_bg_rega.png", is_black=True))
