#!/usr/bin/env python3
import sys
import os
from PIL import Image

def minimal_receipt_prep(image_path):
    try:
        img = Image.open(image_path)
        
        # ONLY convert to grayscale - no other processing
        if img.mode != 'L':
            img = img.convert('L')
        
        # Save with minimal processing
        base, ext = os.path.splitext(image_path)
        output_path = f"{base}_minimal{ext}"
        img.save(output_path, quality=95)
        
        print(output_path)
        return output_path
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    minimal_receipt_prep(sys.argv[1])
