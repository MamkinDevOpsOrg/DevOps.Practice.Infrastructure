# Terraform AWS Infrastructure (Multi-Environment)

This project manages cloud infrastructure using Terraform across multiple isolated environments (`dev`, `prod`), following best practices of infrastructure-as-code.

---

## Features

- Fully modularized structure using reusable modules (e.g. `app_infra`)
- Dedicated environment folders: `terraform/environments/dev` and `terraform/environments/prod`
- Remote state stored in S3 per environment
- Support for CI/CD via GitHub Actions
- Isolation between `dev` and `prod`: names, state, configuration

---

## Structure

```
terraform/
├── infra_bootstrap/         # One-time S3 + backend setup
├── modules/
│   └── app_infra/           # Main app infrastructure module
├── environments/
│   ├── dev/
│   └── prod/
```

---

## Usage

### 1. Bootstrap: Create S3 bucket for remote state

```bash
cd terraform/infra_bootstrap
terraform init
terraform apply
```

---

### 2. Deploy environment (`dev` or `prod`)

```bash
cd terraform/environments/dev         # or prod
terraform init                        # Initializes with backend
terraform fmt
terraform validate
terraform plan
terraform apply
```

You can override secrets (e.g. DB password) via:

```bash
export TF_VAR_analytics_db_password=your_password
```

---

### 3. Destroy resources

```bash
cd terraform/environments/dev
./pre_destroy_cleanup.sh   # Optional: cleanup EIP / NAT resources
terraform destroy
```

---

## CI/CD (GitHub Actions)

Terraform is automatically validated and applied:

- PR to `main` → runs `plan` for `dev`
- Push to `main` → applies to `dev`
- Manual trigger → applies to `dev` or `prod` (with approval for prod)
