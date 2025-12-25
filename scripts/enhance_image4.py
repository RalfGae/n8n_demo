#!/usr/bin/env python3
import sys
import os
from PIL import Image, ImageEnhance, ImageFilter, ImageOps

def receipt_processing(image_path):
    try:
        img = Image.open(image_path)
        
        # Step 1: Convert to grayscale
        gray_img = ImageOps.grayscale(img)
        
        # Step 2: Aggressive resize for small text
        width, height = gray_img.size
        if min(width, height) < 800:  # Receipt needs larger size
            scale = 800 / min(width, height)
            new_size = (int(width * scale), int(height * scale))
            gray_img = gray_img.resize(new_size, Image.Resampling.LANCZOS)
        
        # Step 3: Strong contrast for faded receipts
        contrast_enhancer = ImageEnhance.Contrast(gray_img)
        high_contrast = contrast_enhancer.enhance(3.0)  # Very high for receipts
        
        # Step 4: Brightness adjustment for gray receipts
        brightness_enhancer = ImageEnhance.Brightness(high_contrast)
        bright_img = brightness_enhancer.enhance(1.3)
        
        # Step 5: Auto-level to maximize black/white separation
        auto_leveled = ImageOps.autocontrast(bright_img, cutoff=5)
        
        # Step 6: Sharp enhancement for small text
        sharpness_enhancer = ImageEnhance.Sharpness(auto_leveled)
        sharp_img = sharpness_enhancer.enhance(2.5)
        
        # Save result
        base, ext = os.path.splitext(image_path)
        output_path = f"{base}_enhanced{ext}"
        sharp_img.save(output_path, quality=95)
        
        print(output_path)
        return output_path
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    receipt_processing(sys.argv[1])
