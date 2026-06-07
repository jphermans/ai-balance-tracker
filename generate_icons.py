#!/usr/bin/env python3
"""Generate AI-themed app icon for AI Balance Tracker."""
from PIL import Image, ImageDraw, ImageFilter
import math
import os

SIZES = [
    ("20x20@2x", 40), ("20x20@3x", 60), ("20x20@1x", 20),
    ("29x29@1x", 29), ("29x29@2x", 58), ("29x29@3x", 87),
    ("40x40@1x", 40), ("40x40@2x", 80), ("40x40@3x", 120),
    ("60x60@2x", 120), ("60x60@3x", 180),
    ("76x76@1x", 76), ("76x76@2x", 152),
    ("83.5x83.5@2x", 167), ("1024x1024@1x", 1024),
]

OUTPUT_DIR = "ios/Runner/Assets.xcassets/AppIcon.appiconset"

def create_master_icon(size=1024):
    """Create the master icon at given size."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    margin = size * 0.1
    cx, cy = size / 2, size / 2
    r = size / 2 - margin

    # === Background: deep gradient circle with rounded corners feel ===
    # Draw a filled rounded rect or circle — iOS applies mask, so we fill full
    # Use a beautiful indigo→purple→blue gradient
    for y in range(size):
        t = y / size
        # Gradient from deep blue-purple (top) to vibrant purple-blue (bottom)
        r_val = int(30 + t * 40)
        g_val = int(20 + t * 60)
        b_val = int(120 + (1 - t) * 70)
        # Add subtle magenta shift
        r_val = min(255, r_val + int((1 - abs(t - 0.5) * 2) * 40))
        color = (r_val, g_val, b_val, 255)
        draw.line([(0, y), (size, y)], fill=color)

    # === Subtle radial glow (lighter center) ===
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    for i in range(3):
        gr = int(size * (0.5 - i * 0.12))
        alpha = int(30 - i * 10)
        glow_draw.ellipse(
            [cx - gr, cy - gr, cx + gr, cy + gr],
            fill=(255, 255, 255, alpha),
        )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=size * 0.08))
    img = Image.alpha_composite(img, glow)

    # === Central AI chip design ===
    # Hexagonal neural net node
    hx_c = (cx, cy)
    hx_r = size * 0.22

    # Draw hexagonal chip
    hx_points = []
    for i in range(6):
        angle = math.pi / 6 + i * math.pi / 3
        px = hx_c[0] + hx_r * math.cos(angle)
        py = hx_c[1] + hx_r * math.sin(angle)
        hx_points.append((px, py))

    # Hexagon fill with semi-transparent white
    draw.polygon(hx_points, fill=(255, 255, 255, 25), outline=(255, 255, 255, 80), width=3)

    # Inner hexagon
    inner_r = hx_r * 0.65
    inner_points = []
    for i in range(6):
        angle = math.pi / 6 + i * math.pi / 3
        px = hx_c[0] + inner_r * math.cos(angle)
        py = hx_c[1] + inner_r * math.sin(angle)
        inner_points.append((px, py))
    draw.polygon(inner_points, fill=(255, 255, 255, 15), outline=(255, 255, 255, 50), width=2)

    # === Neural network nodes (circles at hex vertices) ===
    node_r = size * 0.035
    for i in range(6):
        angle = math.pi / 6 + i * math.pi / 3
        nx = hx_c[0] + hx_r * math.cos(angle)
        ny = hx_c[1] + hx_r * math.sin(angle)
        # Outer glow
        draw.ellipse(
            [nx - node_r * 1.5, ny - node_r * 1.5, nx + node_r * 1.5, ny + node_r * 1.5],
            fill=(255, 255, 255, 60),
        )
        draw.ellipse(
            [nx - node_r, ny - node_r, nx + node_r, ny + node_r],
            fill=(255, 255, 255, 220),
        )

    # === Inner nodes (more connections) ===
    inner_node_r = size * 0.025
    inner_hx_r = hx_r * 0.4
    for i in range(6):
        angle = math.pi / 6 + i * math.pi / 3
        nx = hx_c[0] + inner_hx_r * math.cos(angle)
        ny = hx_c[1] + inner_hx_r * math.sin(angle)
        draw.ellipse(
            [nx - inner_node_r, ny - inner_node_r, nx + inner_node_r, ny + inner_node_r],
            fill=(255, 255, 255, 140),
        )

    # Central node
    center_node_r = size * 0.045
    draw.ellipse(
        [cx - center_node_r, cy - center_node_r, cx + center_node_r, cy + center_node_r],
        fill=(255, 255, 255, 180),
    )
    # Central glow
    glow_center = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gc_draw = ImageDraw.Draw(glow_center)
    gc_draw.ellipse(
        [cx - center_node_r * 2.5, cy - center_node_r * 2.5,
         cx + center_node_r * 2.5, cy + center_node_r * 2.5],
        fill=(180, 180, 255, 35),
    )
    glow_center = glow_center.filter(ImageFilter.GaussianBlur(radius=center_node_r * 1.5))
    img = Image.alpha_composite(img, glow_center)

    # === Balance scale cross (subtle, behind nodes) ===
    scale_y = cy + hx_r * 0.8
    scale_w = hx_r * 0.7
    scale_h = size * 0.06

    # Horizontal bar
    draw.rounded_rectangle(
        [cx - scale_w, scale_y - scale_h, cx + scale_w, scale_y + scale_h],
        radius=int(scale_h),
        fill=(255, 255, 255, 45),
    )

    # Vertical post
    post_w = size * 0.015
    draw.rounded_rectangle(
        [cx - post_w, scale_y, cx + post_w, size - margin],
        radius=int(post_w),
        fill=(255, 255, 255, 30),
    )

    # Scale dishes (rounded bowls)
    bowl_r = size * 0.07
    bowl_y = scale_y - bowl_r * 0.3
    for bx in [cx - scale_w * 0.85, cx + scale_w * 0.85]:
        draw.arc(
            [bx - bowl_r, bowl_y - bowl_r, bx + bowl_r, bowl_y + bowl_r],
            start=200, end=340, fill=(255, 255, 255, 70), width=3,
        )

    # === Orbiting particles for AI motion feel ===
    orbit_r = hx_r * 1.25
    particle_r = size * 0.012
    for i in range(8):
        angle = (i / 8) * 2 * math.pi + math.pi / 8
        px = cx + orbit_r * math.cos(angle)
        py = cy + orbit_r * math.sin(angle)
        draw.ellipse(
            [px - particle_r, py - particle_r, px + particle_r, py + particle_r],
            fill=(200, 200, 255, 120),
        )

    # === Fine connection lines (neural net style) ===
    for i in range(6):
        a1 = math.pi / 6 + i * math.pi / 3
        x1 = hx_c[0] + hx_r * math.cos(a1)
        y1 = hx_c[1] + hx_r * math.sin(a1)
        # Connect to neighbors (skip one)
        a2 = math.pi / 6 + ((i + 2) % 6) * math.pi / 3
        x2 = hx_c[0] + hx_r * math.cos(a2)
        y2 = hx_c[1] + hx_r * math.sin(a2)
        draw.line([(x1, y1), (x2, y2)], fill=(255, 255, 255, 35), width=2)
        # Connect to center
        draw.line([(x1, y1), (cx, cy)], fill=(255, 255, 255, 25), width=1)

    # === Apply corner radius (iOS style rounded rect) ===
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner_radius = int(size * 0.225)  # ~22.5% corner radius like iOS
    mask_draw.rounded_rectangle(
        [0, 0, size, size], radius=corner_radius, fill=255
    )
    img.putalpha(Image.composite(img.getchannel("A"), mask, mask))

    return img

def main():
    master = create_master_icon(1024)

    for name, px_size in SIZES:
        scaled = master.resize((px_size, px_size), Image.LANCZOS)
        path = os.path.join(OUTPUT_DIR, f"Icon-App-{name}.png")
        scaled.save(path, "PNG")
        print(f"  ✓ {path} ({px_size}x{px_size})")

    print(f"\n✅ Generated {len(SIZES)} icon sizes")

if __name__ == "__main__":
    main()
