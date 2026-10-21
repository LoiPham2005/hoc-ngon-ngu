"""Vẽ logo Lingua: 2 bong bóng hội thoại (A + あ) trên nền gradient Indigo."""
import sys
from PIL import Image, ImageDraw, ImageFont

OUT = sys.argv[1]
S = 4096  # vẽ to 4x rồi thu nhỏ → viền mịn
JP = ImageFont.truetype('/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc', int(S * 0.30))
LATIN = ImageFont.truetype('/System/Library/Fonts/SFNSRounded.ttf', int(S * 0.20))
LATIN.set_variation_by_axes([800]) if hasattr(LATIN, 'set_variation_by_axes') else None
BANNER = ImageFont.truetype('/System/Library/Fonts/SFNSRounded.ttf', int(S * 0.085))

INDIGO_TOP, INDIGO_BOTTOM = (124, 115, 255), (67, 56, 202)
SAKURA = (236, 72, 153)
WHITE = (255, 255, 255)
INK = (67, 56, 202)


def gradient(size):
    img = Image.new('RGB', (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            px[x, y] = tuple(int(a + (b - a) * t) for a, b in zip(INDIGO_TOP, INDIGO_BOTTOM))
    return img


def bubble(draw, box, fill, tail):
    x0, y0, x1, y1 = box
    r = (x1 - x0) * 0.28
    draw.rounded_rectangle(box, radius=r, fill=fill)
    tx, ty, direction = tail  # đuôi bong bóng
    w = (x1 - x0) * 0.16
    if direction == 'left':
        draw.polygon([(tx, ty - w), (tx + w * 1.1, ty - w), (tx - w * 0.35, ty + w * 0.9)], fill=fill)
    else:
        draw.polygon([(tx - w * 1.1, ty - w), (tx, ty - w), (tx + w * 0.35, ty + w * 0.9)], fill=fill)


def centered_text(draw, box, text, font, fill):
    x0, y0, x1, y1 = box
    l, t, r, b = draw.textbbox((0, 0), text, font=font)
    draw.text(((x0 + x1 - (r - l)) / 2 - l, (y0 + y1 - (b - t)) / 2 - t), text, font=font, fill=fill)


def foreground(draw):
    # Bong bóng sau (hồng, chữ A) — lệch phải trên.
    back = (S * 0.44, S * 0.16, S * 0.86, S * 0.56)
    bubble(draw, back, SAKURA, (S * 0.76, S * 0.56, 'right'))
    centered_text(draw, (back[0] + S * 0.06, back[1], back[2], back[3] - S * 0.03), 'A', LATIN, WHITE)
    # Bong bóng trước (trắng, chữ あ) — lệch trái dưới.
    front = (S * 0.14, S * 0.36, S * 0.62, S * 0.80)
    bubble(draw, front, WHITE, (S * 0.26, S * 0.80, 'left'))
    centered_text(draw, front, 'あ', JP, INK)


def make(variant=None):
    img = gradient(S // 8).resize((S, S), Image.BICUBIC)
    draw = ImageDraw.Draw(img)
    foreground(draw)
    if variant:  # dải nhãn DEV / STG ở đáy
        color = {'DEV': (245, 158, 11), 'STG': (16, 185, 129)}[variant]
        draw.rectangle((0, S * 0.84, S, S), fill=color)
        centered_text(draw, (0, S * 0.84, S, S), variant, BANNER, WHITE)
    return img.resize((1024, 1024), Image.LANCZOS)


make().save(f'{OUT}/prod.png')
make('DEV').save(f'{OUT}/dev.png')
make('STG').save(f'{OUT}/stg.png')
print('ok')
