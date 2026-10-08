import sys
from PIL import Image, ImageDraw

img_path = sys.argv[1]
out_path = sys.argv[2]

img = Image.open(img_path).convert("RGBA")
# Make a circular mask
mask = Image.new("L", img.size, 0)
draw = ImageDraw.Draw(mask)
# Draw a circle slightly smaller than the image to cut out the planet
# The generated image has a small border, so we adjust bounding box
w, h = img.size
bbox = (w*0.05, h*0.05, w*0.95, h*0.95)
draw.ellipse(bbox, fill=255)

# Apply mask
img.putalpha(mask)
img.save(out_path)
