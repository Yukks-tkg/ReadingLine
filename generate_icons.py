#!/usr/bin/env python3
"""App icon generator for Doksen"""

from PIL import Image, ImageDraw
import os

def generate_icon(size):
    # 背景を四隅まで完全に塗りつぶす（角丸なし）
    img = Image.new('RGBA', (size, size), color=(255, 248, 240, 255))  # warm cream
    draw = ImageDraw.Draw(img)

    s = size / 1024.0

    line_h    = max(1, int(28 * s))
    radius    = max(1, int(10 * s))
    spacing   = int(72 * s)
    line_w    = int(680 * s)
    start_x   = (size - line_w) // 2
    start_y   = int(160 * s)
    num_lines = 10
    hi_index  = 5  # オレンジのハイライト行

    for i in range(num_lines):
        y  = start_y + i * spacing
        w  = line_w if i < num_lines - 1 else int(line_w * 0.55)
        x0, y0, x1, y1 = start_x, y, start_x + w, y + line_h

        if i == hi_index:
            color = (220, 100, 60, 255)   # オレンジ
        else:
            color = (200, 195, 190, 255)  # グレー

        draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=color)

    return img


SIZES = [16, 32, 64, 128, 256, 512, 1024]
OUT   = "Resources/Assets.xcassets/AppIcon.appiconset"

os.makedirs(OUT, exist_ok=True)

for sz in SIZES:
    img = generate_icon(sz)
    path = os.path.join(OUT, f"icon_{sz}.png")
    img.save(path, "PNG")
    print(f"✅ {path}")

# Contents.json を上書き
contents = '''{
  "images" : [
    { "filename" : "icon_16.png",   "idiom" : "mac", "scale" : "1x", "size" : "16x16"   },
    { "filename" : "icon_32.png",   "idiom" : "mac", "scale" : "2x", "size" : "16x16"   },
    { "filename" : "icon_32.png",   "idiom" : "mac", "scale" : "1x", "size" : "32x32"   },
    { "filename" : "icon_64.png",   "idiom" : "mac", "scale" : "2x", "size" : "32x32"   },
    { "filename" : "icon_128.png",  "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_256.png",  "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256.png",  "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_512.png",  "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512.png",  "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_1024.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
'''

with open(os.path.join(OUT, "Contents.json"), "w") as f:
    f.write(contents)
print("✅ Contents.json updated")
print("\n完了！Xcodeでビルドしてください。")
