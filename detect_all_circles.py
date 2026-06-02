import cv2
import numpy as np
from PIL import Image, ImageDraw

SCALE = 140.0 / 1024.0

def find_platter_precise(image_path, name):
    """Find the platter and spindle with manual verification overlay."""
    img = cv2.imread(image_path)
    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (9, 9), 2)
    
    # Find ALL circles
    circles = cv2.HoughCircles(
        blurred, cv2.HOUGH_GRADIENT, 1, 50,
        param1=80, param2=35,
        minRadius=100, maxRadius=int(w * 0.5)
    )
    
    results = []
    if circles is not None:
        circles = np.around(circles[0]).astype(int)
        for c in circles:
            results.append((c[0], c[1], c[2]))
        results.sort(key=lambda c: c[2])  # sort by radius
        
    print(f"\n{name}: Found {len(results)} circles")
    for i, (cx, cy, r) in enumerate(results):
        print(f"  Circle {i}: center=({cx*SCALE:.1f}, {cy*SCALE:.1f}), radius={r*SCALE:.1f}, diameter={r*2*SCALE:.1f}")
    
    return results

def draw_all_circles(image_path, output_path, circles, name):
    """Draw all detected circles with different colors for visual verification."""
    img = Image.open(image_path).convert("RGB")
    draw = ImageDraw.Draw(img)
    
    colors = ["red", "lime", "cyan", "yellow", "magenta", "orange"]
    for i, (cx, cy, r) in enumerate(circles):
        color = colors[i % len(colors)]
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], outline=color, width=4)
        # Draw center crosshair
        draw.line([cx-20, cy, cx+20, cy], fill=color, width=2)
        draw.line([cx, cy-20, cx, cy+20], fill=color, width=2)
    
    img.save(output_path)

base_dir = "/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay/NotchPlay.app/Contents/Resources"
out_dir = "/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay"

images = [
    (f"{base_dir}/turntable_bg.png", "Technics Gold"),
    (f"{base_dir}/turntable_bg_anni.png", "Technics 50th"),
]

for img_path, name in images:
    circles = find_platter_precise(img_path, name)
    out_path = f"{out_dir}/allcircles_{name.replace(' ', '_').lower()}.png"
    draw_all_circles(img_path, out_path, circles, name)
    print(f"  Saved: {out_path}")
