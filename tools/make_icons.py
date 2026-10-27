"""Draw simple_bible's icon and installer artwork.

    python tools/make_icons.py <out_dir> [<wordmark_font> <caption_font>]

Writes into <out_dir>:
  bible_gui.ico            the program's icon (16 to 256 pixels, each size drawn for itself)
  bible_gui_256.png        the same at 256 pixels, for a look
  wizard_<scale>.bmp       the installer's left-hand picture (164x314 at 100%, and 125/150/200%)
  wizard_small_<scale>.bmp the installer's top-right picture (55x55 at 100%, and larger)
The picture: an open book on deep ink, parchment pages, a gold ribbon; small sizes drop the
detail so the shape still reads at 16 pixels. Nothing is read but the two optional fonts.
"""
import io
import math
import struct
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

INK_TOP = (44, 52, 70)
INK_BOTTOM = (18, 21, 30)
COVER = (122, 38, 48)
COVER_EDGE = (82, 24, 32)
PAGE_LIGHT = (246, 236, 207)
PAGE_SHADE = (214, 194, 146)
EDGE = (176, 148, 92)
GOLD = (214, 168, 64)
GOLD_DARK = (150, 110, 34)
LINE = (178, 160, 120)
WIZARD_BACK = (20, 23, 32)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(len(a)))


def vertical_gradient(w, h, top, bottom):
    img = Image.new('RGB', (w, h))
    px = img.load()
    for y in range(h):
        c = lerp(top, bottom, y / max(1, h - 1))
        for x in range(w):
            px[x, y] = c
    return img


def bezier(p0, p1, p2, steps=40):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1])
            for t in (i / steps for i in range(steps + 1))]


def page(side, lift, s, ox, oy):
    """One page as a polygon: side -1 left, 1 right; `lift' raises the outer corners."""
    cx = 0.5
    out = 0.5 + side * 0.36
    top_spine, bottom_spine = 0.36, 0.78
    top_out, bottom_out = 0.29 - lift, 0.72 - lift
    top = bezier((cx, top_spine), (cx + side * 0.17, top_spine - 0.07), (out, top_out))
    bottom = bezier((out, bottom_out), (cx + side * 0.17, bottom_spine - 0.07), (cx, bottom_spine))
    pts = top + bottom
    return [(ox + x * s, oy + y * s) for x, y in pts]


def draw_book(draw, s, ox=0.0, oy=0.0, detail=True):
    """The open book in a square of side `s' at (ox, oy)."""
    # The cover, a little larger than the pages, and the page block's edge below them.
    for side in (-1, 1):
        cover = [(ox + x * s, oy + y * s) for x, y in
                 bezier((0.5, 0.40), (0.5 + side * 0.18, 0.34), (0.5 + side * 0.40, 0.32)) +
                 bezier((0.5 + side * 0.40, 0.78), (0.5 + side * 0.18, 0.80), (0.5, 0.86))]
        draw.polygon(cover, fill=COVER, outline=COVER_EDGE)
    for side in (-1, 1):
        draw.polygon(page(side, -0.035, s, ox, oy), fill=EDGE)
        draw.polygon(page(side, -0.018, s, ox, oy), fill=PAGE_SHADE)
        draw.polygon(page(side, 0.0, s, ox, oy), fill=PAGE_LIGHT)
    if detail:
        # Lines of text, following the page's curve.
        for side in (-1, 1):
            for k in range(6):
                y0 = 0.43 + k * 0.05
                a = (0.5 + side * 0.06, y0 + 0.012)
                b = (0.5 + side * 0.30, y0 - 0.05)
                mid = (0.5 + side * 0.16, y0 - 0.03)
                pts = [(ox + x * s, oy + y * s) for x, y in bezier(a, mid, b, 16)]
                draw.line(pts, fill=LINE, width=max(1, int(s * 0.012)))
    # The spine's shadow and the ribbon.
    draw.line([(ox + 0.5 * s, oy + 0.36 * s), (ox + 0.5 * s, oy + 0.78 * s)], fill=PAGE_SHADE, width=max(1, int(s * 0.012)))
    rw = 0.045
    ribbon = [(0.5 + 0.012, 0.36), (0.5 + 0.012 + rw, 0.36), (0.5 + 0.012 + rw, 0.93),
              (0.5 + 0.012 + rw / 2, 0.895), (0.5 + 0.012, 0.93)]
    draw.polygon([(ox + x * s, oy + y * s) for x, y in ribbon], fill=GOLD, outline=GOLD_DARK)


def icon(size):
    """The icon at `size' pixels, drawn at four times and reduced."""
    k = 4
    S = size * k
    bg = vertical_gradient(S, S, INK_TOP, INK_BOTTOM).convert('RGBA')
    mask = Image.new('L', (S, S), 0)
    radius = int(S * (0.18 if size >= 32 else 0.12))
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=radius, fill=255)
    art = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    art.paste(bg, (0, 0), mask)
    if size >= 48:
        glow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(glow).ellipse([S * 0.18, S * 0.12, S * 0.82, S * 0.62], fill=(232, 196, 110, 70))
        glow = glow.filter(ImageFilter.GaussianBlur(S * 0.08))
        art = Image.alpha_composite(art, Image.composite(glow, Image.new('RGBA', (S, S), (0, 0, 0, 0)), mask))
    d = ImageDraw.Draw(art)
    # Small sizes: a larger book filling more of the square.
    scale, off = (0.98, 0.01) if size <= 24 else (0.92, 0.04)
    draw_book(d, S * scale, S * off, S * (off - 0.02), detail=size >= 48)
    if size >= 32:
        d.rounded_rectangle([1, 1, S - 2, S - 2], radius=radius, outline=(214, 168, 64, 90), width=max(1, k))
    return art.resize((size, size), Image.LANCZOS)


def write_ico(path, images):
    """An .ico holding each image as PNG (Windows Vista and later read every size so)."""
    blobs = []
    for im in images:
        b = io.BytesIO()
        im.save(b, 'PNG')
        blobs.append(b.getvalue())
    head = struct.pack('<HHH', 0, 1, len(images))
    offset = 6 + 16 * len(images)
    entries = b''
    for im, blob in zip(images, blobs):
        w, h = im.size
        entries += struct.pack('<BBBBHHII', w % 256, h % 256, 0, 0, 1, 32, len(blob), offset)
        offset += len(blob)
    with open(path, 'wb') as f:
        f.write(head + entries + b''.join(blobs))


def wizard(w, h, wordmark_font, caption_font):
    """The installer's tall picture: glow, the book, the name."""
    k = 3
    W, H = w * k, h * k
    img = vertical_gradient(W, H, (14, 16, 23), (30, 36, 52)).convert('RGBA')
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([W * -0.2, H * 0.18, W * 1.2, H * 0.62], fill=(232, 196, 110, 80))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(W * 0.16)))
    # Faint rays from the book.
    rays = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rays)
    cx, cy = W * 0.5, H * 0.47
    for i in range(-5, 6):
        a = math.radians(-90 + i * 13)
        rd.polygon([(cx, cy), (cx + math.cos(a - 0.04) * H, cy + math.sin(a - 0.04) * H),
                    (cx + math.cos(a + 0.04) * H, cy + math.sin(a + 0.04) * H)], fill=(240, 214, 150, 18))
    img = Image.alpha_composite(img, rays.filter(ImageFilter.GaussianBlur(W * 0.02)))
    d = ImageDraw.Draw(img)
    s = W * 0.86
    draw_book(d, s, (W - s) / 2, H * 0.47 - s * 0.58, detail=True)
    if wordmark_font:
        f = ImageFont.truetype(wordmark_font, int(W * 0.128))
        text = 'simple_bible'
        tw = d.textlength(text, font=f)
        d.text(((W - tw) / 2, H * 0.715), text, font=f, fill=(244, 234, 210))
    if caption_font:
        f2 = ImageFont.truetype(caption_font, int(W * 0.058))
        cap = 'PERSONAL EDITION'
        tw = d.textlength(cap, font=f2) + len(cap) * W * 0.004
        x = (W - tw) / 2
        for ch in cap:
            d.text((x, H * 0.715 + W * 0.185), ch, font=f2, fill=GOLD)
            x += d.textlength(ch, font=f2) + W * 0.004
    return img.convert('RGB').resize((w, h), Image.LANCZOS)


def small_wizard(size):
    im = icon(size)
    back = Image.new('RGBA', im.size, WIZARD_BACK + (255,))
    return Image.alpha_composite(back, im).convert('RGB')


def main():
    out = sys.argv[1].rstrip('/\\')
    word = sys.argv[2] if len(sys.argv) > 2 else None
    cap = sys.argv[3] if len(sys.argv) > 3 else None
    sizes = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256]
    images = [icon(n) for n in sizes]
    write_ico(out + '/bible_gui.ico', images)
    images[-1].save(out + '/bible_gui_256.png')
    for pct, (w, h), sq in [(100, (164, 314), 55), (125, (205, 393), 69), (150, (246, 471), 83), (200, (328, 628), 110)]:
        wizard(w, h, word, cap).save(out + '/wizard_%d.bmp' % pct)
        small_wizard(sq).save(out + '/wizard_small_%d.bmp' % pct)
    print('written to', out)


if __name__ == '__main__':
    main()
