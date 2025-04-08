#!/bin/bash

# Use this script to delete NAT Gateway to allow 'terraform destroy' delete all network entities without errors
# FOR DEBUG/TRAINING PURPOSES ONLY!!!

set -e

# Step 1: Get NAT Gateway ID from Terraform outputs
echo "Getting NAT Gateway ID..."
NAT_GW_ID=$(terraform output -raw nat_gateway_id 2>/dev/null)

if [[ -z "$NAT_GW_ID" ]]; then
  echo "❌ NAT Gateway ID not found in Terraform outputs."
  exit 1
fi

echo "NAT Gateway ID: $NAT_GW_ID"

# Step 2: Delete NAT Gateway
echo "Deleting NAT Gateway..."
aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_GW_ID" > /dev/null
echo "Waiting for NAT Gateway to be deleted..."

# Step 3: Wait for NAT Gateway to reach 'deleted' status
while true; do
  STATUS=$(aws ec2 describe-nat-gateways \
    --nat-gateway-ids "$NAT_GW_ID" \
    --query "NatGateways[0].State" \
    --output text 2>/dev/null)

  if [[ "$STATUS" == "deleted" ]]; then
    echo "NAT Gateway deleted successfully."
    break
  fi

  if [[ "$STATUS" == "failed" || "$STATUS" == "null" ]]; then
    echo "NAT Gateway not found or already deleted."
    break
  fi

  echo "Current status: $STATUS — waiting 15s..."
  sleep 15
done

# Step 4: Release all unattached EIPs (optional cleanup)
echo "Checking for unattached EIPs..."
EIP_ALLOC_IDS=$(aws ec2 describe-addresses \
  --query "Addresses[?AssociationId==null].AllocationId" \
  --output text)

if [[ -n "$EIP_ALLOC_IDS" ]]; then
  for alloc_id in $EIP_ALLOC_IDS; do
    echo "Releasing EIP with AllocationId: $alloc_id"
    aws ec2 release-address --allocation-id "$alloc_id"
  done
else
  echo "No unattached EIPs found."
fi

echo "✅ Pre-destroy cleanup complete. Ready for 'terraform destroy'."
