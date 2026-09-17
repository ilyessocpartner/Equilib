#!/usr/bin/env python3
"""Genere l'icone (512x512) et les miniatures (1920x1080) du jeu a partir des sources HTML/SVG de src/.

Pre-requis : pip install playwright && playwright install chromium
(ou definir CHROME_PATH vers un executable Chromium existant).
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")
SPECS = [
    ("icon.html", 512, 512, "icone_512.png"),
    ("thumb_main.html", 1920, 1080, "miniature_1_principale.png"),
    ("thumb_boss.html", 1920, 1080, "miniature_2_raid_minuit.png"),
    ("thumb_crypt.html", 1920, 1080, "miniature_3_crypte.png"),
]


def assemble(name):
    with open(os.path.join(SRC, "common.css"), encoding="utf-8") as handle:
        common = handle.read()
    with open(os.path.join(SRC, "symbols.svg"), encoding="utf-8") as handle:
        symbols = handle.read()
    with open(os.path.join(SRC, name), encoding="utf-8") as handle:
        page = handle.read()
    style = ""
    match = re.search(r"<style>(.*?)</style>", page, re.S)
    if match:
        style = match.group(1)
        page = page.replace(match.group(0), "")
    html = f"<!doctype html><html><head><meta charset='utf-8'><style>{common}</style><style>{style}</style></head><body>{symbols}{page}</body></html>"
    out = os.path.join(SRC, "_" + name.replace(".html", ".build.html"))
    with open(out, "w", encoding="utf-8") as handle:
        handle.write(html)
    return out


def main():
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("Installe Playwright : pip install playwright && playwright install chromium")
        sys.exit(1)
    executable = os.environ.get("CHROME_PATH")
    with sync_playwright() as playwright:
        launch = {"executable_path": executable} if executable else {}
        browser = playwright.chromium.launch(**launch)
        for name, width, height, output in SPECS:
            built = assemble(name)
            page = browser.new_page(viewport={"width": width, "height": height}, device_scale_factor=1)
            page.goto("file://" + built)
            page.evaluate("document.fonts.ready")
            page.wait_for_timeout(400)
            target = os.path.join(HERE, output)
            page.screenshot(path=target, full_page=False)
            page.close()
            os.remove(built)
            print("OK", output, f"{width}x{height}")
        browser.close()


if __name__ == "__main__":
    main()
