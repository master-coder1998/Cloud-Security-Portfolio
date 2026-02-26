#!/usr/bin/env bash

# Prowler Security Audit Script
# Automates AWS security scanning with Prowler

set -euo pipefail

# Configuration
PROWLER_VERSION="3.0"
OUTPUT_DIR="./reports/$(date +%Y-%m-%d)"
AWS_PROFILE="${AWS_PROFILE:-default}"
AWS_REGIONS="${AWS_REGIONS:-all}"
COMPLIANCE="${COMPLIANCE:-cis_1.5_aws}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Prowler is installed
    if ! command -v prowler &> /dev/null; then
        log_error "Prowler is not installed. Install with: pip install prowler"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
        log_error "AWS credentials not configured for profile: $AWS_PROFILE"
        exit 1
    fi
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    log_info "Prerequisites check passed"
}

run_prowler_scan() {
    log_info "Starting Prowler scan..."
    log_info "Profile: $AWS_PROFILE"
    log_info "Compliance: $COMPLIANCE"
    log_info "Output: $OUTPUT_DIR"
    
    # Run Prowler with multiple output formats
    prowler aws \
        --profile "$AWS_PROFILE" \
        --compliance "$COMPLIANCE" \
        --output-formats json csv html \
        --output-directory "$OUTPUT_DIR" \
        --verbose \
        || {
            log_error "Prowler scan failed"
            exit 1
        }
    
    log_info "Prowler scan completed successfully"
}

generate_summary() {
    log_info "Generating scan summary..."
    
    # Find the JSON output file
    JSON_FILE=$(find "$OUTPUT_DIR" -name "*.json" -type f | head -n 1)
    
    if [ -z "$JSON_FILE" ]; then
        log_warn "No JSON output found, skipping summary"
        return
    fi
    
    # Parse findings using jq
    if command -v jq &> /dev/null; then
        TOTAL=$(jq '. | length' "$JSON_FILE")
        CRITICAL=$(jq '[.[] | select(.severity=="critical")] | length' "$JSON_FILE")
        HIGH=$(jq '[.[] | select(.severity=="high")] | length' "$JSON_FILE")
        MEDIUM=$(jq '[.[] | select(.severity=="medium")] | length' "$JSON_FILE")
        LOW=$(jq '[.[] | select(.severity=="low")] | length' "$JSON_FILE")
        
        # Create summary file
        SUMMARY_FILE="$OUTPUT_DIR/summary.txt"
        cat > "$SUMMARY_FILE" << EOF
AWS Security Audit Summary
==========================
Date: $(date)
Profile: $AWS_PROFILE
Compliance: $COMPLIANCE

Findings Summary:
-----------------
Total Findings: $TOTAL
  - Critical: $CRITICAL
  - High: $HIGH
  - Medium: $MEDIUM
  - Low: $LOW

Report Location: $OUTPUT_DIR

Next Steps:
-----------
1. Review critical and high findings immediately
2. Prioritize remediation based on risk
3. Create remediation tickets
4. Schedule follow-up scan

EOF
        
        cat "$SUMMARY_FILE"
        log_info "Summary saved to: $SUMMARY_FILE"
    else
        log_warn "jq not installed, skipping detailed summary"
    fi
}

send_notification() {
    log_info "Sending notification..."
    
    # Example: Send to Slack (requires SLACK_WEBHOOK_URL environment variable)
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        SUMMARY_FILE="$OUTPUT_DIR/summary.txt"
        if [ -f "$SUMMARY_FILE" ]; then
            curl -X POST "$SLACK_WEBHOOK_URL" \
                -H 'Content-Type: application/json' \
                -d "{\"text\": \"AWS Security Audit Completed\n\`\`\`$(cat $SUMMARY_FILE)\`\`\`\"}" \
                || log_warn "Failed to send Slack notification"
        fi
    fi
    
    # Example: Send email (requires AWS SES configured)
    if [ -n "${NOTIFICATION_EMAIL:-}" ]; then
        aws ses send-email \
            --from "security@example.com" \
            --to "$NOTIFICATION_EMAIL" \
            --subject "AWS Security Audit Completed - $(date +%Y-%m-%d)" \
            --text "file://$OUTPUT_DIR/summary.txt" \
            --profile "$AWS_PROFILE" \
            || log_warn "Failed to send email notification"
    fi
}

main() {
    log_info "=== AWS Security Audit with Prowler ==="
    
    check_prerequisites
    run_prowler_scan
    generate_summary
    send_notification
    
    log_info "=== Audit Complete ==="
    log_info "Review the reports in: $OUTPUT_DIR"
}

# Run main function
main "$@"
