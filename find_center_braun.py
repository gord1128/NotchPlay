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
    
    if not contours:
        return None
        
    # We might have multiple contours (e.g. the base itself might be white)
    # We should filter by circularity or just find the largest one that is not the whole image.
    # Actually, for Braun, the platter is very circular and large.
    valid_contours = []
    for cnt in contours:
        x, y, w, h = cv2.boundingRect(cnt)
        if w > 100 and h > 100 and w < 900 and h < 900: # filter out small noise and the whole image boundary
            valid_contours.append(cnt)
            
    if not valid_contours:
        return None
        
    largest_contour = max(valid_contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(largest_contour)
    
    # Calculate center
    cx = x + w / 2.0
    cy = y + h / 2.0
    
    # Scale to 140x140
    width = img.shape[1]
    scale = 140.0 / width
    return (cx * scale, cy * scale, w * scale, h * scale)

print("Braun:")
print(find_platter_center("/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay/NotchPlay.app/Contents/Resources/turntable_bg_braun.png", is_black=False))
