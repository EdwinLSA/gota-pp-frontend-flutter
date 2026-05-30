"""
Genera las 4 imagenes (paneles) del home de la app de ahorro de agua.
Estilo: ilustracion plana (flat), alegre pero no infantil, a juego con la paleta:
  - beige de fondo: #E6E2DC
  - slate oscuro:   #2F3D52
Los DOS cerros son identicos en las 4 imagenes; solo cambia el clima.
Se dibuja a 2x (supersampling) y se reduce para tener bordes suaves.
"""

from PIL import Image, ImageDraw
import os

# --- escala y lienzo ---------------------------------------------------------
S = 2                      # factor de supersampling
W, H = 1080 * S, 1280 * S  # lienzo de trabajo (vertical, se recorta con cover)

# --- paleta ------------------------------------------------------------------
BEIGE      = (230, 226, 220)   # #E6E2DC  fondo general de la app
SLATE      = (47, 61, 82)      # #2F3D52  color de botones / acentos
HILL_BACK  = (203, 176, 137)   # cerro trasero (arena/ocre)
HILL_FRONT = (138, 154, 116)   # cerro frontal (verde salvia)
HILL_FRONT_DK = (120, 135, 100)
CACTUS     = (96, 122, 92)
SUN        = (243, 184, 75)
SUN_HALO   = (248, 214, 150)
CLOUD      = (159, 176, 190)
CLOUD_DK   = (132, 150, 166)
RAIN       = (91, 112, 137)
SWEAT      = (150, 200, 214)

GROUND_Y = int(H * 0.60)   # linea base donde "nacen" los cerros


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def sky(draw, top, bottom):
    """Cielo con degradado vertical de 'top' a 'bottom'."""
    for y in range(H):
        t = y / H
        draw.line([(0, y), (W, y)], fill=lerp(top, bottom, t))


def hills(draw):
    """Los mismos dos cerros redondeados para TODOS los paneles."""
    # cerro trasero (mas claro, mas alto a la izquierda)
    draw.ellipse([-260 * S, 250 * S, 760 * S, 1700 * S], fill=HILL_BACK)
    draw.ellipse([560 * S, 300 * S, 1340 * S, 1700 * S], fill=HILL_BACK)
    # piso del cerro frontal
    draw.rectangle([0, GROUND_Y, W, H], fill=HILL_FRONT)
    # cerro frontal (dos lomas)
    draw.ellipse([-340 * S, 360 * S, 720 * S, 1500 * S], fill=HILL_FRONT)
    draw.ellipse([460 * S, 300 * S, 1420 * S, 1500 * S], fill=HILL_FRONT)
    # cactus simpatico sobre el cerro frontal (toque arido del norte)
    cx = 300 * S
    draw.rounded_rectangle([cx - 14 * S, GROUND_Y - 150 * S, cx + 14 * S, GROUND_Y - 10 * S],
                           radius=14 * S, fill=CACTUS)
    draw.rounded_rectangle([cx - 60 * S, GROUND_Y - 110 * S, cx - 32 * S, GROUND_Y - 60 * S],
                           radius=14 * S, fill=CACTUS)
    draw.rounded_rectangle([cx - 60 * S, GROUND_Y - 110 * S, cx - 32 * S, GROUND_Y - 95 * S],
                           radius=14 * S, fill=CACTUS)
    draw.rounded_rectangle([cx + 32 * S, GROUND_Y - 130 * S, cx + 60 * S, GROUND_Y - 80 * S],
                           radius=14 * S, fill=CACTUS)


def birds(draw, x, y):
    """Tres pajaritos en 'V' para alegrar el cielo."""
    for dx in (0, 90 * S, 175 * S):
        bx, by = x + dx, y + (15 * S if dx == 90 * S else 0)
        draw.arc([bx, by, bx + 55 * S, by + 40 * S], 200, 340, fill=SLATE, width=4 * S)
        draw.arc([bx + 45 * S, by, bx + 100 * S, by + 40 * S], 200, 340, fill=SLATE, width=4 * S)


def fade_bottom(img):
    """Funde el borde inferior hacia el beige para unir con la zona de botones."""
    fade = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fade)
    start = int(H * 0.80)
    for y in range(start, H):
        t = (y - start) / (H - start)
        a = int(255 * t)
        fd.line([(0, y), (W, y)], fill=BEIGE + (a,))
    return Image.alpha_composite(img.convert("RGBA"), fade)


def base_canvas(sky_top, sky_bottom):
    img = Image.new("RGB", (W, H), BEIGE)
    d = ImageDraw.Draw(img)
    sky(d, sky_top, sky_bottom)
    hills(d)
    return img, d


def panel_normal():
    img, d = base_canvas((206, 224, 226), BEIGE)   # cielo calmado pale teal
    birds(d, 690 * S, 240 * S)
    return img


def panel_calor():
    img, d = base_canvas((247, 221, 170), (245, 230, 205))  # cielo calido
    # sol a lo lejos detras de los cerros
    sx, sy, r = 850 * S, 360 * S, 95 * S
    d.ellipse([sx - r - 26 * S, sy - r - 26 * S, sx + r + 26 * S, sy + r + 26 * S], fill=SUN_HALO)
    d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=SUN)
    # gotitas de "sudor" sobre el cerro frontal
    for (gx, gy) in [(250, 770), (520, 700), (760, 780), (980, 720)]:
        x, y = gx * S, gy * S
        d.ellipse([x - 14 * S, y - 14 * S, x + 14 * S, y + 22 * S], fill=SWEAT)
    return img


def panel_lluvia():
    img, d = base_canvas((150, 165, 180), (205, 207, 205))  # cielo gris-azul
    # nube de base plana (lomos redondeados arriba)
    d.rounded_rectangle([405 * S, 370 * S, 735 * S, 440 * S], radius=35 * S, fill=CLOUD)
    for (cx, cy, rr) in [(470, 360, 75), (570, 330, 95), (670, 365, 72)]:
        x, y, r = cx * S, cy * S, rr * S
        d.ellipse([x - r, y - r, x + r, y + r], fill=CLOUD)
    # sombra sutil en el borde inferior para dar volumen
    d.rounded_rectangle([405 * S, 412 * S, 735 * S, 440 * S], radius=18 * S, fill=CLOUD_DK)
    # lineas de lluvia
    for x in range(360, 820, 55):
        for off in (0, 130, 260):
            xx = x * S
            yy = (470 + off) * S
            d.line([(xx, yy), (xx - 18 * S, yy + 70 * S)], fill=RAIN, width=6 * S)
    return img


def export(img, name):
    img = fade_bottom(img)
    img = img.resize((W // S, H // S), Image.LANCZOS)
    img.convert("RGB").save(name, "PNG")
    print("escrito:", name)


here = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(here, "..", "assets", "paneles")
os.makedirs(out, exist_ok=True)

export(panel_normal(), os.path.join(out, "panel1.png"))   # normal
export(panel_calor(),  os.path.join(out, "panel2.png"))   # calor
export(panel_normal(), os.path.join(out, "panel3.png"))   # normal (igual al 1)
export(panel_lluvia(), os.path.join(out, "panel4.png"))   # lluvia
print("Listo.")
