#!/usr/bin/env python3
import sys
import json

def check_price_difference(receipt_data, threshold=0.05):
    receipt_total = receipt_data['receipt_info']['total_amount']
    items = receipt_data['items']
    # Ignore quantity, sum only the price of each item
    calculated_sum = sum(
        item['price']
        for item in items
    )
    difference = abs(receipt_total - calculated_sum)
    percentage_difference = abs(difference / receipt_total) if receipt_total else 0.0

    is_significant = percentage_difference > threshold
    return {
        'receiptTotal': receipt_total,
        'calculatedSum': round(calculated_sum, 2),
        'difference': round(difference, 2),
        'percentageDifference': round(percentage_difference * 100, 2),
        'isSignificant': is_significant
    }

if __name__ == "__main__":
    if len(sys.argv) > 1:
        input_path = sys.argv[1]
        with open(input_path, 'r') as f:
            receipt_data = json.load(f)
    else:
        try:
            receipt_data = json.load(sys.stdin)
        except Exception as e:
            print("Usage: python3 receipt_price_check.py <receipt_data.json> OR echo '<json>' | python3 receipt_price_check.py", file=sys.stderr)
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    result = check_price_difference(receipt_data, threshold=0.05)
    print(json.dumps(result, indent=2))
