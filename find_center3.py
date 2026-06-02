from PIL import Image

def find_center_and_size(image_path, condition):
    img = Image.open(image_path).convert("RGB")
    width, height = img.size
    
    min_x, max_x = width, 0
    min_y, max_y = height, 0
    
    for y in range(height):
        for x in range(width):
            r, g, b = img.getpixel((x, y))
            if condition(r, g, b):
                if x < min_x: min_x = x
                if x > max_x: max_x = x
                if y < min_y: min_y = y
                if y > max_y: max_y = y
                
    cx = (min_x + max_x) / 2.0
    cy = (min_y + max_y) / 2.0
    diam_x = max_x - min_x
    diam_y = max_y - min_y
    
    scale = 140.0 / width
    return (cx * scale, cy * scale, diam_x * scale, diam_y * scale)

print("Technics Platter (Dark grey circle):")
# The base is dark, so condition should catch the strobe dots which are bright, or the dark platter itself against the slightly brighter gold base.
# Let's just find the bounding box of pixels where r < 50, g < 50, b < 50.
print(find_center_and_size("/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay/NotchPlay.app/Contents/Resources/turntable_bg.png", lambda r,g,b: (r<30 and g<30 and b<30)))

