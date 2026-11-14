import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

os.makedirs('docs/release/store_assets', exist_ok=True)

FONT_BOLD = r'C:\Windows\Fonts\segoeuib.ttf'
FONT_REGULAR = r'C:\Windows\Fonts\segoeui.ttf'

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.load_default()

# -------------------------------------------------------------
# 1. GENERATE FEATURE GRAPHIC (1024 x 500)
# -------------------------------------------------------------
def make_feature_graphic():
    W, H = 1024, 500
    bg = Image.new('RGB', (W, H), '#090d16')
    draw = ImageDraw.Draw(bg)

    # Subtle vertical gradient
    for y in range(H):
        r = int(9 + (18 - 9) * (y / H))
        g = int(13 + (26 - 13) * (y / H))
        b = int(22 + (44 - 22) * (y / H))
        draw.line([(0, y), (W, y)], fill=(r, g, b))

    # Soft ambient glows
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse([580, 40, 1020, 460], fill=(56, 189, 248, 28))
    glow_draw.ellipse([640, 100, 960, 420], fill=(139, 92, 246, 32))
    glow_draw.ellipse([80, 200, 360, 480], fill=(59, 130, 246, 16))
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    bg.paste(Image.alpha_composite(Image.new('RGBA', (W, H), (0, 0, 0, 0)), glow), (0, 0), glow)

    # App icon
    icon_path = 'docs/release/assets/play-icon-512.png'
    if os.path.exists(icon_path):
        icon = Image.open(icon_path).convert('RGBA')
        icon = icon.resize((96, 96), Image.Resampling.LANCZOS)
        mask = Image.new('L', (96, 96), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([0, 0, 96, 96], radius=22, fill=255)
        
        # Shadow for icon
        icon_shadow = Image.new('RGBA', (116, 116), (0, 0, 0, 0))
        s_draw = ImageDraw.Draw(icon_shadow)
        s_draw.rounded_rectangle([10, 10, 106, 106], radius=22, fill=(0, 0, 0, 120))
        icon_shadow = icon_shadow.filter(ImageFilter.GaussianBlur(8))
        bg.paste(Image.alpha_composite(Image.new('RGBA', (W, H), (0, 0, 0, 0)), 
                 Image.new('RGBA', (W, H), (0,0,0,0))), (0,0))
        bg.paste(icon_shadow, (70 - 10, 140 - 10), icon_shadow)
        bg.paste(icon, (70, 140), mask)

    # Texts
    f_title = get_font(FONT_BOLD, 42)
    f_sub = get_font(FONT_REGULAR, 21)
    f_badge = get_font(FONT_BOLD, 13)

    draw.text((70, 260), "DayPanel", font=f_title, fill="#ffffff")
    draw.text((70, 318), "Mindful Habits & Daily Journal", font=f_sub, fill="#94a3b8")

    # Feature badges
    badges = ["100% Offline", "Zero Ads", "Private", "One-Time Plus"]
    bx = 70
    by = 370
    for b in badges:
        bbox = draw.textbbox((0, 0), b, font=f_badge)
        bw = bbox[2] - bbox[0] + 24
        bh = 30
        
        # Pill badge with alpha
        pill = Image.new('RGBA', (bw, bh), (0, 0, 0, 0))
        p_draw = ImageDraw.Draw(pill)
        p_draw.rounded_rectangle([0, 0, bw - 1, bh - 1], radius=15, 
                                 fill=(30, 41, 59, 200), outline=(71, 85, 105, 180), width=1)
        p_draw.text((12, 6), b, font=f_badge, fill="#cbd5e1")
        bg.paste(pill, (bx, by), pill)
        bx += bw + 10

    # Phone mockup on right side using ENGLISH screenshot
    screen_src = '.local/reports/qa02-en-normal-daily.png'
    if os.path.exists(screen_src):
        screen = Image.open(screen_src).convert('RGBA')
        # Frame dimensions
        fw, fh = 246, 520
        fx, fy = 720, 60
        
        # Phone drop shadow
        phone_shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        ps_draw = ImageDraw.Draw(phone_shadow)
        ps_draw.rounded_rectangle([fx - 8, fy + 8, fx + fw + 8, fy + fh + 8], radius=32, fill=(0, 0, 0, 160))
        phone_shadow = phone_shadow.filter(ImageFilter.GaussianBlur(24))
        bg.paste(phone_shadow, (0, 0), phone_shadow)

        # Phone outer frame
        frame = Image.new('RGBA', (fw, fh), (0, 0, 0, 0))
        f_draw = ImageDraw.Draw(frame)
        f_draw.rounded_rectangle([0, 0, fw - 1, fh - 1], radius=28, fill=(15, 23, 42, 255), outline=(51, 65, 85, 255), width=3)

        # Screen inside frame
        sw, sh = fw - 16, fh - 16
        screen_resized = screen.resize((sw, sh), Image.Resampling.LANCZOS)
        
        # Screen mask with rounded corners
        s_mask = Image.new('L', (sw, sh), 0)
        sm_draw = ImageDraw.Draw(s_mask)
        sm_draw.rounded_rectangle([0, 0, sw, sh], radius=20, fill=255)
        
        frame.paste(screen_resized, (8, 8), s_mask)
        
        # Phone camera punch hole
        f_draw.ellipse([fw // 2 - 5, 14, fw // 2 + 5, 24], fill=(10, 15, 30, 255))

        bg.paste(frame, (fx, fy), frame)

    bg.save('docs/release/store_assets/feature-graphic-1024x500.png', 'PNG')
    print("Generated Feature Graphic: docs/release/store_assets/feature-graphic-1024x500.png")

# -------------------------------------------------------------
# 2. GENERATE STORE SCREENSHOTS (1080 x 1920)
# -------------------------------------------------------------
def make_screenshot(out_name, headline, subhead, src_file, bg_top, bg_bot, accent_glow):
    W, H = 1080, 1920
    im = Image.new('RGB', (W, H), bg_top)
    draw = ImageDraw.Draw(im)

    # Vertical gradient
    r1, g1, b1 = int(bg_top[1:3], 16), int(bg_top[3:5], 16), int(bg_top[5:7], 16)
    r2, g2, b2 = int(bg_bot[1:3], 16), int(bg_bot[3:5], 16), int(bg_bot[5:7], 16)
    for y in range(H):
        r = int(r1 + (r2 - r1) * (y / H))
        g = int(g1 + (g2 - g1) * (y / H))
        b = int(b1 + (b2 - b1) * (y / H))
        draw.line([(0, y), (W, y)], fill=(r, g, b))

    # Ambient subtle light in center/top
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow)
    g_draw.ellipse([W // 2 - 380, 200, W // 2 + 380, 960], fill=accent_glow)
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    im.paste(glow, (0, 0), glow)

    # Header texts
    f_head = get_font(FONT_BOLD, 56)
    f_sub = get_font(FONT_REGULAR, 30)

    # Draw headline
    h_box = draw.textbbox((0, 0), headline, font=f_head)
    hx = (W - (h_box[2] - h_box[0])) // 2
    draw.text((hx, 110), headline, font=f_head, fill="#0f172a")

    # Draw subhead
    s_box = draw.textbbox((0, 0), subhead, font=f_sub)
    sx = (W - (s_box[2] - s_box[0])) // 2
    draw.text((sx, 185), subhead, font=f_sub, fill="#64748b")

    # Draw Phone Mockup
    if os.path.exists(src_file):
        screen = Image.open(src_file).convert('RGBA')
        
        # Phone mockup dimensions
        pw, ph = 648, 1440
        px = (W - pw) // 2
        py = 280

        # Multi-layer shadow for realistic depth
        shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        s_draw = ImageDraw.Draw(shadow)
        s_draw.rounded_rectangle([px - 14, py + 14, px + pw + 14, py + ph + 14], radius=44, fill=(15, 23, 42, 70))
        shadow = shadow.filter(ImageFilter.GaussianBlur(30))
        im.paste(shadow, (0, 0), shadow)

        # Phone frame
        p_frame = Image.new('RGBA', (pw, ph), (0, 0, 0, 0))
        pf_draw = ImageDraw.Draw(p_frame)
        pf_draw.rounded_rectangle([0, 0, pw - 1, ph - 1], radius=38, 
                                  fill=(255, 255, 255, 255), outline=(226, 232, 240, 255), width=4)

        # Inner screen
        iw, ih = pw - 20, ph - 20
        screen_fitted = screen.resize((iw, ih), Image.Resampling.LANCZOS)
        
        mask = Image.new('L', (iw, ih), 0)
        m_draw = ImageDraw.Draw(mask)
        m_draw.rounded_rectangle([0, 0, iw, ih], radius=30, fill=255)

        p_frame.paste(screen_fitted, (10, 10), mask)

        # Punch hole camera
        pf_draw.ellipse([pw // 2 - 7, 20, pw // 2 + 7, 34], fill=(15, 23, 42, 220))

        im.paste(p_frame, (px, py), p_frame)

    dst_path = os.path.join('docs/release/store_assets', out_name)
    im.save(dst_path, 'PNG')
    print(f"Generated {out_name}: {im.size} {im.mode}")

if __name__ == '__main__':
    make_feature_graphic()

    # 1. Habits
    make_screenshot(
        'screenshot-1-habits.png',
        'Track Daily Habits',
        'Build lasting routines at your own rhythm',
        '.local/reports/qa02-en-normal-daily.png',
        '#f8fafc', '#e2e8f0', (56, 189, 248, 25)
    )

    # 2. Tasks
    make_screenshot(
        'screenshot-2-tasks.png',
        'Keep-Around Tasks',
        'Pressure-free to-dos that stay until completed',
        '.local/reports/qa02-en-normal-tasks.png',
        '#f8fafc', '#ede9fe', (168, 85, 247, 22)
    )

    # 3. Journal
    make_screenshot(
        'screenshot-3-journal.png',
        'Mindful Daily Journal',
        'Capture thoughts & link them to habits',
        '.local/reports/qa02-en-normal-journal.png',
        '#f8fafc', '#e0f2fe', (14, 165, 233, 22)
    )

    # 4. Statistics
    make_screenshot(
        'screenshot-4-statistics.png',
        'Visual Statistics & Trends',
        'Review progress across days, weeks, and years',
        '.local/reports/qa02-en-normal-statistics-0.png',
        '#f8fafc', '#f1f5f9', (99, 102, 241, 20)
    )

    # 5. Achievement Cards
    make_screenshot(
        'screenshot-5-cards.png',
        'Daily Achievement Cards',
        'Celebrate your mindful consistency every day',
        '.local/reports/qa02-en-normal-card-details.png',
        '#f8fafc', '#fef3c7', (245, 158, 11, 22)
    )
