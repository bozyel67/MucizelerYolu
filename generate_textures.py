import numpy as np
from PIL import Image

def generate_ceramic():
    # 512x512 tile
    size = 512
    img = np.ones((size, size, 3), dtype=np.uint8) * 240 # off-white
    
    # Draw grid lines for tiles
    grid_spacing = 128
    line_thickness = 4
    
    for i in range(0, size, grid_spacing):
        img[i:i+line_thickness, :] = [200, 200, 200]
        img[:, i:i+line_thickness] = [200, 200, 200]
        
    Image.fromarray(img).save("ceramic_diffuse.png")

def generate_marble():
    # Very simple marble/stone look (just some noise)
    size = 512
    np.random.seed(42)
    noise = np.random.normal(230, 10, (size, size)).clip(0, 255).astype(np.uint8)
    img = np.stack([noise]*3, axis=-1)
    
    # Add some soft lines (veins)
    for i in range(5):
        x = np.random.randint(0, size)
        img[:, x:x+2] = [200, 200, 200]
    
    Image.fromarray(img).save("marble_diffuse.png")

generate_ceramic()
generate_marble()
