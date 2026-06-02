from PIL import Image, ImageDraw

def draw_crosshair(image_path, out_path, x, y, size=10):
    img = Image.open(image_path).convert("RGB")
    draw = ImageDraw.Draw(img)
    # x, y are in 140x140 scale. Convert back to 1024.
    x_px = x * (1024.0 / 140.0)
    y_px = y * (1024.0 / 140.0)
    r = size * (1024.0 / 140.0)
    draw.line((x_px - r, y_px, x_px + r, y_px), fill="red", width=5)
    draw.line((x_px, y_px - r, x_px, y_px + r), fill="red", width=5)
    img.save(out_path)

draw_crosshair("/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay/NotchPlay.app/Contents/Resources/turntable_bg_rega.png", "/Users/hyeonm9/.gemini/antigravity/scratch/NotchPlay/rega_crosshair.png", 47.5, 71.5)
