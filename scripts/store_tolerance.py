def get_store_tolerance(store_name):
    """
    Define store-specific tolerance thresholds based on typical receipt characteristics.
    """
    
    tolerance_by_store = {
        'IKEA': 3.0,        # Furniture store, fewer items, higher accuracy expected
        'REWE': 5.0,        # Grocery store, many small items, more OCR errors possible
        'EDEKA': 5.0,       # Grocery store, similar to REWE
        'ALDI': 4.0,        # Discount store, simpler receipts
        'LIDL': 4.0,        # Discount store, simpler receipts
        'ESSO': 2.0,        # Gas station, usually few items
        'SHELL': 2.0,       # Gas station, usually few items
        'AMAZON': 3.0,      # Online orders, usually accurate
        'DM': 4.0,          # Drugstore, medium complexity
        'default': 5.0      # Default for unknown stores
    }
    
    return tolerance_by_store.get(store_name.upper(), tolerance_by_store['default'])

def validate_receipt_with_store_tolerance(receipt_data):
    """
    Enhanced validation with store-specific tolerances.
    """
    
    store_name = receipt_data['receipt_info']['store']
    tolerance = get_store_tolerance(store_name)
    
    receipt_total = receipt_data['receipt_info']['total_amount']
    items = receipt_data['items']
    
    calculated_sum = sum(
        item['price'] * item.get('quantity', 1) 
        for item in items
    )
    
    if receipt_total == 0:
        percentage_difference = 100.0 if calculated_sum != 0 else 0.0
    else:
        percentage_difference = abs((receipt_total - calculated_sum) / receipt_total) * 100
    
    is_valid = percentage_difference <= tolerance
    
    return {
        **receipt_data,
        'validation': {
            'receipt_total': receipt_total,
            'calculated_sum': round(calculated_sum, 2),
            'percentage_difference': round(percentage_difference, 2),
            'tolerance_threshold': tolerance,
            'store_specific_tolerance': True,
            'is_valid': is_valid,
            'difference_amount': round(abs(receipt_total - calculated_sum), 2),
            'status': 'VALID' if is_valid else 'PRICE_MISMATCH',
            'items_count': len(items)
        }
    }

# Usage in n8n:
receipt_data = $json.output
result = validate_receipt_with_store_tolerance(receipt_data)
return {'json': result}
