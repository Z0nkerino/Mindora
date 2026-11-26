#!/usr/bin/env python3
"""Generate the Mindora SVG logo and every platform's app icons.

The geometry mirrors `MindoraMark` in
packages/mindora_glass/lib/src/brand/mindora_logo.dart — keep them in sync.

Usage:  python3 tool/generate_icons.py            (writes all assets)
        python3 tool/generate_icons.py --overlay  (writes a comparison image
                                                   against the master PNG)
Requires Pillow.
"""
import json
import pathlib
import struct
import sys

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
APP = ROOT / "apps" / "mindora"

CANVAS = 2000
BAR_X = [299, 807, 1314]
BAR_W = 385
SLANT = 377  # vertical drop of the top/bottom edges across a bar
TOP_LEFT_Y = 393
VERTICAL = 836
SHARP = 52
OBTUSE = 60
ACCENT = (0xFF, 0x00, 0x51)
BLACK = (0, 0, 0)


def bar_corners(i):
    x0 = BAR_X[i]
    x1 = x0 + BAR_W
    return [
        ((x0, TOP_LEFT_Y), SHARP),
        ((x1, TOP_LEFT_Y + SLANT), OBTUSE),
        ((x1, TOP_LEFT_Y + SLANT + VERTICAL), SHARP),
        ((x0, TOP_LEFT_Y + VERTICAL), OBTUSE),
    ]


def _along(a, b, d):
    vx, vy = b[0] - a[0], b[1] - a[1]
    length = (vx * vx + vy * vy) ** 0.5
    d = min(d, length / 2)
    return (a[0] + vx / length * d, a[1] + vy / length * d)


def bar_segments(i):
    """[(start, control, end)] quadratic corners joined by straight lines."""
    pts = bar_corners(i)
    n = len(pts)
    segs = []
    for k in range(n):
        prev, cur, nxt = pts[k - 1][0], pts[k][0], pts[(k + 1) % n][0]
        r = pts[k][1]
        segs.append((_along(cur, prev, r), cur, _along(cur, nxt, r)))
    return segs


def bar_polygon(i, steps=24):
    poly = []
    for a, c, b in bar_segments(i):
        for s in range(steps + 1):
            t = s / steps
            x = (1 - t) ** 2 * a[0] + 2 * (1 - t) * t * c[0] + t * t * b[0]
            y = (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * c[1] + t * t * b[1]
            poly.append((x, y))
    return poly


def svg_path(i):
    segs = bar_segments(i)
    f = lambda p: f"{p[0]:.1f} {p[1]:.1f}"
    d = f"M{f(segs[0][0])}"
    for k, (a, c, b) in enumerate(segs):
        if k:
            d += f" L{f(a)}"
        d += f" Q{f(c)} {f(b)}"
    return d + " Z"


def write_svgs():
    paths = "".join(f'<path d="{svg_path(i)}"/>' for i in range(3))
    icon = (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {CANVAS} {CANVAS}">'
        f'<rect width="{CANVAS}" height="{CANVAS}" fill="#000"/>'
        f'<g fill="#FF0051">{paths}</g></svg>\n'
    )
    x0, y0 = BAR_X[0], TOP_LEFT_Y
    w, h = BAR_X[-1] + BAR_W - x0, SLANT + VERTICAL
    mark = (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x0} {y0} {w} {h}">'
        f'<g fill="#FF0051">{paths}</g></svg>\n'
    )
    out = ROOT / "assets" / "brand"
    (out / "mindora-icon.svg").write_text(icon)
    (out / "mindora-mark.svg").write_text(mark)


def render(size, *, background=BLACK, scale=1.0, alpha=False):
    """Render the mark. `scale` < 1 shrinks it around the centre (safe zones)."""
    ss = 4
    big = size * ss
    mode = "RGBA" if alpha else "RGB"
    bg = (0, 0, 0, 0) if alpha and background is None else (background or BLACK)
    img = Image.new(mode, (big, big), bg)
    draw = ImageDraw.Draw(img)
    k = big / CANVAS
    off = big * (1 - scale) / 2
    for i in range(3):
        poly = [(off + x * k * scale, off + y * k * scale) for x, y in bar_polygon(i)]
        draw.polygon(poly, fill=ACCENT + ((255,) if alpha else ()))
    return img.resize((size, size), Image.LANCZOS)


def overwrite_png(path, **kw):
    with Image.open(path) as im:
        w, h = im.size
    render(w, **kw).save(path, optimize=True)
    return w, h


def write_ico(path, sizes=(16, 24, 32, 48, 64, 128, 256)):
    render(256).save(path, format="ICO", sizes=[(s, s) for s in sizes])


def main():
    if "--overlay" in sys.argv:
        master = Image.open(ROOT / "assets/brand/mindora-logo-2000.png").convert("RGB")
        traced = render(2000)
        blend = Image.blend(master, traced, 0.5)
        diff = Image.new("RGB", master.size)
        mp, tp, dp = master.load(), traced.load(), diff.load()
        bad = 0
        for y in range(0, 2000, 2):
            for x in range(0, 2000, 2):
                a = mp[x, y][0] > 128
                b = tp[x, y][0] > 128
                if a != b:
                    bad += 1
                    dp[x, y] = (255, 255, 0)
        print(f"mismatched pixels (sampled): {bad} of {1000*1000} = {bad/1e4:.2f}%")
        blend.save(sys.argv[-1] if sys.argv[-1].endswith(".png") else "overlay.png")
        return

    write_svgs()
    render(1024).save(ROOT / "assets/brand/mindora-icon-1024.png", optimize=True)

    # iOS: every size in the asset catalogue, opaque.
    ios = APP / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for p in ios.glob("*.png"):
        overwrite_png(p)

    # macOS: macOS icons conventionally have padding and their own rounding.
    mac = APP / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for p in mac.glob("*.png"):
        with Image.open(p) as im:
            s = im.size[0]
        img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        inner = round(s * 0.805)
        tile = render(inner).convert("RGBA")
        mask = Image.new("L", (inner * 4, inner * 4), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, inner * 4 - 1, inner * 4 - 1], radius=round(inner * 4 * 0.225), fill=255
        )
        tile.putalpha(mask.resize((inner, inner), Image.LANCZOS))
        img.paste(tile, ((s - inner) // 2, (s - inner) // 2), tile)
        img.save(p, optimize=True)

    # Android: legacy launcher icons + adaptive icon foreground.
    res = APP / "android/app/src/main/res"
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for d, m in densities.items():
        overwrite_png(res / f"mipmap-{d}" / "ic_launcher.png")
        fg = render(round(108 * m), background=None, alpha=True, scale=0.62)
        fg.save(res / f"mipmap-{d}" / "ic_launcher_foreground.png", optimize=True)
    anydpi = res / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )
    (res / "values" / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        '    <color name="ic_launcher_background">#000000</color>\n</resources>\n'
    )

    # Web: favicon, PWA icons (maskable ones keep the mark in the safe zone).
    web = APP / "web"
    render(64).save(web / "favicon.png", optimize=True)
    for name in ["Icon-192.png", "Icon-512.png"]:
        overwrite_png(web / "icons" / name)
    for name in ["Icon-maskable-192.png", "Icon-maskable-512.png"]:
        overwrite_png(web / "icons" / name, scale=0.8)

    # Windows.
    write_ico(APP / "windows/runner/resources/app_icon.ico")
    print("Icons written.")


if __name__ == "__main__":
    main()
