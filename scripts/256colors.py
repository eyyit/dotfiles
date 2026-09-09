#!/usr/bin/env python3
# Original Author of the perl script: Todd Larason <jtl@molehill.org>
# $XFree86: xc/programs/xterm/vttests/256colors2.pl,v 1.2 2002/03/26 01:46:43

import sys

RESET = "\x1b[0m"
LAYERS = {38: "foreground", 48: "background"}

# System colors
max_colors = 16
for layer, name in LAYERS.items():
  print(f"System colors ({name}):")
  for color in range(max_colors):
    sys.stdout.write(f"\x1b[{layer};5;{color}m {color:2d} {RESET} ")
    if color == (max_colors - 1) or color == ((max_colors // 2) - 1):
      print()
  print()

# Color cube 6x6x6
for layer, name in LAYERS.items():
  print(f"Color cube 6x6x6 ({name}):")
  for green in range(6):
    for red in range(6):
      for blue in range(6):
        color = 16 + (red * 36) + (green * 6) + blue
        sys.stdout.write(f"\x1b[{layer};5;{color}m{color:3d}{RESET} ")
      sys.stdout.write(" ")
    print()
  print()

# Grayscale ramp
for layer, name in LAYERS.items():
  print(f"System colors ({name}):")
  for color in range(232, 256):
    sys.stdout.write(f"\x1b[{layer};5;{color}m {color:2d} {RESET} ")
  print("\n")
