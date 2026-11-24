#!/usr/bin/env bash
# shapes-json.sh <out.json>: every shape's points from components/Shapes.js, for tools/wallpaper.py (needs node)
here=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp --suffix=.js)
trap 'rm -f "$tmp"' EXIT
{ sed 's/^\.pragma library//' "$here/components/Shapes.js"
  echo 'var o={};names().forEach(function(n){o[n]=points(n)});console.log(JSON.stringify(o));'; } > "$tmp"
node "$tmp" > "$1"
