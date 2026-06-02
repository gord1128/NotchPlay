import cv2
import numpy as np
from PIL import Image, ImageDraw

SCALE = 140.0 / 1024.0

def find_hole(image_path, output_path):
    img = cv2.imread(image_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # The hole is dark. Let's find dark circles.
    blurred = cv2.GaussianBlur(gray, (9, 9), 2)
    circles = cv2.HoughCircles(
        blurred, cv2.HOUGH_GRADIENT, 1, 20,
        param1=50, param2=30,
        minRadius=30, maxRadius=100
    )
    
    if circles is not None:
        circles = np.around(circles[0]).astype(int)
        
        # Filter circles to find ones on the left side (x < 512)
        left_circles = [c for c in circles if c[0] < 512]
        
        if left_circles:
            # Assume the one with lowest brightness in center is the hole
            best_c = None
            min_val = 255
            for c in left_circles:
                cx, cy, r = c
                val = gray[cy, cx]
                if val < min_val:
                    min_val = val
                    best_c = c
                    
            if best_c is not None:
                cx, cy, r = best_c
                print(f"Hole found (raw px): center=({cx}, {cy}), radius={r}")
                print(f"Hole found (140 scale): center=({cx*SCALE:.1f}, {cy*SCALE:.1f})")
                
                # Draw on image
                pil_img = Image.open(image_path).convert("RGB")
                draw = ImageDraw.Draw(pil_img)
                draw.ellipse([cx-r, cy-r, cx+r, cy+r], outline="red", width=4)
                draw.line([cx-20, cy, cx+20, cy], fill="red", width=2)
                draw.line([cx, cy-20, cx, cy+20], fill="red", width=2)
                pil_img.save(output_path)
                print(f"Saved overlay: {output_path}")
                return (cx*SCALE, cy*SCALE)
            
    print("Hole not found using HoughCircles. Trying contours...")
    _, thresh = cv2.threshold(gray, 80, 255, cv2.THRESH_BINARY_INV)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    for cnt in contours:
        x, y, w, h = cv2.boundingRect(cnt)
        if x < 512 and 50 < w < 200 and 50 < h < 200:
            cx = x + w/2
            cy = y + h/2
            print(f"Contour hole found (raw px): center=({cx}, {cy})")
            print(f"Contour hole found (140 scale): center=({cx*SCALE:.1f}, {cy*SCALE:.1f})")
            return (cx*SCALE, cy*SCALE)
            
    print("Hole not found.")
    return None

find_hole("/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay/NotchPlay.app/Contents/Resources/turntable_bg_braun.png", "/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay/hole_braun.png")
