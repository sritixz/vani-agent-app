import os
from PIL import Image

source_icon = r"C:\Users\sriti\.gemini\antigravity\brain\1be8bec8-c0d7-429a-95e3-f4d758d8b7a2\.user_uploaded\media_1787071929877.png"
res_dir = r"c:\Users\sriti\OneDrive\Desktop\VaniAgent\VaniAgent-App\vani-agent-app\android\app\src\main\res"

sizes = {
    "mipmap-mdpi": (48, 48),
    "mipmap-hdpi": (72, 72),
    "mipmap-xhdpi": (96, 96),
    "mipmap-xxhdpi": (144, 144),
    "mipmap-xxxhdpi": (192, 192),
}

img = Image.open(source_icon).convert("RGBA")

for folder, size in sizes.items():
    target_folder = os.path.join(res_dir, folder)
    os.makedirs(target_folder, exist_ok=True)
    
    # Save ic_launcher.png
    resized_img = img.resize(size, Image.Resampling.LANCZOS)
    target_path = os.path.join(target_folder, "ic_launcher.png")
    resized_img.save(target_path, "PNG")
    print(f"Updated {target_path} ({size[0]}x{size[1]})")

print("All launcher icons updated with exact target image successfully!")
