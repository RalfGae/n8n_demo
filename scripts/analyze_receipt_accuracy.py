def analyze_receipt_accuracy(validation_results):
    """
    Analyze multiple receipt validations for quality monitoring.
    """
    
    total_receipts = len(validation_results)
    valid_receipts = sum(1 for r in validation_results if r['validation']['is_valid'])
    
    accuracy_rate = (valid_receipts / total_receipts) * 100 if total_receipts > 0 else 0
    
    # Calculate average percentage difference
    avg_difference = sum(
        r['validation']['percentage_difference'] 
        for r in validation_results
    ) / total_receipts if total_receipts > 0 else 0
    
    # Store-wise statistics
    store_stats = {}
    for result in validation_results:
        store = result['receipt_info']['store']
        if store not in store_stats:
            store_stats[store] = {'total': 0, 'valid': 0, 'differences': []}
        
        store_stats[store]['total'] += 1
        if result['validation']['is_valid']:
            store_stats[store]['valid'] += 1
        store_stats[store]['differences'].append(result['validation']['percentage_difference'])
    
    # Calculate store-wise accuracy
    for store in store_stats:
        stats = store_stats[store]
        stats['accuracy_rate'] = (stats['valid'] / stats['total']) * 100
        stats['avg_difference'] = sum(stats['differences']) / len(stats['differences'])
    
    analysis = {
        'total_receipts_processed': total_receipts,
        'valid_receipts': valid_receipts,
        'overall_accuracy_rate': round(accuracy_rate, 2),
        'average_percentage_difference': round(avg_difference, 2),
        'store_statistics': store_stats,
        'analysis_date': datetime.now().isoformat()
    }
    
    return analysis

# Usage for periodic monitoring:
# validation_results = $json  # Array of validation results
# analysis = analyze_receipt_accuracy(validation_results)
# return {'json': analysis}
