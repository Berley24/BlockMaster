#!/usr/bin/env python3
"""
Gera assets PNG placeholders para o Block Master
Requer: pip install pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

ASSETS_DIR = r"C:\Users\berle\BlockMaster\assets"
UI_DIR = os.path.join(ASSETS_DIR, "ui")
SPRITES_DIR = os.path.join(ASSETS_DIR, "sprites")

os.makedirs(UI_DIR, exist_ok=True)
os.makedirs(SPRITES_DIR, exist_ok=True)

# Cores do tema
COLORS = {
    "bg_dark": (26, 26, 46),
    "bg_medium": (22, 33, 62),
    "blue": (0, 212, 255),
    "blue_dark": (0, 102, 255),
    "red": (255, 68, 68),
    "red_dark": (204, 0, 0),
    "yellow": (255, 204, 0),
    "yellow_dark": (255, 153, 0),
    "green": (102, 255, 102),
    "green_dark": (0, 204, 0),
    "purple": (230, 102, 255),
    "purple_dark": (153, 0, 204),
    "orange": (255, 153, 51),
    "orange_dark": (255, 102, 0),
    "pink": (255, 51, 153),
    "white": (255, 255, 255),
    "gold": (255, 215, 0),
    "silver": (192, 192, 192),
    "bronze": (205, 127, 50),
}

def draw_rounded_rect(draw, xy, radius, fill, outline=None, width=0):
    x1, y1, x2, y2 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)

def create_icon_base(size, bg_color=COLORS["bg_dark"]):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    margin = size // 16
    draw_rounded_rect(draw, (margin, margin, size-margin, size-margin), size//8, bg_color)
    return img, draw

def save_img(img, path):
    img.save(path, "PNG")
    print(f"[OK] {path}")

# ========== ÍCONES PRINCIPAIS ==========

# Icon 512x512 (Play Store)
img, draw = create_icon_base(512)
# Blocos decorativos
blocks = [
    (-120, -120, 80, 80, COLORS["blue"], -15),
    (40, -120, 80, 80, COLORS["red"], 10),
    (-120, 40, 80, 80, COLORS["yellow"], 5),
    (40, 40, 80, 80, COLORS["blue"], -5),
    (-80, -80, 60, 60, COLORS["red"], 0, 0.9),
    (-20, -80, 60, 60, COLORS["yellow"], 0, 0.9),
    (20, -80, 60, 60, COLORS["blue"], 0, 0.9),
    (-80, -20, 60, 60, COLORS["yellow"], 0, 0.9),
    (-20, -20, 60, 60, COLORS["blue"], 0, 0.9),
    (20, -20, 60, 60, COLORS["red"], 0, 0.9),
]
cx, cy = 256, 256
for x, y, w, h, color, rot, *alpha in blocks:
    block_img = Image.new("RGBA", (w, h), (0,0,0,0))
    bdraw = ImageDraw.Draw(block_img)
    bdraw.rounded_rectangle((0, 0, w, h), radius=w//10, fill=color)
    if alpha:
        block_img.putalpha(int(255 * alpha[0]))
    if rot:
        block_img = block_img.rotate(rot, expand=True, resample=Image.BICUBIC)
    bx = cx + x - block_img.width//2
    by = cy + y - block_img.height//2
    img.paste(block_img, (bx, by), block_img)

# Texto BLOCK MASTER
try:
    font = ImageFont.truetype("arialbd.ttf", 48)
except:
    font = ImageFont.load_default()
text = "BLOCK MASTER"
bbox = draw.textbbox((0, 0), text, font=font)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
# Gradiente no texto (simulado com múltiplas camadas)
for i, color in [(0, COLORS["blue"]), (1, COLORS["yellow"]), (2, COLORS["red"])]:
    offset = i * 2
    draw.text((cx - tw//2 + offset, 420 + offset), text, font=font, fill=color)

save_img(img, os.path.join(UI_DIR, "icon_512.png"))

# Icon 192x192 (PWA)
img192 = img.resize((192, 192), Image.LANCZOS)
save_img(img192, os.path.join(UI_DIR, "icon_192.png"))

# Icon 512x512 para Android (adaptive)
img512_android = Image.new("RGBA", (512, 512), (0,0,0,0))
draw512 = ImageDraw.Draw(img512_android)
# Background layer
draw512.rounded_rectangle((32, 32, 480, 480), radius=64, fill=COLORS["bg_dark"])
# Foreground blocks
for x, y, w, h, color, rot, *alpha in blocks:
    block_img = Image.new("RGBA", (w, h), (0,0,0,0))
    bdraw = ImageDraw.Draw(block_img)
    bdraw.rounded_rectangle((0, 0, w, h), radius=w//10, fill=color)
    if alpha:
        block_img.putalpha(int(255 * alpha[0]))
    if rot:
        block_img = block_img.rotate(rot, expand=True, resample=Image.BICUBIC)
    bx = 256 + x - block_img.width//2
    by = 256 + y - block_img.height//2
    img512_android.paste(block_img, (bx, by), block_img)
save_img(img512_android, os.path.join(UI_DIR, "icon_512_android.png"))

# Feature Graphic 1024x500
fg = Image.new("RGBA", (1024, 500), COLORS["bg_dark"])
fgdraw = ImageDraw.Draw(fg)
# Gradiente background
for y in range(500):
    ratio = y / 500
    r = int(COLORS["bg_dark"][0] * (1-ratio) + COLORS["bg_medium"][0] * ratio)
    g = int(COLORS["bg_dark"][1] * (1-ratio) + COLORS["bg_medium"][1] * ratio)
    b = int(COLORS["bg_dark"][2] * (1-ratio) + COLORS["bg_medium"][2] * ratio)
    fgdraw.line([(0, y), (1024, y)], fill=(r, g, b))

# Blocos espalhados
import random
random.seed(42)
for _ in range(30):
    x = random.randint(50, 974)
    y = random.randint(50, 450)
    w = random.randint(40, 80)
    h = random.randint(40, 80)
    color = random.choice([COLORS["blue"], COLORS["red"], COLORS["yellow"], COLORS["green"], COLORS["purple"]])
    rot = random.randint(-20, 20)
    block_img = Image.new("RGBA", (w, h), (0,0,0,0))
    bdraw = ImageDraw.Draw(block_img)
    bdraw.rounded_rectangle((0, 0, w, h), radius=w//10, fill=color)
    block_img = block_img.rotate(rot, expand=True, resample=Image.BICUBIC)
    bx = x - block_img.width//2
    by = y - block_img.height//2
    fg.paste(block_img, (bx, by), block_img)

# Título
try:
    font_big = ImageFont.truetype("arialbd.ttf", 80)
    font_small = ImageFont.truetype("arial.ttf", 32)
except:
    font_big = font_small = ImageFont.load_default()

title = "BLOCK MASTER"
bbox = fgdraw.textbbox((0, 0), title, font=font_big)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
# Sombra
fgdraw.text((512 - tw//2 + 4, 180 + 4), title, font=font_big, fill=(0,0,0,180))
# Gradiente simulado
for i, color in enumerate([COLORS["blue"], COLORS["yellow"], COLORS["red"]]):
    fgdraw.text((512 - tw//2 + i*2, 180 + i*2), title, font=font_big, fill=color)

subtitle = "Puzzle Viciante de Blocos"
bbox = fgdraw.textbbox((0, 0), subtitle, font=font_small)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
fgdraw.text((512 - tw//2, 280), subtitle, font=font_small, fill=(200, 220, 255))

# Badge
badge_text = "GRÁTIS • OFFLINE • SEM CADASTRO"
bbox = fgdraw.textbbox((0, 0), badge_text, font=font_small)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
fgdraw.rounded_rectangle((512 - tw//2 - 20, 340, 512 + tw//2 + 20, 340 + th + 20), radius=25, fill=COLORS["blue"])
fgdraw.text((512 - tw//2, 350), badge_text, font=font_small, fill=COLORS["white"])

save_img(fg, os.path.join(UI_DIR, "feature_graphic.png"))

# ========== POWER-UPS (128x128) ==========

powerups = [
    ("powerup_bomb.png", "💣", COLORS["red"], COLORS["red_dark"]),
    ("powerup_shuffle.png", "🔀", COLORS["green"], COLORS["green_dark"]),
    ("powerup_undo.png", "↩️", COLORS["blue"], COLORS["blue_dark"]),
    ("powerup_colorclear.png", "🎨", COLORS["purple"], COLORS["purple_dark"]),
]

for filename, emoji, color, color_dark in powerups:
    img, draw = create_icon_base(128, COLORS["bg_medium"])
    # Fundo do ícone
    draw.ellipse((24, 24, 104, 104), fill=color)
    # Símbolo (usando texto como placeholder)
    try:
        font = ImageFont.truetype("seguiemj.ttf", 56)
    except:
        try:
            font = ImageFont.truetype("NotoColorEmoji.ttf", 56)
        except:
            font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), emoji, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text((64 - tw//2, 64 - th//2 - 4), emoji, font=font, fill=COLORS["white"])
    # Brilho
    shine = Image.new("RGBA", (128, 128), (0,0,0,0))
    sdraw = ImageDraw.Draw(shine)
    sdraw.ellipse((24, 24, 104, 104), fill=(255,255,255,40))
    img = Image.alpha_composite(img, shine)
    save_img(img, os.path.join(UI_DIR, filename))

# ========== LIGAS (64x64) ==========

leagues = [
    ("league_0.png", "🥉", COLORS["bronze"], "Bronze"),
    ("league_1.png", "🥈", COLORS["silver"], "Prata"),
    ("league_2.png", "🥇", COLORS["gold"], "Ouro"),
    ("league_3.png", "💎", (0, 255, 200), "Platina"),
    ("league_4.png", "💠", (100, 200, 255), "Diamante"),
    ("league_5.png", "👑", (255, 100, 255), "Mestre"),
    ("league_6.png", "🏆", (255, 215, 0), "Grão-Mestre"),
]

for filename, emoji, color, name in leagues:
    img, draw = create_icon_base(64, COLORS["bg_medium"])
    # Anel da liga
    draw.ellipse((8, 8, 56, 56), outline=color, width=4)
    # Ícone
    try:
        font = ImageFont.truetype("seguiemj.ttf", 28)
    except:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), emoji, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text((32 - tw//2, 32 - th//2 - 2), emoji, font=font, fill=color)
    save_img(img, os.path.join(UI_DIR, filename))

# ========== MOEDAS ==========

# Moeda gold
coin = Image.new("RGBA", (64, 64), (0,0,0,0))
cdraw = ImageDraw.Draw(coin)
cdraw.ellipse((4, 4, 60, 60), fill=COLORS["gold"], outline=(200, 170, 0), width=2)
cdraw.ellipse((16, 16, 48, 48), fill=(255, 220, 50))
# $ ou B
try:
    font = ImageFont.truetype("arialbd.ttf", 24)
except:
    font = ImageFont.load_default()
cdraw.text((32, 32), "B", font=font, fill=(180, 140, 0), anchor="mm")
save_img(coin, os.path.join(UI_DIR, "coin.png"))

# Coração (vida)
heart = Image.new("RGBA", (64, 64), (0,0,0,0))
hdraw = ImageDraw.Draw(heart)
# Desenhar coração com path
heart_points = [
    (32, 50), (16, 34), (12, 30), (10, 26), (12, 22), (16, 18),
    (24, 10), (32, 18), (40, 10), (48, 18), (52, 22), (50, 26),
    (48, 30), (44, 34)
]
hdraw.polygon(heart_points, fill=COLORS["red"], outline=(180, 0, 0), width=2)
# Brilho
hdraw.ellipse((20, 18, 30, 28), fill=(255, 100, 100, 100))
save_img(heart, os.path.join(UI_DIR, "heart.png"))

# ========== BLOCOS DO JOGO (sprites) ==========

block_colors = [
    ("block_blue.png", COLORS["blue"], COLORS["blue_dark"]),
    ("block_red.png", COLORS["red"], COLORS["red_dark"]),
    ("block_yellow.png", COLORS["yellow"], COLORS["yellow_dark"]),
    ("block_green.png", COLORS["green"], COLORS["green_dark"]),
    ("block_purple.png", COLORS["purple"], COLORS["purple_dark"]),
    ("block_orange.png", COLORS["orange"], COLORS["orange_dark"]),
    ("block_pink.png", COLORS["pink"], (200, 0, 100)),
]

for filename, color, color_dark in block_colors:
    for size in [40, 80, 120]:
        img = Image.new("RGBA", (size, size), (0,0,0,0))
        draw = ImageDraw.Draw(img)
        radius = size // 8
        margin = size // 20
        # Sombra
        draw.rounded_rectangle((margin+2, margin+2, size-margin+2, size-margin+2), radius=radius, fill=(0,0,0,80))
        # Bloco principal
        draw.rounded_rectangle((margin, margin, size-margin, size-margin), radius=radius, fill=color)
        # Highlight topo
        draw.rounded_rectangle((margin+2, margin+2, size-margin-2, margin+size//6), radius=radius-2, fill=tuple(min(255, c+60) for c in color))
        # Brilho canto
        draw.ellipse((size//3, size//3, size//2, size//2), fill=(255,255,255,60))
        save_img(img, os.path.join(SPRITES_DIR, f"{filename.replace('.png', f'_{size}.png')}"))

# Grid background pattern
grid_bg = Image.new("RGBA", (400, 400), COLORS["bg_dark"])
gdraw = ImageDraw.Draw(grid_bg)
for x in range(0, 400, 40):
    gdraw.line([(x, 0), (x, 400)], fill=(255,255,255,10), width=1)
for y in range(0, 400, 40):
    gdraw.line([(0, y), (400, y)], fill=(255,255,255,10), width=1)
save_img(grid_bg, os.path.join(UI_DIR, "grid_pattern.png"))

print("\n[SUCCESS] Todos os assets gerados com sucesso!")
print(f"📁 UI: {UI_DIR}")
print(f"📁 Sprites: {SPRITES_DIR}")