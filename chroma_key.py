from PIL import Image
import sys

def remove_green(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    data = img.getdata()
    
    new_data = []
    for item in data:
        r, g, b, a = item
        
        # Determine how "green" the pixel is.
        # Background is pure #00FF00
        # Gold is around #D4AF37 (high red, high green, low blue)
        # So greenness is best measured by how much G exceeds R.
        greenness = g - r
        
        if greenness > 20:
            # Fade out alpha based on greenness
            alpha = 255 - (greenness - 20) * 4
            if alpha < 0: alpha = 0
            if alpha > 255: alpha = 255
            # To fix green fringing on edges, we also desaturate the green channel
            # by clamping it to red.
            new_g = min(g, r)
            new_data.append((r, new_g, b, alpha))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(output_path, "PNG")

if __name__ == "__main__":
    remove_green(sys.argv[1], sys.argv[2])
