#!/usr/bin/env python3
import sys
import os
from PIL import Image, ImageEnhance, ImageFilter, ImageOps, ImageStat
import math

def minimal_enhance(image_path):
    try:
        # Open and convert to grayscale
        img = Image.open(image_path).convert('L')
        
        # Step 1: Intelligent resizing (ensure good DPI)
        width, height = img.size
        min_dimension = min(width, height)
        if min_dimension < 600:  # Scale up small images
            scale = 600 / min_dimension
            new_size = (int(width * scale), int(height * scale))
            img = img.resize(new_size, Image.Resampling.LANCZOS)
        
        # Step 2: Auto-contrast based on image statistics
        stat = ImageStat.Stat(img)
        mean_brightness = stat.mean[0]
        
        # Adaptive contrast enhancement
        if mean_brightness < 100:  # Dark image
            contrast_factor = 2.5
        elif mean_brightness > 180:  # Bright image  
            contrast_factor = 1.8
        else:  # Normal image
            contrast_factor = 2.2
            
        enhancer = ImageEnhance.Contrast(img)
        contrast_img = enhancer.enhance(contrast_factor)
        
        # Step 3: Smart sharpening
        sharp_enhancer = ImageEnhance.Sharpness(contrast_img)
        sharp_img = sharp_enhancer.enhance(2.0)
        
        # Step 4: Clean up with filters (built into PIL)
        # Median filter removes salt-and-pepper noise
        filtered_img = sharp_img.filter(ImageFilter.MedianFilter(size=3))
        
        # Unsharp mask for final sharpening
        final_img = filtered_img.filter(ImageFilter.UnsharpMask(
            radius=1.5, percent=120, threshold=2))
        
        # Step 5: Ensure high contrast binary-like result
        # Auto-level adjustment
        final_img = ImageOps.autocontrast(final_img, cutoff=2)
        
        # Save result
        base, ext = os.path.splitext(image_path)
        output_path = f"{base}_enhanced{ext}"
        final_img.save(output_path, quality=95, optimize=True)
        
        print(output_path)
        return output_path
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 enhance_image.py <image_path>")
        sys.exit(1)
    
    minimal_enhance(sys.argv[1])
