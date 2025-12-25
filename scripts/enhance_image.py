#!/usr/bin/env python3
import sys
from PIL import Image, ImageEnhance
import os

def enhance_contrast(image_path, factor=2.0):
    try:
        img = Image.open(image_path)
        enhancer = ImageEnhance.Contrast(img)
        enhanced_img = enhancer.enhance(factor)
        
        # Create output filename
        base, ext = os.path.splitext(image_path)
        enhanced_path = f"{base}_enhanced{ext}"
        
        enhanced_img.save(enhanced_path)
        print(enhanced_path)  # n8n will capture this as output
        return enhanced_path
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 enhance_image.py <image_path> [contrast_factor]")
        sys.exit(1)
    
    image_path = sys.argv[1]
    factor = float(sys.argv[2]) if len(sys.argv) > 2 else 2.0
    enhance_contrast(image_path, factor)
