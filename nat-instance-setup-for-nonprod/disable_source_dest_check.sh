#!/bin/bash

# Variables
REGION="us-east-1" # Change to your AWS region
TAG_KEY="Name"
TAG_VALUE_PREFIX="nat-instance-asg-" # Prefix for NAT instance Name tag

# Fetch instance IDs with the specified tag pattern
echo "Fetching NAT instance IDs with tag ${TAG_KEY} starting with ${TAG_VALUE_PREFIX}..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region "${REGION}" \
  --filters "Name=tag:${TAG_KEY},Values=${TAG_VALUE_PREFIX}*" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

if [ -z "${INSTANCE_IDS}" ]; then
  echo "No NAT instances found with the specified tag prefix."
  exit 1
fi

# Disable source/destination check for each instance
for INSTANCE_ID in ${INSTANCE_IDS}; do
  echo "Disabling source/destination check for instance: ${INSTANCE_ID}..."
  aws ec2 modify-instance-attribute \
    --region "${REGION}" \
    --instance-id "${INSTANCE_ID}" \
    --source-dest-check "{\"Value\": false}"

  if [ $? -eq 0 ]; then
    echo "Successfully disabled source/destination check for ${INSTANCE_ID}."
  else
    echo "Failed to disable source/destination check for ${INSTANCE_ID}."
  fi
done

echo "Source/destination check disabled for all matching NAT instances."
