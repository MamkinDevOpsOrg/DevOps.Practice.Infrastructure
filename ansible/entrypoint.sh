#!/bin/bash
set -e

if [ ! -f "/ansible/devops_practice.pem" ]; then
  echo "SSH private key not found at /ansible/devops_practice.pem"
  exit 1
fi

cp /ansible/devops_practice.pem /tmp/key.pem
chmod 400 /tmp/key.pem

ansible-playbook -i inventory.ini playbook.yml --private-key /tmp/key.pem
