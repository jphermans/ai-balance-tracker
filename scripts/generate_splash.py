#!/usr/bin/env python3
"""Generate native launch screen image for AI Balance Tracker.

Matches the Flutter SplashScreen widget design:
  - Deep navy → royal blue → violet blue gradient
  - Tech grid overlay with dot nodes
  - Credit-card icon with purple/indigo strip + AI sparkle + balance bars
  - "AI Balance" / "Tracker" text
  - Version + JPHsystems at bottom
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

OUTPUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "assets", "splash"
)

# ── Colors (from Flutter splash_screen.dart) ──────────────────────────
GRADIENT_TOP    = (0x0A, 0x0F, 0x23)   # #0A0F23 deep navy
GRADIENT_MID    = (0x1E, 0x28, 0x5A)   # #1E285A royal blue
GRADIENT_BOTTOM = (0x32, 0x46, 0x8C)   # #32468C violet blue
GRID_LINE       = (255, 255, 255, 10)  # subtle white
GRID_DOT        = (255, 255, 255, 15)
CARD_BODY       = (240, 240, 245, 235)
CARD_SHADOW     = (0, 0, 0, 50)
STRIP_TOP       = (79, 70, 229)        # #4F46E5 indigo
STRIP_BOTTOM    = (139, 92, 246)       # #8B5CF6 violet
STAR_OUTER      = (79, 70, 229)        # #4F46E5
STAR_INNER      = (139, 92, 246, 180)
STAR_CENTER     = (255, 255, 255)
STAR_GLOW       = (99, 102, 241, 20)   # #6366F1
BAR_COLORS = [
    (79, 70, 229, 204),
    (99, 102, 241, 200),
    (165, 180, 252, 190),
]
TEXT_PRIMARY     = (255, 255, 255, 230)
TEXT_SECONDARY   = (255, 255, 255, 128)
TEXT_VERSION     = (255, 255, 255, 64)
TEXT_BRAND       = (255, 255, 255, 50)

# ── Fonts ─────────────────────────────────────────────────────────────
def _find_font(size: int) -> ImageFont.FreeTypeFont | None:
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        "/System/Library/Fonts/SF-Pro-Display-Bold.otf",
        "/System/Library/Fonts/SF-Pro-Display-Regular.otf",
    ]
    for p in candidates:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                continue
    return None


def _interp(c1, c2, t: float):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def draw_gradient(draw: ImageDraw.ImageDraw, w: int, h: int):
    """Vertical three-stop gradient."""
    for y in range(h):
        t = y / (h - 1)
        if t < 0.5:
            color = _interp(GRADIENT_TOP, GRADIENT_MID, t * 2)
        else:
            color = _interp(GRADIENT_MID, GRADIENT_BOTTOM, (t - 0.5) * 2)
        draw.line([(0, y), (w, y)], fill=color)


def draw_grid(draw: ImageDraw.ImageDraw, w: int, h: int):
    """Faint tech grid matching _GridPainter."""
    step = w / 6
    # Vertical lines
    for i in range(7):
        x = i * step
        draw.line([(x, 0), (x, h)], fill=GRID_LINE, width=1)
    # Horizontal lines
    for i in range(int(h / step) + 1):
        y = i * step
        draw.line([(0, y), (w, y)], fill=GRID_LINE, width=1)
    # Dot nodes
    dot_r = step * 0.04
    for i in range(1, 7):
        for j in range(1, int(h / step)):
            x, y = i * step, j * step
            draw.ellipse(
                [(x - dot_r, y - dot_r), (x + dot_r, y + dot_r)],
                fill=GRID_DOT
            )


def draw_card_icon(draw: ImageDraw.ImageDraw, cx: float, cy: float, s: float):
    """Draw the credit-card icon with purple strip + AI sparkle + bars.
    
    s = card width (card height ≈ s * 0.7).
    """
    cw = s
    ch = s * 0.68
    cr = cw * 0.14                     # corner radius
    x0, y0 = cx - cw / 2, cy - ch / 2
    
    # ── Shadow ──
    shadow_offset = cr * 0.5
    for step in range(6):
        alpha = int(50 * (1 - step / 6) * (1 - step / 6))
        ox = shadow_offset * (step / 5)
        oy = shadow_offset * (step / 5)
        draw.rounded_rectangle(
            [(x0 + ox, y0 + oy), (x0 + cw + ox, y0 + ch + oy)],
            radius=cr, fill=(0, 0, 0, alpha)
        )
    
    # ── Card body ──
    draw.rounded_rectangle(
        [(x0, y0), (x0 + cw, y0 + ch)],
        radius=cr, fill=CARD_BODY
    )
    
    # ── Top accent strip ──
    sh = ch * 0.30                     # strip height
    # Strip background
    draw.rounded_rectangle(
        [(x0, y0), (x0 + cw, y0 + sh + cr)],
        radius=cr, fill=STRIP_TOP
    )
    # Clip bottom of strip (square off)
    draw.rectangle(
        [(x0, y0 + sh), (x0 + cw, y0 + sh + cr)],
        fill=STRIP_TOP
    )
    # Strip gradient (vertical, over the top portion)
    for sy in range(int(sh)):
        t = sy / sh
        color = _interp(STRIP_TOP, STRIP_BOTTOM, t)
        draw.line(
            [(x0, y0 + sy), (x0 + cw, y0 + sy)],
            fill=color
        )
    
    # ── Dots on strip ──
    dot_r = sh * 0.15
    for i in range(3):
        dx = x0 + cw * 0.2 + i * cw * 0.15
        dy = y0 + sh / 2
        alpha = int(204 - i * 20)
        draw.ellipse(
            [(dx - dot_r, dy - dot_r), (dx + dot_r, dy + dot_r)],
            fill=(255, 255, 255, alpha)
        )
    
    # ── AI sparkle (4-point star) ──
    scx = cx
    scy = y0 + sh + (ch - sh) / 2
    sparkle = ch * 0.28                  # sparkle size param
    
    # Outer glow
    glow_r = sparkle * 0.7
    for gstep in range(4):
        ga = int(20 * (1 - gstep / 4) * (1 - gstep / 4))
        gsr = glow_r + gstep * glow_r * 0.5
        draw.ellipse(
            [(scx - gsr, scy - gsr), (scx + gsr, scy + gsr)],
            fill=(99, 102, 241, ga)
        )
    
    # 4-point star
    points = []
    for i in range(4):
        a = i * math.pi / 2 - math.pi / 2
        ox = scx + sparkle * math.cos(a)
        oy = scy + sparkle * math.sin(a)
        ix = scx + sparkle * 0.35 * math.cos(a + math.pi / 4)
        iy = scy + sparkle * 0.35 * math.sin(a + math.pi / 4)
        points.extend([ox, oy, ix, iy])
    draw.polygon([(points[i], points[i + 1]) for i in range(0, len(points), 2)],
                 fill=STAR_OUTER)
    
    # Inner star
    ipoints = []
    for i in range(4):
        a = i * math.pi / 2 - math.pi / 2
        ox = scx + sparkle * 0.55 * math.cos(a)
        oy = scy + sparkle * 0.55 * math.sin(a)
        ix = scx + sparkle * 0.25 * math.cos(a + math.pi / 4)
        iy = scy + sparkle * 0.25 * math.sin(a + math.pi / 4)
        ipoints.extend([ox, oy, ix, iy])
    draw.polygon([(ipoints[i], ipoints[i + 1]) for i in range(0, len(ipoints), 2)],
                 fill=STAR_INNER)
    
    # Center dot
    draw.ellipse(
        [(scx - sparkle * 0.13, scy - sparkle * 0.13),
         (scx + sparkle * 0.13, scy + sparkle * 0.13)],
        fill=STAR_CENTER
    )
    
    # ── Balance bars below sparkle ──
    bar_y0 = scy + sparkle * 0.75
    bar_full_w = cw * 0.38
    bar_x0 = scx - bar_full_w / 2
    bar_gap = sparkle * 0.26
    for i in range(3):
        bw = bar_full_w - i * bar_full_w * 0.24
        by = bar_y0 + i * bar_gap
        bh = bar_gap * 0.55
        bx = bar_x0 + (bar_full_w - bw) / 2
        draw.rounded_rectangle(
            [(bx, by), (bx + bw, by + bh)],
            radius=bh * 0.45, fill=BAR_COLORS[i]
        )


def generate(w: int = 1284, h: int = 2778, version: str = "1.0.0"):
    """Generate splash image."""
    img = Image.new("RGBA", (w, h))
    draw = ImageDraw.Draw(img)
    
    # Background gradient
    draw_gradient(draw, w, h)
    
    # Tech grid
    draw_grid(draw, w, h)
    
    # ── Card icon ──
    shortest = min(w, h)
    card_w = shortest * 0.35
    draw_card_icon(draw, w / 2, h * 0.38, card_w)
    
    # ── Text ──
    title_font = _find_font(int(shortest * 0.07)) or ImageFont.load_default()
    subtitle_font = _find_font(int(shortest * 0.045)) or ImageFont.load_default()
    version_font = _find_font(26) or ImageFont.load_default()
    brand_font = _find_font(22) or ImageFont.load_default()
    
    text_y = h * 0.38 + card_w * 0.68 / 2 + shortest * 0.06
    
    # "AI Balance"
    tbbox = draw.textbbox((0, 0), "AI Balance", font=title_font)
    tw = tbbox[2] - tbbox[0]
    draw.text(
        (w / 2 - tw / 2, text_y),
        "AI Balance", font=title_font, fill=TEXT_PRIMARY
    )
    
    # "Tracker"
    sbbox = draw.textbbox((0, 0), "Tracker", font=subtitle_font)
    sw = sbbox[2] - sbbox[0]
    draw.text(
        (w / 2 - sw / 2, text_y + shortest * 0.07 + shortest * 0.015),
        "Tracker", font=subtitle_font, fill=TEXT_SECONDARY
    )
    
    # Version
    vtext = f"v{version}"
    vbbox = draw.textbbox((0, 0), vtext, font=version_font)
    vw = vbbox[2] - vbbox[0]
    draw.text(
        (w / 2 - vw / 2, h - 140),
        vtext, font=version_font, fill=TEXT_VERSION
    )
    
    # JPHsystems
    bbox2 = draw.textbbox((0, 0), "JPHsystems", font=brand_font)
    bw2 = bbox2[2] - bbox2[0]
    draw.text(
        (w / 2 - bw2 / 2, h - 90),
        "JPHsystems", font=brand_font, fill=TEXT_BRAND
    )
    
    # Save
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    outpath = os.path.join(OUTPUT_DIR, "splash.png")
    img.save(outpath)
    
    # Also save a downsized version for Android (mdpi ~ 1x at 360×780 scale)
    android_w = 1080
    android_h = int(android_w * h / w)
    android_img = img.resize((android_w, android_h), Image.LANCZOS)
    android_path = os.path.join(OUTPUT_DIR, "splash_android.png")
    android_img.save(android_path)
    
    print(f"✓ Splash image saved to {outpath} ({w}×{h})")
    print(f"✓ Android splash saved to {android_path} ({android_w}×{android_h})")
    return outpath


if __name__ == "__main__":
    generate()
