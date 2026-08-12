#!/usr/bin/env python3
import re

with open("scenes/player.tscn", "r") as f:
    lines = f.readlines()

# 1. Add ext_resources for death frames after the last ext_resource
ext_resources = []
id_counter = 5
for direction in ["down", "left", "up"]:
    for i in range(1, 6):
        frame_id = f"{id_counter}_death_{direction[0]}{i}"
        path = f"res://assets/sprites/player/death_{direction}/{i}.png"
        ext_resources.append(f'[ext_resource type="Texture2D" path="{path}" id="{frame_id}"]\n')
        id_counter += 1

# Find last ext_resource line index
last_ext_idx = -1
for i, line in enumerate(lines):
    if line.startswith("[ext_resource"):
        last_ext_idx = i

# Insert after last ext_resource
insert_point = last_ext_idx + 1
for ext_line in reversed(ext_resources):
    lines.insert(insert_point, ext_line)

# 2. Add death animations before the `}]` that closes the animations array
# Find the line with `}]` after the "up" animation
target_line = None
for i, line in enumerate(lines):
    stripped = line.strip()
    if stripped == '}]' and i > 200:  # Should be after the up animation in SpriteFrames
        # Verify previous lines contain "up" animation
        prev_content = "".join(lines[max(0, i-10):i])
        if '&"up"' in prev_content:
            target_line = i
            break

if target_line is None:
    raise ValueError("Could not find animations array closing `}]`")

# Build death animations
death_anims = []
for direction in ["down", "left", "up"]:
    frames = []
    for i in range(1, 6):
        idx = 5 + (['down', 'left', 'up'].index(direction) * 5) + (i - 1)
        frame_id = f"{idx}_death_{direction[0]}{i}"
        frames.append(f'''{{
"duration": 1.0,
"texture": ExtResource("{frame_id}")
}}''')
    
    frames_str = ", ".join(frames)
    anim = f''', {{
"frames": [{frames_str}],
"loop": false,
"name": &"death_{direction}",
"speed": 8.0
}}'''
    death_anims.append(anim)

# Insert before the `}]`
for anim in reversed(death_anims):
    lines.insert(target_line, anim)

with open("scenes/player.tscn", "w") as f:
    f.writelines(lines)

print("Updated scenes/player.tscn with death animations")
