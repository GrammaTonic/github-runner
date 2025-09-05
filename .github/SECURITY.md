# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability, please report it responsibly:

### Preferred Method: GitHub Security Advisories

1. Go to the [Security tab](https://github.com/GrammaTonic/github-runner/security) of this repository
2. Click "Report a vulnerability"
3. Fill out the advisory form with details

### Alternative: Email

Send an email to the repository maintainer with the following information:

- **Subject**: Security Vulnerability in github-runner
- **Description**: Clear description of the vulnerability
- **Steps to reproduce**: Detailed reproduction steps
- **Impact**: Potential security impact
- **Affected versions**: Which versions are affected

### What to Include

Please include the following details in your report:

- **Type of vulnerability** (e.g., code injection, privilege escalation, etc.)
- **Location of the vulnerability** (file path, line number if applicable)
- **Step-by-step instructions** to reproduce the issue
- **Proof of concept** (if applicable)
- **Impact assessment** (what could an attacker accomplish)
- **Suggested fix** (if you have one)

## Response Timeline

- **Initial Response**: Within 48 hours of receiving the report
- **Status Update**: Within 7 days with assessment and timeline
- **Fix Deployment**: Security fixes are prioritized and typically deployed within 14 days
- **Public Disclosure**: After fix is deployed and verified

## Security Best Practices

When using this GitHub Actions runner:

### Container Security

- Regularly update base Docker images
- Scan images for vulnerabilities using tools like Trivy
- Use non-root users in containers
- Apply resource limits to prevent abuse

### Token Security

- Store GitHub tokens securely using Docker secrets
- Rotate tokens regularly
- Use least-privilege access principles
- Never commit tokens to version control

### Network Security

- Isolate runner containers appropriately
- Use secure networks for sensitive workloads
- Monitor network traffic for anomalies

### Access Control

- Implement proper branch protection rules
- Require code review for all changes
- Use required status checks
- Limit repository access to necessary personnel

## Vulnerability Disclosure Policy

- We follow **responsible disclosure** practices
- Security researchers are credited for valid findings (unless they prefer to remain anonymous)
- We coordinate with reporters on disclosure timeline
- Public disclosure happens only after fixes are available

## Security Updates

- Security updates are released as patch versions
- Critical vulnerabilities may result in immediate releases
- Security advisories are published for all confirmed vulnerabilities
- Users are notified through GitHub Security Advisories

## Scope

This security policy covers:

- Docker images and configurations in this repository
- GitHub Actions workflows and scripts
- Documentation that could impact security
- Dependencies and third-party integrations

## Out of Scope

- Issues in third-party dependencies (report to upstream projects)
- General Docker or GitHub Actions platform issues
- Social engineering attacks
- Physical security issues

---

**Thank you for helping keep the GitHub Runner project secure!**
