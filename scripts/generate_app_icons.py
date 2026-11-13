import os
from PIL import Image, ImageDraw

def generate_icons():
    src_path = r'C:\Users\Yu\.gemini\antigravity\brain\59b3dfa7-329e-45a0-b30f-cc4a271fc0f7\daypanel_icon_flat_zen_xiaorichang_1794569943266.jpg'
    res_dir = r'd:\project\daypanel_flutter\android\app\src\main\res'
    play_icon_path = r'd:\project\daypanel_flutter\docs\release\assets\play-icon-512.png'

    src = Image.open(src_path).convert('RGBA')
    w, h = src.size

    # Background color of the card
    bg_color = (246, 243, 228, 255) # #F6F3E4

    # Extract central element by flood-filling outside the dark boundary
    from collections import deque
    visited = set()
    q = deque([(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)])
    for pt in list(q): visited.add(pt)

    while q:
        x, y = q.popleft()
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                p = src.getpixel((nx, ny))
                # Border is dark or header blue
                is_border = (p[0] < 120 and p[1] < 120 and p[2] < 120) or (p[2] > 220 and p[0] < 170)
                if not is_border:
                    visited.add((nx, ny))
                    q.append((nx, ny))

    # Create transparent foreground of the central icon
    fg = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            if (x, y) not in visited:
                fg.putpixel((x, y), src.getpixel((x, y)))

    # Get bounding box of the non-transparent foreground
    bbox = fg.getbbox()
    print('Foreground bbox:', bbox)
    fg_cropped = fg.crop(bbox)
    cw, ch = fg_cropped.size
    print('Cropped size:', cw, ch)

    # 1. Generate Google Play 512x512 icon (full-bleed square with background color)
    play_im = Image.new('RGBA', (512, 512), bg_color)
    # Scale cropped element to fit nicely in 512x512 with ~68% scale (~350px)
    target_fg_size = 350
    scale = target_fg_size / max(cw, ch)
    new_cw, new_ch = int(cw * scale), int(ch * scale)
    fg_resized = fg_cropped.resize((new_cw, new_ch), Image.Resampling.LANCZOS)
    pos_x = (512 - new_cw) // 2
    pos_y = (512 - new_ch) // 2
    play_im.paste(fg_resized, (pos_x, pos_y), fg_resized)
    os.makedirs(os.path.dirname(play_icon_path), exist_ok=True)
    play_im.convert('RGB').save(play_icon_path, 'PNG')
    print('Saved:', play_icon_path)

    # 2. Generate Adaptive Icon Foreground (ic_launcher_foreground.png)
    # Canvas is 108dp x 108dp, inner safe zone is 72dp (66.7%).
    # We scale the icon to ~58% of canvas for comfortable breathing room.
    adaptive_sizes = {
        'mipmap-mdpi': 108,
        'mipmap-hdpi': 162,
        'mipmap-xhdpi': 216,
        'mipmap-xxhdpi': 324,
        'mipmap-xxxhdpi': 432
    }

    for folder, csize in adaptive_sizes.items():
        canvas = Image.new('RGBA', (csize, csize), (0, 0, 0, 0))
        target_size = int(csize * 0.58)
        scale = target_size / max(cw, ch)
        scw, sch = int(cw * scale), int(ch * scale)
        s_fg = fg_cropped.resize((scw, sch), Image.Resampling.LANCZOS)
        px = (csize - scw) // 2
        py = (csize - sch) // 2
        canvas.paste(s_fg, (px, py), s_fg)
        
        target_dir = os.path.join(res_dir, folder)
        os.makedirs(target_dir, exist_ok=True)
        out_fg = os.path.join(target_dir, 'ic_launcher_foreground.png')
        canvas.save(out_fg, 'PNG')
        print('Saved foreground:', out_fg)

    # 3. Generate Legacy Launcher Icons (ic_launcher.png)
    legacy_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }

    for folder, lsize in legacy_sizes.items():
        # Draw full icon on squircle or full background
        lim = Image.new('RGBA', (lsize, lsize), (0, 0, 0, 0))
        draw = ImageDraw.Draw(lim)
        # Rounded squircle
        corner_r = int(lsize * 0.22)
        draw.rounded_rectangle([0, 0, lsize, lsize], radius=corner_r, fill=bg_color)
        
        target_size = int(lsize * 0.72)
        scale = target_size / max(cw, ch)
        scw, sch = int(cw * scale), int(ch * scale)
        s_fg = fg_cropped.resize((scw, sch), Image.Resampling.LANCZOS)
        px = (lsize - scw) // 2
        py = (lsize - sch) // 2
        lim.paste(s_fg, (px, py), s_fg)

        target_dir = os.path.join(res_dir, folder)
        os.makedirs(target_dir, exist_ok=True)
        out_legacy = os.path.join(target_dir, 'ic_launcher.png')
        lim.save(out_legacy, 'PNG')
        print('Saved legacy:', out_legacy)

if __name__ == '__main__':
    generate_icons()
