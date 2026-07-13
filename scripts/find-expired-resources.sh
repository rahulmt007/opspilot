#!/usr/bin/env bash
set -euo pipefail
: "${AWS_REGION:=us-east-1}"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
aws resourcegroupstaggingapi get-resources --region "$AWS_REGION" \
  --tag-filters Key=Project,Values=opspilot \
  --query "ResourceTagMappingList[?Tags[?Key=='ExpiresAt' && Value<='${now}']].[ResourceARN,Tags]" \
  --output table
echo "Review only: destroy resources with Terraform; this script does not delete anything."
