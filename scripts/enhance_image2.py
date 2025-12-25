#!/usr/bin/env python3
import sys
import os
import cv2
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter
import tempfile

def comprehensive_enhance(image_path, output_path=None):
    """
    Apply multiple preprocessing techniques for optimal OCR results
    """
    try:
        # Read image with OpenCV for advanced processing
        img = cv2.imread(image_path)
        if img is None:
            # Fallback to PIL for other formats
            pil_img = Image.open(image_path)
            img = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
        
        # Step 1: Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Step 2: Noise removal using Non-Local Means Denoising
        denoised = cv2.fastNlMeansDenoising(gray, None, 10, 7, 21)
        
        # Step 3: Rescale image to optimal DPI (min 300 DPI recommended)
        height, width = denoised.shape
        scale_factor = max(1, 300 / min(height, width))  # Ensure minimum 300px
        if scale_factor > 1:
            new_width = int(width * scale_factor)
            new_height = int(height * scale_factor)
            resized = cv2.resize(denoised, (new_width, new_height), interpolation=cv2.INTER_CUBIC)
        else:
            resized = denoised
        
        # Step 4: Deskewing (straighten rotated text)
        coords = np.column_stack(np.where(resized > 0))
        if len(coords) > 0:
            angle = cv2.minAreaRect(coords)[-1]
            if angle < -45:
                angle = -(90 + angle)
            else:
                angle = -angle
            
            if abs(angle) > 0.5:  # Only rotate if significant skew
                (h, w) = resized.shape[:2]
                center = (w // 2, h // 2)
                M = cv2.getRotationMatrix2D(center, angle, 1.0)
                deskewed = cv2.warpAffine(resized, M, (w, h), 
                                        flags=cv2.INTER_CUBIC, 
                                        borderMode=cv2.BORDER_REPLICATE)
            else:
                deskewed = resized
        else:
            deskewed = resized
        
        # Step 5: Adaptive Thresholding (better than simple threshold)
        thresh = cv2.adaptiveThreshold(deskewed, 255, 
                                     cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                     cv2.THRESH_BINARY, 11, 2)
        
        # Step 6: Morphological operations to clean up text
        kernel = np.ones((2,2), np.uint8)
        # Remove small noise
        cleaned = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
        
        # Step 7: Sharpening using custom kernel
        sharpen_kernel = np.array([[-1,-1,-1],
                                 [-1, 9,-1],
                                 [-1,-1,-1]])
        sharpened = cv2.filter2D(cleaned, -1, sharpen_kernel)
        
        # Save processed image
        if output_path is None:
            base, ext = os.path.splitext(image_path)
            output_path = f"{base}_enhanced{ext}"
        
        cv2.imwrite(output_path, sharpened)
        print(output_path)  # n8n captures this
        return output_path
        
    except Exception as e:
        print(f"Error processing image: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 enhance_image.py <image_path> [output_path]")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None
    
    comprehensive_enhance(input_path, output_path)
