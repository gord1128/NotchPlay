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

print("Braun Platter (White circle):")
print(find_center_and_size("/Users/hyeonm9/.gemini/antigravity/brain/0a012dc9-1ac4-460b-b6a2-5cceddbc6ac7/turntable_braun_base_1780081900373.png", lambda r,g,b: (r>240 and g>240 and b>240)))

print("Rega Platter (Black circle):")
print(find_center_and_size("/Users/hyeonm9/.gemini/antigravity/brain/0a012dc9-1ac4-460b-b6a2-5cceddbc6ac7/turntable_rega_base_1780081929287.png", lambda r,g,b: (r<20 and g<20 and b<20)))
