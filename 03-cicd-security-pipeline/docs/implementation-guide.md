# Security Pipeline Implementation Guide

## Prerequisites

- GitHub repository
- GitHub Actions enabled
- Basic understanding of CI/CD
- AWS account (optional, for deployment)

## Quick Start

### 1. Copy Workflow Files

```bash
# Copy the .github/workflows directory to your repository
cp -r .github/workflows /path/to/your/repo/.github/

# Copy policies directory
cp -r policies /path/to/your/repo/

# Copy Gitleaks config
cp .gitleaks.toml /path/to/your/repo/
```

### 2. Configure Branch Protection

```bash
# Enable branch protection for main branch
# Settings → Branches → Add rule

Required settings:
✓ Require status checks to pass before merging
✓ Require branches to be up to date before merging
✓ Status checks: security-scan, sast-scan, dependency-scan, iac-security
✓ Require pull request reviews before merging
✓ Dismiss stale pull request approvals when new commits are pushed
```

### 3. Enable GitHub Security Features

```bash
# Settings → Security & analysis

Enable:
✓ Dependency graph
✓ Dependabot alerts
✓ Dependabot security updates
✓ Code scanning (if using GitHub Advanced Security)
```

### 4. Test the Pipeline

```bash
# Create a test branch
git checkout -b test-security-pipeline

# Make a change
echo "# Test" >> README.md

# Commit and push
git add README.md
git commit -m "Test security pipeline"
git push origin test-security-pipeline

# Create pull request and watch the checks run
```

## Configuration

### Customizing Severity Thresholds

Edit `.github/workflows/security-scan.yml`:

```yaml
# For Trivy - adjust severity levels
- name: Run Trivy
  with:
    severity: 'CRITICAL,HIGH'  # Change to 'CRITICAL,HIGH,MEDIUM' for stricter
    exit-code: '1'  # Change to '0' to not fail on findings

# For Semgrep - adjust config
- name: Run Semgrep
  with:
    config: >-
      p/security-audit
      p/owasp-top-ten
      # Add more rulesets as needed
```

### Adding Custom OPA Policies

Create new `.rego` files in `policies/` directory:

```rego
# policies/custom.rego
package custom

deny[msg] {
    # Your custom policy logic
    msg := "Custom policy violation"
}
```

### Configuring Notifications

#### Slack Notifications

1. Create Slack webhook
2. Add to GitHub Secrets as `SLACK_WEBHOOK_URL`
3. Uncomment Slack notification step in workflow

#### Email Notifications

GitHub automatically sends emails for:
- Failed workflow runs
- Security alerts
- Pull request comments

## Troubleshooting

### Pipeline Takes Too Long

**Problem:** Scans taking > 15 minutes

**Solutions:**
```yaml
# 1. Run jobs in parallel (already configured)
# 2. Cache dependencies
- name: Cache dependencies
  uses: actions/cache@v3
  with:
    path: ~/.cache
    key: ${{ runner.os }}-deps-${{ hashFiles('**/requirements.txt') }}

# 3. Skip unnecessary scans
- name: Run container scan
  if: hashFiles('**/Dockerfile') != ''  # Only if Dockerfile exists
```

### Too Many False Positives

**Problem:** Pipeline failing on non-issues

**Solutions:**
```toml
# 1. Update .gitleaks.toml allowlist
[allowlist]
regexes = [
    '''your-false-positive-pattern''',
]

# 2. Skip specific Checkov checks
- name: Run Checkov
  with:
    skip_check: CKV_AWS_20,CKV_AWS_57  # Skip specific checks
```

### Secrets Detected in History

**Problem:** Gitleaks finds secrets in old commits

**Solutions:**
```bash
# Option 1: Use BFG Repo-Cleaner to remove secrets
java -jar bfg.jar --replace-text passwords.txt your-repo.git

# Option 2: Add to allowlist if false positive
# .gitleaks.toml
[allowlist]
commits = ["commit-hash-with-false-positive"]

# Option 3: Rotate the exposed secret immediately
```

### Pipeline Fails on Dependency Scan

**Problem:** Critical CVE found in dependency

**Solutions:**
```bash
# 1. Update the vulnerable dependency
pip install --upgrade vulnerable-package

# 2. If no fix available, document exception
# Create issue with:
# - CVE details
# - Why it's acceptable risk
# - Mitigation controls
# - Remediation timeline

# 3. Add to exception list (temporary)
# .trivyignore
CVE-2021-12345  # Expires: 2024-12-31, Reason: No fix available
```

## Testing the Pipeline

### Test 1: Secrets Detection

```bash
# This should FAIL
echo 'AWS_KEY = "AKIAIOSFODNN7EXAMPLE"' >> test.py
git add test.py
git commit -m "Test secrets detection"
git push

# Expected: Pipeline fails with Gitleaks error
```

### Test 2: SAST Findings

```bash
# This should FAIL
cat > test.py << 'EOF'
import os
def run_command(user_input):
    os.system(user_input)  # Command injection
EOF

git add test.py
git commit -m "Test SAST detection"
git push

# Expected: Pipeline fails with Semgrep/Bandit error
```

### Test 3: Vulnerable Dependency

```bash
# This should FAIL (if critical CVE exists)
echo "requests==2.6.0" >> requirements.txt  # Old version with CVEs
git add requirements.txt
git commit -m "Test dependency scan"
git push

# Expected: Pipeline fails with Trivy error
```

### Test 4: IaC Security

```bash
# This should FAIL
cat > main.tf << 'EOF'
resource "aws_s3_bucket" "test" {
  bucket = "test-bucket"
  acl    = "public-read"  # Public bucket
}
EOF

git add main.tf
git commit -m "Test IaC security"
git push

# Expected: Pipeline fails with Checkov error
```

## Integration with Existing Workflows

### Adding to Existing Pipeline

```yaml
# your-existing-workflow.yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: make build

  # Add security scan before deploy
  security:
    needs: build
    uses: ./.github/workflows/security-scan.yml

  deploy:
    needs: security  # Only deploy if security passes
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: make deploy
```

### Pre-commit Hooks (Optional)

```bash
# Install pre-commit
pip install pre-commit

# Create .pre-commit-config.yaml
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  - repo: https://github.com/semgrep/semgrep
    rev: v1.45.0
    hooks:
      - id: semgrep
        args: ['--config', 'p/security-audit']
EOF

# Install hooks
pre-commit install
```

## Monitoring and Metrics

### View Scan Results

```bash
# GitHub UI
Repository → Actions → Select workflow run → View logs

# GitHub Security Tab
Repository → Security → Code scanning alerts

# Download artifacts
gh run download <run-id>
```

### Track Metrics

```bash
# Create metrics dashboard
# Use GitHub API to collect data

curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo/actions/runs \
  | jq '.workflow_runs[] | {name: .name, conclusion: .conclusion}'
```

## Maintenance

### Weekly Tasks
- Review failed pipelines
- Update exception list
- Check for tool updates

### Monthly Tasks
- Review metrics dashboard
- Update severity thresholds
- Tune false positive filters
- Update documentation

### Quarterly Tasks
- Review and update policies
- Audit exception list
- Update tool versions
- Security team retrospective

## Cost Optimization

### Reduce GitHub Actions Minutes

```yaml
# 1. Use caching
- uses: actions/cache@v3

# 2. Skip redundant scans
if: github.event_name == 'pull_request'

# 3. Use self-hosted runners (for high volume)
runs-on: self-hosted
```

### Free Tier Limits

- GitHub Actions: 2,000 minutes/month (private repos)
- All scanning tools: Free (open source)
- Storage: 500MB artifacts

## Next Steps

1. Customize policies for your organization
2. Integrate with Slack/email notifications
3. Add custom Semgrep rules
4. Set up metrics dashboard
5. Train team on pipeline usage
6. Document exception process
7. Schedule regular reviews
