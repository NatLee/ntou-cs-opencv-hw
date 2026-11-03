#!/bin/sh
# Renders the README pictures: each <name>.html in this folder becomes ../<name>-light.png and
# ../<name>-dark.png (the page switches to its dark theme when opened with #dark).
#
# Needs a Chromium-based browser (set BROWSER, default msedge), ImageMagick 7 (magick) and pngquant.
# The pictures in the repo were rendered on Windows with Edge; the Chinese text uses Microsoft JhengHei.
#
# Usage: ./render.sh                 all pages
#        ./render.sh craps.html      only this one
set -eu
cd "$(dirname "$0")"
browser=${BROWSER:-msedge}
dir=$(pwd -W 2>/dev/null || pwd)   # the browser needs a Windows path when this runs in Git Bash
[ $# -gt 0 ] || set -- *.html

for page in "$@"; do
  name=${page%.html}
  for theme in light dark; do
    shot="$dir/$name-$theme-raw.png"
    # The window is larger than any picture; the transparent margin is trimmed off afterwards.
    "$browser" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
      --window-size=1100,1600 --default-background-color=00000000 --virtual-time-budget=8000 \
      --screenshot="$shot" "file:///${dir#/}/$page#$theme" 2>/dev/null
    magick "$name-$theme-raw.png" -trim +repage "$name-$theme-raw.png"
    pngquant 64 --floyd=0.5 --speed 1 --strip --force --output "../$name-$theme.png" "$name-$theme-raw.png"
    rm "$name-$theme-raw.png"
    echo "../$name-$theme.png"
  done
done
