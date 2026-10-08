import math

def generate_apple(filename="apple.obj"):
    with open(filename, 'w') as f:
        f.write("o Apple\n")
        
        # Apple parameters
        radius = 0.5
        segments = 32
        rings = 32
        
        vertices = []
        for i in range(rings + 1):
            v = i / rings
            phi = v * math.pi
            
            # Apple shape deformation:
            # Flatter on top and bottom, slight indentation at top and bottom.
            # R(v) modifies the radius based on vertical angle.
            shape_factor = 1.0 - 0.2 * math.sin(phi)**3 - 0.1 * math.cos(phi)
            # Indent top (v near 0) and bottom (v near 1)
            indent = 0.0
            if v < 0.2:
                indent = -0.3 * (0.2 - v)
            elif v > 0.8:
                indent = -0.3 * (v - 0.8)
                
            r = radius * shape_factor * math.sin(phi)
            y = radius * math.cos(phi) + indent
            
            for j in range(segments):
                u = j / segments
                theta = u * 2 * math.pi
                
                x = r * math.cos(theta)
                z = r * math.sin(theta)
                
                vertices.append((x, y, z))
                f.write(f"v {x:.4f} {y:.4f} {z:.4f}\n")
                
        # Stem
        stem_start = len(vertices) + 1
        f.write(f"v 0 {radius - 0.1} 0\n")
        f.write(f"v 0.05 {radius + 0.15} 0.05\n")
        f.write(f"v -0.02 {radius + 0.12} -0.05\n")
        
        # Faces
        for i in range(rings):
            for j in range(segments):
                next_j = (j + 1) % segments
                
                v1 = i * segments + j + 1
                v2 = i * segments + next_j + 1
                v3 = (i + 1) * segments + next_j + 1
                v4 = (i + 1) * segments + j + 1
                
                f.write(f"f {v1} {v2} {v3} {v4}\n")

if __name__ == "__main__":
    generate_apple("/home/bozyel67/Masaüstü/updates/MucizelerYolu/apple.obj")
