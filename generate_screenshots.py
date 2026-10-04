#!/usr/bin/env python3
"""
Gera screenshots mockups para Play Store (1080x1920 - portrait)
Requer: pip install pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

SCREENSHOTS_DIR = r"C:\Users\berle\BlockMaster\assets\screenshots"
os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

# Resolução padrão Play Store (phone portrait)
W, H = 1080, 1920

COLORS = {
    "bg_dark": (26, 26, 46),
    "bg_medium": (22, 33, 62),
    "blue": (0, 212, 255),
    "blue_dark": (0, 102, 255),
    "red": (255, 68, 68),
    "yellow": (255, 204, 0),
    "green": (102, 255, 102),
    "purple": (230, 102, 255),
    "orange": (255, 153, 51),
    "white": (255, 255, 255),
    "gold": (255, 215, 0),
    "silver": (192, 192, 192),
    "bronze": (205, 127, 50),
}

def draw_rounded_rect(draw, xy, radius, fill, outline=None, width=0):
    x1, y1, x2, y2 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)

def create_base_image():
    img = Image.new("RGBA", (W, H), COLORS["bg_dark"])
    draw = ImageDraw.Draw(img)
    
    # Gradiente sutil
    for y in range(H):
        ratio = y / H
        r = int(COLORS["bg_dark"][0] * (1-ratio) + COLORS["bg_medium"][0] * ratio)
        g = int(COLORS["bg_dark"][1] * (1-ratio) + COLORS["bg_medium"][1] * ratio)
        b = int(COLORS["bg_dark"][2] * (1-ratio) + COLORS["bg_medium"][2] * ratio)
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    
    # Pattern de grade sutil
    for x in range(0, W, 80):
        draw.line([(x, 0), (x, H)], fill=(255,255,255,8), width=1)
    for y in range(0, H, 80):
        draw.line([(0, y), (W, y)], fill=(255,255,255,8), width=1)
    
    return img, draw

def load_font(size, bold=False):
    try:
        if bold:
            return ImageFont.truetype("arialbd.ttf", size)
        return ImageFont.truetype("arial.ttf", size)
    except:
        return ImageFont.load_default()

def draw_text_with_outline(draw, pos, text, font, fill, outline_fill=(0,0,0,180), outline_width=3, center=False):
    x, y = pos
    if center:
        bbox = draw.textbbox((0, 0), text, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        x -= tw // 2
        y -= th // 2
    # Desenhar outline
    for dx in [-outline_width, 0, outline_width]:
        for dy in [-outline_width, 0, outline_width]:
            if dx != 0 or dy != 0:
                draw.text((x+dx, y+dy), text, font=font, fill=outline_fill)
    # Texto principal
    draw.text((x, y), text, font=font, fill=fill)

# ========== SCREENSHOT 1: GAMEPLAY ==========
img, draw = create_base_image()

# Top bar
draw.rounded_rectangle((40, 60, W-40, 180), radius=20, fill=(20, 20, 35, 220))
# Score
font_big = load_font(72, True)
draw_text_with_outline(draw, (W//2, 100), "12,450", font_big, COLORS["white"], center=True)
# Best
font_small = load_font(28)
draw_text_with_outline(draw, (W//2, 160), "Best: 48,200", font_small, COLORS["gold"], center=True)

# Grid area (central)
grid_size = 10
cell_size = 72
grid_w = grid_size * cell_size
grid_h = grid_size * cell_size
grid_x = (W - grid_w) // 2
grid_y = 280

# Desenhar grid
for gx in range(grid_size):
    for gy in range(grid_size):
        x = grid_x + gx * cell_size
        y = grid_y + gy * cell_size
        color = (30, 30, 50)
        draw.rounded_rectangle((x+4, y+4, x+cell_size-4, y+cell_size-4), radius=8, fill=color)
        # Algumas células preenchidas (simular jogo em andamento)
        import random
        random.seed(gx * 100 + gy)
        if random.random() < 0.35:
            colors = [COLORS["blue"], COLORS["red"], COLORS["yellow"], COLORS["green"], COLORS["purple"]]
            fill_color = random.choice(colors)
            draw.rounded_rectangle((x+8, y+8, x+cell_size-8, y+cell_size-8), radius=6, fill=fill_color)

# Next blocks preview
preview_y = grid_y + grid_h + 40
draw_text_with_outline(draw, (W//2, preview_y - 50), "PRÓXIMOS", load_font(24, True), COLORS["white"], center=True)

for i in range(3):
    px = W//2 - 200 + i * 200
    py = preview_y
    draw.rounded_rectangle((px-80, py-80, px+80, py+80), radius=16, fill=(20, 20, 35, 220))
    # Blocos de preview
    shapes = [
        [(0,0), (1,0), (2,0)],  # linha 3
        [(0,0), (0,1), (1,1)],  # L
        [(0,0), (1,0), (1,1)],  # L invertido
    ]
    shape = shapes[i]
    colors = [COLORS["blue"], COLORS["red"], COLORS["yellow"]]
    block_size = 36
    for sx, sy in shape:
        bx = px - 40 + sx * block_size
        by = py - 40 + sy * block_size
        draw.rounded_rectangle((bx, by, bx+block_size-4, by+block_size-4), radius=6, fill=colors[i])

# Power-ups bottom
pu_y = H - 200
powers = [
    ("💣", "Bomba", COLORS["red"]),
    ("🔀", "Embaralhar", COLORS["green"]),
    ("↩️", "Desfazer", COLORS["blue"]),
    ("🎨", "Limpar Cor", COLORS["purple"]),
]
for i, (icon, name, color) in enumerate(powers):
    px = 120 + i * 240
    draw.rounded_rectangle((px-80, pu_y-80, px+80, pu_y+80), radius=20, fill=(20, 20, 35, 220))
    draw.rounded_rectangle((px-80, pu_y-80, px+80, pu_y+80), radius=20, outline=color, width=3)
    font_icon = load_font(48)
    draw_text_with_outline(draw, (px, pu_y-10), icon, font_icon, COLORS["white"], center=True)
    font_name = load_font(20, True)
    draw_text_with_outline(draw, (px, pu_y+50), name, font_name, COLORS["white"], center=True)

# Coins/Lives top right
draw.rounded_rectangle((W-280, 60, W-40, 180), radius=20, fill=(20, 20, 35, 220))
font_coin = load_font(36, True)
draw_text_with_outline(draw, (W-160, 120), "2,450", font_coin, COLORS["gold"], center=True)
# Moeda icon
draw.ellipse((W-100, 95, W-60, 135), fill=COLORS["gold"], outline=(200,170,0), width=2)

img.save(os.path.join(SCREENSHOTS_DIR, "screenshot_01_gameplay.png"))
print("[OK] screenshot_01_gameplay.png")

# ========== SCREENSHOT 2: SHOP ==========
img, draw = create_base_image()

# Header
draw.rounded_rectangle((40, 60, W-40, 200), radius=20, fill=(20, 20, 35, 220))
font_title = load_font(56, True)
draw_text_with_outline(draw, (W//2, 130), "🏪 LOJA", font_title, COLORS["gold"], center=True)

# Tabs
tab_y = 240
tabs = ["💰 MOEDAS", "🚫 SEM ANÚNCIOS", "⚡ POWER-UPS", "❤️ VIDAS"]
tab_w = (W - 80) // 4
for i, tab in enumerate(tabs):
    x = 40 + i * tab_w
    selected = i == 0
    draw.rounded_rectangle((x, tab_y, x+tab_w, tab_y+80), radius=12, 
                          fill=COLORS["blue"] if selected else (30, 30, 50, 180))
    font_tab = load_font(22, True)
    draw_text_with_outline(draw, (x + tab_w//2, tab_y+40), tab, font_tab, COLORS["white"], center=True)

# Coin packs
packs = [
    ("100 Moedas", "R$ 4,99", "Iniciante", False, COLORS["blue"]),
    ("550 Moedas", "R$ 19,99", "+10% BÔNUS ⭐", True, COLORS["gold"]),
    ("1.400 Moedas", "R$ 44,99", "+16% BÔNUS", False, COLORS["purple"]),
    ("3.000 Moedas", "R$ 89,99", "+20% BÔNUS", False, COLORS["orange"]),
]

start_y = 360
for i, (name, price, badge, popular, color) in enumerate(packs):
    x = 60 if i % 2 == 0 else W//2 + 20
    y = start_y + (i // 2) * 380
    card_w = W//2 - 80
    card_h = 340
    
    # Card background
    draw.rounded_rectangle((x, y, x+card_w, y+card_h), radius=20, fill=(20, 20, 35, 230))
    if popular:
        draw.rounded_rectangle((x, y, x+card_w, y+card_h), radius=20, outline=COLORS["gold"], width=4)
        # Badge popular
        font_badge = load_font(18, True)
        draw.rounded_rectangle((x+card_w-140, y-15, x+card_w-10, y+25), radius=12, fill=COLORS["gold"])
        draw_text_with_outline(draw, (x+card_w-75, y+5), "⭐ MAIS POPULAR", font_badge, (20,20,20), center=True)
    
    # Icon
    draw.ellipse((x+card_w//2-60, y+40, x+card_w//2+60, y+160), fill=color)
    draw.ellipse((x+card_w//2-40, y+60, x+card_w//2+40, y+140), fill=(255,255,255,50))
    font_coin_big = load_font(48, True)
    draw_text_with_outline(draw, (x+card_w//2, y+100), "💰", font_coin_big, COLORS["white"], center=True)
    
    # Name
    font_name = load_font(28, True)
    draw_text_with_outline(draw, (x+card_w//2, y+190), name, font_name, COLORS["white"], center=True)
    
    # Badge
    if badge:
        font_badge = load_font(18)
        draw.rounded_rectangle((x+card_w//2-80, y+230, x+card_w//2+80, y+260), radius=10, fill=color)
        draw_text_with_outline(draw, (x+card_w//2, y+245), badge, font_badge, COLORS["white"], center=True)
    
    # Price
    font_price = load_font(36, True)
    draw_text_with_outline(draw, (x+card_w//2, y+300), price, font_price, COLORS["gold"], center=True)

img.save(os.path.join(SCREENSHOTS_DIR, "screenshot_02_shop.png"))
print("[OK] screenshot_02_shop.png")

# ========== SCREENSHOT 3: LEADERBOARD ==========
img, draw = create_base_image()

# Header
draw.rounded_rectangle((40, 60, W-40, 200), radius=20, fill=(20, 20, 35, 220))
font_title = load_font(56, True)
draw_text_with_outline(draw, (W//2, 130), "🏆 LIGAS & RANKING", font_title, COLORS["gold"], center=True)

# Tabs
tabs = ["🌍 GLOBAL", "📅 SEMANAL", "☀️ DIÁRIO", "👥 AMIGOS"]
for i, tab in enumerate(tabs):
    x = 40 + i * tab_w
    selected = i == 0
    draw.rounded_rectangle((x, tab_y, x+tab_w, tab_y+80), radius=12, 
                          fill=COLORS["gold"] if selected else (30, 30, 50, 180))
    font_tab = load_font(22, True)
    draw_text_with_outline(draw, (x + tab_w//2, tab_y+40), tab, font_tab, COLORS["white"] if selected else (200,200,200), center=True)

# Player card
player_y = 360
draw.rounded_rectangle((60, player_y, W-60, player_y+200), radius=20, fill=(0, 80, 150, 100))
draw.rounded_rectangle((60, player_y, W-60, player_y+200), radius=20, outline=COLORS["blue"], width=3)

# Avatar
draw.ellipse((100, player_y+30, 220, player_y+150), fill=COLORS["blue"])
draw_text_with_outline(draw, (160, player_y+90), "👤", load_font(56), COLORS["white"], center=True)

# Player info
font_name = load_font(36, True)
draw_text_with_outline(draw, (260, player_y+50), "Você", font_name, COLORS["white"])
font_score = load_font(28)
draw_text_with_outline(draw, (260, player_y+100), "Pontuação: 48,200", font_score, COLORS["gold"])
font_rank = load_font(24)
draw_text_with_outline(draw, (260, player_y+140), "Rank: #1.234  •  Liga: 🥇 Ouro", font_rank, COLORS["green"])

# League progress
draw.rounded_rectangle((260, player_y+170, W-100, player_y+195), radius=12, fill=(0,0,0,100))
draw.rounded_rectangle((260, player_y+170, 260+int((W-360)*0.65), player_y+195), radius=12, fill=COLORS["gold"])
draw_text_with_outline(draw, (W//2, player_y+182), "65% para Prata", load_font(18), COLORS["white"], center=True)

# Leaderboard entries
entries = [
    ("#1", "ProPlayer_BR", "1,250,000", COLORS["gold"]),
    ("#2", "BlockMaster99", "980,500", COLORS["silver"]),
    ("#3", "PuzzleKing", "875,200", COLORS["bronze"]),
    ("#4", "ComboQueen", "720,100", COLORS["white"]),
    ("#5", "TetrisGod", "650,000", COLORS["white"]),
    ("#6", "BlockBreaker", "590,300", COLORS["white"]),
    ("#7", "LineClear", "520,800", COLORS["white"]),
    ("#8", "MasterMind", "480,150", COLORS["white"]),
]

entry_y = player_y + 230
for i, (rank, name, score, color) in enumerate(entries):
    y = entry_y + i * 100
    is_me = i == 0
    draw.rounded_rectangle((60, y, W-60, y+90), radius=15, 
                          fill=(0, 100, 200, 50) if is_me else (20, 20, 35, 200))
    if is_me:
        draw.rounded_rectangle((60, y, W-60, y+90), radius=15, outline=COLORS["blue"], width=2)
    
    # Rank
    font_rank = load_font(32, True)
    draw_text_with_outline(draw, (120, y+45), rank, font_rank, color, center=True)
    
    # Name
    font_name = load_font(28, True)
    draw_text_with_outline(draw, (220, y+45), name, font_name, COLORS["white" if not is_me else "gold"], center=True)
    
    # Score
    font_score = load_font(26)
    draw_text_with_outline(draw, (W-100, y+45), score, font_score, COLORS["gold"], center=True)

img.save(os.path.join(SCREENSHOTS_DIR, "screenshot_03_leaderboard.png"))
print("[OK] screenshot_03_leaderboard.png")

# ========== SCREENSHOT 4: DAILY REWARD ==========
img, draw = create_base_image()

# Header
draw.rounded_rectangle((40, 60, W-40, 200), radius=20, fill=(20, 20, 35, 220))
font_title = load_font(56, True)
draw_text_with_outline(draw, (W//2, 130), "🎁 RECOMPENSA DIÁRIA", font_title, COLORS["gold"], center=True)

# Main card
card_y = 280
card_h = 600
draw.rounded_rectangle((60, card_y, W-60, card_y+card_h), radius=30, fill=(20, 20, 35, 240))
draw.rounded_rectangle((60, card_y, W-60, card_y+card_h), radius=30, outline=COLORS["gold"], width=4)

# Streak
font_streak = load_font(36, True)
draw_text_with_outline(draw, (W//2, card_y+80), "🔥 Sequência: 7 dias!", font_streak, COLORS["orange"], center=True)

# Rewards
rewards = [
    ("💰", "350 Moedas", COLORS["gold"]),
    ("❤️", "2 Vidas Extras", COLORS["red"]),
    ("💣", "1 Power-up Bomba", COLORS["purple"]),
]
for i, (icon, text_r, color) in enumerate(rewards):
    y = card_y + 180 + i * 140
    draw.rounded_rectangle((120, y, W-120, y+110), radius=20, fill=(30, 30, 50, 200))
    draw.rounded_rectangle((120, y, W-120, y+110), radius=20, outline=color, width=2)
    
    font_icon = load_font(56)
    draw_text_with_outline(draw, (180, y+55), icon, font_icon, color, center=True)
    
    font_reward = load_font(32, True)
    draw_text_with_outline(draw, (300, y+55), text_r, font_reward, COLORS["white"], center=True)

# Claim button
btn_y = card_y + card_h + 40
draw.rounded_rectangle((W//2-200, btn_y, W//2+200, btn_y+100), radius=30, fill=COLORS["gold"])
draw_text_with_outline(draw, (W//2, btn_y+50), "RESGATAR AGORA", load_font(36, True), (20,20,20), center=True)

# Calendar preview
cal_y = btn_y + 140
draw_text_with_outline(draw, (W//2, cal_y), "📅 Próximas recompensas:", load_font(24, True), COLORS["white"], center=True)

days = ["Dia 8: 400 💰", "Dia 14: 500 💰 + ⚡", "Dia 21: 600 💰 + ❤️", "Dia 30: 1000 💰 + 👑"]
for i, day in enumerate(days):
    x = 100 + i * 240
    y = cal_y + 50
    draw.rounded_rectangle((x, y, x+220, y+80), radius=15, fill=(30, 30, 50, 200))
    draw_text_with_outline(draw, (x+110, y+40), day, load_font(20), COLORS["white"], center=True)

img.save(os.path.join(SCREENSHOTS_DIR, "screenshot_04_daily.png"))
print("[OK] screenshot_04_daily.png")

# ========== SCREENSHOT 5: SETTINGS / NO ADS ==========
img, draw = create_base_image()

# Header
draw.rounded_rectangle((40, 60, W-40, 200), radius=20, fill=(20, 20, 35, 220))
font_title = load_font(56, True)
draw_text_with_outline(draw, (W//2, 130), "⚙️ CONFIGURAÇÕES", font_title, COLORS["blue"], center=True)

# No Ads section
ads_y = 260
draw.rounded_rectangle((60, ads_y, W-60, ads_y+300), radius=20, fill=(20, 20, 35, 240))
draw.rounded_rectangle((60, ads_y, W-60, ads_y+300), radius=20, outline=COLORS["green"], width=3)

font_ads = load_font(40, True)
draw_text_with_outline(draw, (W//2, ads_y+60), "🚫 REMOVER ANÚNCIOS", font_ads, COLORS["green"], center=True)

options = [
    ("VITALÍCIO", "R$ 9,99", "Pague uma vez, nunca mais veja anúncios", COLORS["gold"], True),
    ("MENSAL", "R$ 14,99/mês", "Assinatura cancelável a qualquer momento", COLORS["blue"], False),
]

for i, (name, price, desc, color, popular) in enumerate(options):
    y = ads_y + 120 + i * 130
    x = 100 if i == 0 else W//2 + 20
    w = W//2 - 110
    
    draw.rounded_rectangle((x, y, x+w, y+110), radius=15, fill=(30, 30, 50, 220))
    if popular:
        draw.rounded_rectangle((x, y, x+w, y+110), radius=15, outline=COLORS["gold"], width=3)
        draw.rounded_rectangle((x+w-100, y-15, x+w-10, y+25), radius=12, fill=COLORS["gold"])
        draw_text_with_outline(draw, (x+w-55, y+5), "MELHOR", load_font(16, True), (20,20,20), center=True)
    
    draw_text_with_outline(draw, (x+w//2, y+35), name, load_font(28, True), color, center=True)
    draw_text_with_outline(draw, (x+w//2, y+70), price, load_font(32, True), COLORS["white"], center=True)
    draw_text_with_outline(draw, (x+w//2, y+100), desc, load_font(18), (180,180,190), center=True)

# Audio section
audio_y = ads_y + 350
draw_text_with_outline(draw, (100, audio_y), "🔊 ÁUDIO", load_font(32, True), COLORS["white"])

# Sliders
sliders = [("Música", 0.7), ("Efeitos", 0.9)]
for i, (label, val) in enumerate(sliders):
    y = audio_y + 60 + i * 90
    draw_text_with_outline(draw, (100, y+20), label, load_font(24), COLORS["white"])
    # Slider track
    draw.rounded_rectangle((280, y+10, W-100, y+50), radius=20, fill=(50,50,70))
    # Slider fill
    fill_w = int((W - 380) * val)
    draw.rounded_rectangle((280, y+10, 280+fill_w, y+50), radius=20, fill=COLORS["blue"])
    # Thumb
    draw.ellipse((280+fill_w-20, y, 280+fill_w+20, y+60), fill=COLORS["white"])
    draw_text_with_outline(draw, (W-80, y+20), f"{int(val*100)}%", load_font(22), COLORS["white"], center=True)

# Other toggles
toggles_y = audio_y + 250
toggles = ["📳 Vibração", "💾 Salvamento automático", "👻 Fantasma (preview)", "🔔 Notificação diária", "🔔 Torneio semanal"]
for i, toggle in enumerate(toggles):
    y = toggles_y + i * 65
    draw.rounded_rectangle((80, y, W-80, y+55), radius=12, fill=(30, 30, 50, 200))
    draw_text_with_outline(draw, (120, y+27), toggle, load_font(22), COLORS["white"], center=True)
    # Toggle switch
    draw.rounded_rectangle((W-140, y+10, W-60, y+45), radius=18, fill=COLORS["green"])
    draw.ellipse((W-75, y+5, W-45, y+50), fill=COLORS["white"])

# Legal links
legal_y = H - 180
draw_text_with_outline(draw, (W//2, legal_y), "📄 Política de Privacidade    📋 Termos de Uso", load_font(18), (120,120,140), center=True)
draw_text_with_outline(draw, (W//2, legal_y+30), "Block Master v1.0.0  •  © 2026", load_font(16), (100,100,120), center=True)

img.save(os.path.join(SCREENSHOTS_DIR, "screenshot_05_settings.png"))
print("[OK] screenshot_05_settings.png")

print(f"\n[SUCCESS] 5 screenshots gerados em {SCREENSHOTS_DIR}/")
print("Resolucao: 1080x1920 (portrait) - pronto para Play Store")