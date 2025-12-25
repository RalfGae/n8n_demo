def validate_receipt_prices(receipt_data):
    """
    Validate receipt by comparing total amount with sum of individual items.
    Calculate percentage difference for quality control.
    """
    
    receipt_total = receipt_data['receipt_info']['total_amount']
    items = receipt_data['items']
    
    # Calculate sum of all individual item prices
    calculated_sum = sum(
        item['price'] * item.get('quantity', 1) 
        for item in items
    )
    
    # Calculate percentage difference
    if receipt_total == 0:
        percentage_difference = 100.0 if calculated_sum != 0 else 0.0
    else:
        percentage_difference = abs((receipt_total - calculated_sum) / receipt_total) * 100
    
    # Define tolerance threshold (e.g., 5%)
    tolerance = 5.0
    
    # Validation result
    is_valid = percentage_difference <= tolerance
    difference_amount = abs(receipt_total - calculated_sum)
    
    # Enhanced output with validation info
    validation_result = {
        **receipt_data,
        'validation': {
            'receipt_total': receipt_total,
            'calculated_sum': round(calculated_sum, 2),
            'percentage_difference': round(percentage_difference, 2),
            'tolerance_threshold': tolerance,
            'is_valid': is_valid,
            'difference_amount': round(difference_amount, 2),
            'status': 'VALID' if is_valid else 'PRICE_MISMATCH'
        }
    }
    
    return validation_result

# Example usage in n8n Code Node:

if __name__ == "__main__":
    import sys
    import json
    if len(sys.argv) > 1:
        input_path = sys.argv[1]
        with open(input_path, 'r') as f:
            receipt_data = json.load(f)
    else:
        try:
            receipt_data = json.load(sys.stdin)
        except Exception as e:
            print("Usage: python3 price_validator.py <receipt_data.json> OR echo '<json>' | python3 price_validator.py", file=sys.stderr)
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    # Handle array input
    if isinstance(receipt_data, list):
        if receipt_data:
            # If the first element has 'output', use it
            if isinstance(receipt_data[0], dict) and 'output' in receipt_data[0]:
                receipt_data = receipt_data[0]['output']
            else:
                receipt_data = receipt_data[0]
        else:
            print("Error: Input array is empty.", file=sys.stderr)
            sys.exit(1)
    result = validate_receipt_prices(receipt_data)
    print(json.dumps(result, indent=2))
