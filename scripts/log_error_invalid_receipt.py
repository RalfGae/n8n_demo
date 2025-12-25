from datetime import datetime

def create_error_log_entry(validation_data):
    """
    Create structured error log entry for receipts that fail validation.
    """
    
    validation = validation_data['validation']
    receipt_info = validation_data['receipt_info']
    
    error_entry = {
        'timestamp': datetime.now().isoformat(),
        'store': receipt_info['store'],
        'receipt_date': receipt_info['date'],
        'currency': receipt_info['currency'],
        'receipt_total': validation['receipt_total'],
        'calculated_sum': validation['calculated_sum'],
        'percentage_difference': validation['percentage_difference'],
        'tolerance_threshold': validation['tolerance_threshold'],
        'difference_amount': validation['difference_amount'],
        'items_count': validation['items_count'],
        'status': validation['status'],
        'requires_manual_review': True,
        'error_severity': 'HIGH' if validation['percentage_difference'] > 10 else 'MEDIUM'
    }
    
    return error_entry

# Usage in n8n Error Workflow:
error_data = $json
error_log = create_error_log_entry(error_data)
return {'json': error_log}
