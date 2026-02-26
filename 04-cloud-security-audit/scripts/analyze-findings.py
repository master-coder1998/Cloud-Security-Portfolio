#!/usr/bin/env python3
"""
Prowler Findings Analyzer
Parses Prowler JSON output and calculates risk scores
"""

import json
import sys
from collections import defaultdict
from typing import Dict, List

# Risk scoring weights
SEVERITY_WEIGHTS = {
    'critical': 5,
    'high': 4,
    'medium': 3,
    'low': 2,
    'informational': 1
}

EXPLOITABILITY_MAP = {
    'public_exposure': 5,
    'authentication_bypass': 5,
    'privilege_escalation': 4,
    'information_disclosure': 3,
    'configuration_weakness': 2,
    'best_practice': 1
}

def calculate_risk_score(finding: Dict) -> int:
    """Calculate risk score for a finding"""
    severity = finding.get('severity', 'low').lower()
    severity_score = SEVERITY_WEIGHTS.get(severity, 1)
    
    # Assess exploitability based on finding type
    check_id = finding.get('check_id', '')
    exploitability = assess_exploitability(check_id, finding)
    
    # Assess exposure (simplified - would need more context in production)
    exposure = 3  # Default to moderate
    if 'public' in check_id.lower() or 'internet' in check_id.lower():
        exposure = 5
    
    # Calculate risk score
    risk_score = severity_score * exploitability * exposure
    
    return risk_score

def assess_exploitability(check_id: str, finding: Dict) -> int:
    """Assess exploitability based on finding characteristics"""
    check_lower = check_id.lower()
    
    if any(keyword in check_lower for keyword in ['public', 'open', '0.0.0.0']):
        return 5
    elif any(keyword in check_lower for keyword in ['mfa', 'authentication', 'password']):
        return 4
    elif any(keyword in check_lower for keyword in ['encryption', 'logging', 'monitoring']):
        return 3
    elif any(keyword in check_lower for keyword in ['policy', 'permission']):
        return 2
    else:
        return 1

def analyze_findings(json_file: str) -> Dict:
    """Analyze Prowler findings from JSON file"""
    try:
        with open(json_file, 'r') as f:
            findings = json.load(f)
    except FileNotFoundError:
        print(f"Error: File not found: {json_file}")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in file: {json_file}")
        sys.exit(1)
    
    # Initialize counters
    stats = {
        'total': len(findings),
        'by_severity': defaultdict(int),
        'by_service': defaultdict(int),
        'by_region': defaultdict(int),
        'high_risk': []
    }
    
    # Process each finding
    for finding in findings:
        severity = finding.get('severity', 'unknown').lower()
        service = finding.get('service_name', 'unknown')
        region = finding.get('region', 'global')
        
        stats['by_severity'][severity] += 1
        stats['by_service'][service] += 1
        stats['by_region'][region] += 1
        
        # Calculate risk score
        risk_score = calculate_risk_score(finding)
        finding['risk_score'] = risk_score
        
        # Track high-risk findings
        if risk_score >= 50:
            stats['high_risk'].append({
                'check_id': finding.get('check_id'),
                'check_title': finding.get('check_title'),
                'severity': severity,
                'risk_score': risk_score,
                'resource': finding.get('resource_id', 'N/A'),
                'region': region
            })
    
    # Sort high-risk findings by score
    stats['high_risk'].sort(key=lambda x: x['risk_score'], reverse=True)
    
    return stats

def print_summary(stats: Dict):
    """Print analysis summary"""
    print("\n" + "="*80)
    print("PROWLER FINDINGS ANALYSIS")
    print("="*80)
    
    print(f"\nTotal Findings: {stats['total']}")
    
    print("\nFindings by Severity:")
    print("-" * 40)
    for severity in ['critical', 'high', 'medium', 'low', 'informational']:
        count = stats['by_severity'].get(severity, 0)
        percentage = (count / stats['total'] * 100) if stats['total'] > 0 else 0
        print(f"  {severity.upper():15} {count:4} ({percentage:5.1f}%)")
    
    print("\nTop 5 Services with Most Findings:")
    print("-" * 40)
    top_services = sorted(stats['by_service'].items(), key=lambda x: x[1], reverse=True)[:5]
    for service, count in top_services:
        print(f"  {service:20} {count:4}")
    
    print("\nTop 5 Regions with Most Findings:")
    print("-" * 40)
    top_regions = sorted(stats['by_region'].items(), key=lambda x: x[1], reverse=True)[:5]
    for region, count in top_regions:
        print(f"  {region:20} {count:4}")
    
    print(f"\nHigh-Risk Findings (Risk Score >= 50): {len(stats['high_risk'])}")
    print("-" * 80)
    
    if stats['high_risk']:
        print("\nTop 10 Highest Risk Findings:")
        print("-" * 80)
        for i, finding in enumerate(stats['high_risk'][:10], 1):
            print(f"\n{i}. [{finding['severity'].upper()}] {finding['check_title']}")
            print(f"   Risk Score: {finding['risk_score']}")
            print(f"   Resource: {finding['resource']}")
            print(f"   Region: {finding['region']}")
            print(f"   Check ID: {finding['check_id']}")
    
    print("\n" + "="*80)
    print("RECOMMENDATIONS")
    print("="*80)
    print("\n1. Address all CRITICAL and HIGH severity findings immediately")
    print("2. Focus on findings with risk score >= 75 first")
    print("3. Review and remediate high-risk findings in the next 7 days")
    print("4. Create tickets for MEDIUM severity findings")
    print("5. Schedule follow-up scan after remediation")
    print("\n" + "="*80 + "\n")

def export_csv(stats: Dict, output_file: str):
    """Export high-risk findings to CSV"""
    import csv
    
    with open(output_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'rank', 'severity', 'risk_score', 'check_title', 
            'check_id', 'resource', 'region'
        ])
        writer.writeheader()
        
        for i, finding in enumerate(stats['high_risk'], 1):
            writer.writerow({
                'rank': i,
                'severity': finding['severity'],
                'risk_score': finding['risk_score'],
                'check_title': finding['check_title'],
                'check_id': finding['check_id'],
                'resource': finding['resource'],
                'region': finding['region']
            })
    
    print(f"High-risk findings exported to: {output_file}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python analyze-findings.py <prowler-output.json>")
        sys.exit(1)
    
    json_file = sys.argv[1]
    
    print(f"Analyzing Prowler findings from: {json_file}")
    stats = analyze_findings(json_file)
    print_summary(stats)
    
    # Export high-risk findings to CSV
    csv_file = json_file.replace('.json', '-high-risk.csv')
    if stats['high_risk']:
        export_csv(stats, csv_file)

if __name__ == '__main__':
    main()
