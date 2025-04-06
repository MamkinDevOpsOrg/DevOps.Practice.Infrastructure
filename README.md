# DevOps Learning Projects

This repository contains projects and examples for learning DevOps technologies and tools through hands-on practice.  
It includes practical tasks using Terraform, cloud infrastructure (AWS), automation, and other DevOps-related concepts.

Below you can find onboarding guide.

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

If you haven’t set up SSH access yet then generate ssh keys

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

---

Add your public key (~/.ssh/id_ed25519.pub) to GitHub: `GitHub → Profile → Settings → SSH and GPG Keys → New SSH Key`

Test your access:

```bash
ssh -T git@github.com
```

## 3. Clone the Repository and Create a Branch

```bash
git clone git@github.com:MamkinDevOpsOrg/DevOps.Practice.Infrastructure.git
cd ./DevOps.Practice.Infrastructure
git checkout -b devops/your-name/first-task
```

## 4. Install Required Tools

Make sure the following are installed on your local machine:

- Terraform (https://developer.hashicorp.com/terraform/install)

- AWS CLI (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## 4.1 Install Ansible (Optional for Local Provisioning)

> This step is optional. Ansible is used for configuring EC2 instances (e.g., install Docker, AWS CLI) after provisioning.

If you run **Linux or WSL**, you can install Ansible directly:

```bash
sudo apt update && sudo apt install ansible
```

For detailed instructions, see [`ansible/README.md`](./ansible/README.md)

## 5. Configure AWS Credentials

You need an IAM user with the following minimum permissions:

| Service | Permissions         |
| ------- | ------------------- |
| EC2     | AmazonEC2FullAccess |
| S3      | AmazonS3FullAccess  |
| ECR     | AmazonECRFullAccess |

If you don't have IAM user with the permissions above, ask your AWS admin (artemkapset@gmail.com or mamkindevops@gmail.com) to grant you required accesses (Organization ID: o-ziokp90k5r - for reference only).

Export your IAM credentials:

```bash
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

For Windows it's better to create `~/.aws/credentials` file with the following content:

```
[default]
aws_access_key_id = your-key
aws_secret_access_key = your-secret
```

Check access:

```bash
aws sts get-caller-identity
```

## 6. Make a Change and Open a Pull Request

Navigate to the main infrastructure project `cd terraform/main_project` and make the changes and/or updates you need.

After making changes perform:

```bash
terraform fmt
terraform validate
terraform plan
```

and then if you are happy with results:

```bash
git add .
git commit -m "your message"
git push origin devops/your-name/first-task
```

Then:

- Go to GitHub

- Open a Pull Request into the main branch

- GitHub Actions will automatically run:

  - `terraform validate`
  - `terraform plan` and post result as a comment to your Pull Request

terraform plan and post result as a comment

Make sure the checks pass ✅
