# Ansible (Local Docker-Based Setup)

This folder contains an **Ansible-based automation setup** for configuring EC2 instances, specifically used for:

- Installing Docker from Docker APT repository
- Installing AWS CLI v2
- Preparing the EC2 for running Docker containers from ECR

---

## Motivation

Running Ansible on **Windows** can be tricky due to:

- Lack of native support
- Limited functionality through WSL (e.g., network issues, package installation problems)

### Solution

We use **Docker** to run Ansible in an isolated Ubuntu-based container environment — fully portable and repeatable across machines.

---

## Folder Structure

```
ansible/
├── aws_ec2.yml              # Сonfig for inventory plugin amazon.aws.aws_ec2 (to dynamically generate inventory from AWS for Github Actions)
├── Dockerfile               # Defines Ansible environment in Ubuntu container
├── entrypoint.sh            # Entrypoint that handles key permissions and launches Ansible
├── inventory.ini            # Static inventory with EC2 public IP
├── playbook.yml             # Main provisioning tasks (Docker + AWS CLI)
└── devops_practice.pem      # SSH key for EC2 access (not versioned in VCS)

```

---

## Docker Setup & Run

Build the Ansible image:

```bash
docker build -t local_ansible .
```

Run Ansible with volume mount:

```bash
docker run --rm -it -v ${PWD}:/ansible -w /ansible local_ansible
```

Make sure:

- Your private key `devops_practice.pem` is present in this folder
- The key has proper permissions (`chmod 400 devops_practice.pem`)
- You replace the IP in `inventory.ini` with the correct EC2 public IP

---

## Notes

- The `entrypoint.sh` copies and secures the private key before launching the playbook
- Ansible connects to EC2 over SSH using `ansible_user=ubuntu`
- Target AMI: **Ubuntu Server 24.04 LTS** (`ami-075686beab831bb7f`)

---

## 🚀 CI/CD Integration

This Docker setup is mainly for **local use only**.
In CI/CD (e.g., GitHub Actions), Ansible will run **natively inside the runner**, not via Docker.

---

```

```
