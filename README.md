# DevOps Learning Projects

This repository contains projects and examples for learning DevOps technologies and tools through hands-on practice.  
It includes practical tasks using Terraform, cloud infrastructure (AWS), CI/CD automation, and infrastructure-as-code patterns.

Below you can find onboarding guide.

---

## DevOps Onboarding Guide

This guide will help you get access, clone the repository, and make your first contribution using Terraform and GitHub Actions.

---

## 1. Get Access to the Repository

Ask the repository owner ([@a-kapset](https://github.com/a-kapset) | artemkapset@gmail.com) to add you as a **Collaborator**.

Once you receive the invitation:

- Accept it via email or GitHub notification
- You’ll now have push and PR permissions

(Don't forget to install Git if hasn't been installed yet https://git-scm.com/downloads)

---

## 2. Set Up SSH Access to GitHub

If you haven’t set up SSH access yet then generate SSH keys:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Add your public key (~/.ssh/id_ed25519.pub) to GitHub:  
`GitHub → Profile → Settings → SSH and GPG Keys → New SSH Key`

Test your access:

```bash
ssh -T git@github.com
```

---

## 3. Clone the Repository and Create a Branch

```bash
git clone git@github.com:MamkinDevOpsOrg/DevOps.Practice.Infrastructure.git
cd ./DevOps.Practice.Infrastructure
git checkout -b devops/your-name/first-task
```

---

## 4. Install Required Tools

Ensure you have the following tools installed:

- Terraform — https://developer.hashicorp.com/terraform/install
- AWS CLI — https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### 4.1 Install Ansible (Optional for Local Provisioning)

If you want to manually provision EC2 instances (e.g. Docker, AWS CLI), install Ansible:

```bash
sudo apt update && sudo apt install ansible
```

More details in [`ansible/README.md`](./ansible/README.md)

---

## 5. Configure AWS Credentials

You need an IAM user with permissions:

| Service | Permissions         |
| ------- | ------------------- |
| EC2     | AmazonEC2FullAccess |
| S3      | AmazonS3FullAccess  |
| ECR     | AmazonECRFullAccess |

If not available — contact `artemkapset@gmail.com` or `mamkindevops@gmail.com`.

Export credentials:

```bash
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

Or use `~/.aws/credentials` file:

```
[default]
aws_access_key_id = your-key
aws_secret_access_key = your-secret
```

Check access:

```bash
aws sts get-caller-identity
```

---

## 6. Project Structure (Multi-Environment)

The project is fully modularized and supports multiple environments:

```
terraform/
├── infra_bootstrap/         # S3 bucket & backend init
├── modules/                 # All reusable infrastructure modules
│   └── app_infra/           # Full application stack module
├── environments/
│   ├── dev/                 # Development environment
│   └── prod/                # Production environment
```

Each environment contains:

- its own `main.tf`, `variables.tf`, `terraform.tfvars`, `backend.tf`
- state stored separately in S3
- all names and resources isolated by `var.environment`

---

## 7. CI/CD: Infrastructure Deployments

GitHub Actions is used to validate and deploy infrastructure:

| Trigger                 | Action                        | Environment    |
| ----------------------- | ----------------------------- | -------------- |
| `pull_request` → `main` | `terraform validate` + `plan` | `dev`          |
| `push` → `main`         | `terraform apply` (auto)      | `dev`          |
| `workflow_dispatch`     | Manual `apply`                | `dev` / `prod` |

> Production infrastructure is protected. It can only be deployed **manually via GitHub Actions UI** and requires approval via GitHub Environments.

---

## 8. Contribution Flow

1. Work in `main` branch for `dev` changes
2. Confirm infrastructure behaves correctly in `dev`
3. Merge into `prod` branch
4. Run `Terraform CI/CD` workflow manually with `env: prod` to deploy approved code to production

---

Make sure CI checks pass ✅
