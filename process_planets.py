import sys, os, glob
from PIL import Image, ImageDraw
import numpy as np

images = glob.glob("/home/bozyel67/.gemini/antigravity/brain/5e7e6dc7-1b3f-42f6-9c0b-eadd7c35feba/planet_*_*.jpg")
images.sort()

out_dir = "/home/bozyel67/Masaüstü/updates/MucizelerYolu"

for idx, img_path in enumerate(images):
    img = Image.open(img_path).convert("RGBA")
    w, h = img.size
    
    # Create radial gradient mask for high feathering
    # Center of image is (w/2, h/2). Max radius is w/2
    Y, X = np.ogrid[:h, :w]
    center_y, center_x = h/2, w/2
    dist_from_center = np.sqrt((X - center_x)**2 + (Y - center_y)**2)
    
    # The planet itself occupies about 90% of the image. 
    # We want it fully opaque up to 60%, then linearly fade out to 0 at 95%
    max_radius = min(w, h) / 2
    r_solid = max_radius * 0.70
    r_fade = max_radius * 0.95
    
    # Calculate alpha based on distance
    alpha = np.zeros((h, w), dtype=np.float32)
    alpha[dist_from_center <= r_solid] = 255.0
    
    fade_mask = (dist_from_center > r_solid) & (dist_from_center <= r_fade)
    alpha[fade_mask] = 255.0 * (1.0 - (dist_from_center[fade_mask] - r_solid) / (r_fade - r_solid))
    
    alpha = alpha.astype(np.uint8)
    
    mask = Image.fromarray(alpha, mode="L")
    img.putalpha(mask)
    
    # Also we want to preserve the planet's glow but remove the black background completely.
    # Actually putting the alpha mask handles the black background for the most part,
    # because the black corners will get 0 alpha. But what if the black leaks into the feather?
    # To fix this, we can set RGB to the planet color if it's too dark, or rely on additive blending in Godot.
    # Standard alpha blending will show the black fringe.
    # A simple fix for black fringe is un-premultiplying alpha, or just generating a better alpha mask from the luminance.
    
    # Let's generate a luminance mask and combine it with the radial mask
    img_hsv = img.convert("HSV")
    _, _, v = img_hsv.split()
    v_arr = np.array(v, dtype=np.float32)
    # Enhance V to create a soft luminance mask
    lum_alpha = (v_arr / 255.0) ** 0.5 * 255.0
    
    # Combine radial and luminance
    final_alpha = np.minimum(alpha, lum_alpha).astype(np.uint8)
    final_mask = Image.fromarray(final_alpha, mode="L")
    img.putalpha(final_mask)
    
    out_path = os.path.join(out_dir, f"planet_{idx+1}.png")
    img.save(out_path)
    print(f"Saved {out_path}")

