import cv2
import numpy as np
from PIL import Image, ImageDraw

# Each image is 1024x1024, displayed in 140x140 frame.
# Scale factor: 140/1024 = 0.13671875

SCALE = 140.0 / 1024.0

def find_spindle(image_path, name):
    """Find the spindle (center metallic dot) in the turntable image."""
    img = cv2.imread(image_path)
    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # The spindle is a small bright metallic circle in the center area of the platter.
    # Strategy: Look for small bright circles using HoughCircles
    # First, let's try to find the platter circle (the big one)
    blurred = cv2.GaussianBlur(gray, (9, 9), 2)
    
    # Find large circles (the platter)
    platter_circles = cv2.HoughCircles(
        blurred, cv2.HOUGH_GRADIENT, 1, 100,
        param1=100, param2=40,
        minRadius=int(w * 0.25), maxRadius=int(w * 0.5)
    )
    
    if platter_circles is not None:
        platter_circles = np.around(platter_circles[0]).astype(int)
        # Take the largest circle as the platter
        largest = max(platter_circles, key=lambda c: c[2])
        px, py, pr = largest
        print(f"{name} Platter (raw px): center=({px}, {py}), radius={pr}")
        print(f"{name} Platter (140 scale): center=({px*SCALE:.1f}, {py*SCALE:.1f}), diameter={pr*2*SCALE:.1f}")
        
        # Now find the spindle: small bright circle near the platter center
        # Search in a small region around platter center
        margin = 100
        roi_x1 = max(0, px - margin)
        roi_y1 = max(0, py - margin)
        roi_x2 = min(w, px + margin)
        roi_y2 = min(h, py + margin)
        
        roi = gray[roi_y1:roi_y2, roi_x1:roi_x2]
        roi_blurred = cv2.GaussianBlur(roi, (5, 5), 1)
        
        spindle_circles = cv2.HoughCircles(
            roi_blurred, cv2.HOUGH_GRADIENT, 1, 20,
            param1=80, param2=25,
            minRadius=3, maxRadius=30
        )
        
        if spindle_circles is not None:
            spindle_circles = np.around(spindle_circles[0]).astype(int)
            # Find the brightest small circle (the metallic spindle)
            best_brightness = 0
            best_spindle = None
            for sc in spindle_circles:
                sx, sy, sr = sc
                abs_x = roi_x1 + sx
                abs_y = roi_y1 + sy
                # Check brightness
                mask = np.zeros_like(gray)
                cv2.circle(mask, (abs_x, abs_y), sr, 255, -1)
                brightness = cv2.mean(gray, mask=mask)[0]
                if brightness > best_brightness:
                    best_brightness = brightness
                    best_spindle = (abs_x, abs_y, sr)
            
            if best_spindle:
                sx, sy, sr = best_spindle
                print(f"{name} Spindle (raw px): center=({sx}, {sy}), radius={sr}")
                print(f"{name} Spindle (140 scale): center=({sx*SCALE:.1f}, {sy*SCALE:.1f})")
                return (px, py, pr, sx, sy)
        
        # If spindle detection fails, use platter center
        print(f"{name}: Spindle not found, using platter center")
        return (px, py, pr, px, py)
    else:
        print(f"{name}: No platter found!")
        return None

def draw_overlay(image_path, output_path, cx, cy, pr, sx, sy, name):
    """Draw detected circles on image for visual verification."""
    img = Image.open(image_path).convert("RGB")
    draw = ImageDraw.Draw(img)
    
    # Draw platter circle (green)
    draw.ellipse([cx-pr, cy-pr, cx+pr, cy+pr], outline="lime", width=4)
    
    # Draw spindle center (red crosshair)
    draw.line([sx-30, sy, sx+30, sy], fill="red", width=3)
    draw.line([sx, sy-30, sx, sy+30], fill="red", width=3)
    
    # Draw the record overlay circle at spindle center (cyan, this is where record will go)
    # Record should be slightly smaller than platter
    rr = int(pr * 0.92)
    draw.ellipse([sx-rr, sy-rr, sx+rr, sy+rr], outline="cyan", width=3)
    
    img.save(output_path)
    print(f"  Saved overlay: {output_path}")

base_dir = "/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay/NotchPlay.app/Contents/Resources"
out_dir = "/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay"

images = [
    (f"{base_dir}/turntable_bg.png", "Technics Gold"),
    (f"{base_dir}/turntable_bg_braun.png", "Braun SK4"),
    (f"{base_dir}/turntable_bg_anni.png", "Technics 50th"),
    (f"{base_dir}/turntable_bg_rega.png", "Rega Planar"),
]

print("="*60)
for img_path, name in images:
    result = find_spindle(img_path, name)
    if result:
        px, py, pr, sx, sy = result
        out_path = f"{out_dir}/overlay_{name.replace(' ', '_').lower()}.png"
        draw_overlay(img_path, out_path, px, py, pr, sx, sy, name)
    print("-"*60)
