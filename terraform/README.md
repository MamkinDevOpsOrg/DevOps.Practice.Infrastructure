# Terraform AWS Infrastructure (Multi-Environment)

This project manages AWS infrastructure using Terraform across multiple isolated environments (`dev`, `prod`) with strict version control and CI/CD via GitHub Actions.

---

## Features

- Fully modularized infrastructure (`terraform/modules`)
- Dedicated environments: `terraform/environments/dev` and `prod`
- Remote state stored in S3 per environment
- CI/CD via **two separate GitHub Actions**:
  - `terraform-plan.yml`: validation and plan (on PR or manually)
  - `terraform-apply.yml`: apply infrastructure (manual, by version)
- Controlled deployment via Git tags (e.g. `v1.0.2`)
- Safe manual promotion from `dev` to `prod`
- Reproducible and rollback-friendly versioning

---

## Structure

```
terraform/
├── infra_bootstrap/         # One-time S3 + backend setup
├── modules/                 # Reusable modules
│   └── app_infra/
├── environments/
│   ├── dev/
│   └── prod/
```

---

## Usage

### 1. Bootstrap: create S3 bucket for remote state

```bash
cd terraform/infra_bootstrap
terraform init
terraform apply
```

---

### 2. Manual deployment (local)

```bash
cd terraform/environments/dev         # or prod
terraform init
terraform plan
terraform apply
```

Override variables (e.g. secrets):

```bash
export TF_VAR_analytics_db_password=your_password
```

---

### 3. Destroy environment (if needed)

```bash
cd terraform/environments/dev
./pre_destroy_cleanup.sh   # Optional: cleanup NAT/EIP
terraform destroy
```

---

## CI/CD via GitHub Actions

### 🔍 `terraform-plan.yml`

- Runs automatically on PR to `main` or `prod`
- Can be triggered manually with selected `ref` (`main`, `feature/foo`, `v1.0.2`)
- Posts Terraform plan as comment in PR

### 🚀 `terraform-apply.yml`

- Triggered manually only via **workflow_dispatch**
- Deploys selected version to target environment (`dev` or `prod`)
- Requires Git **tag** for `prod` (e.g. `v1.0.1`)
- Verifies that tag exists in the remote repo before applying

---

## Versioning Strategy

- Changes are merged to `main`
- Optionally tested on `dev` via manual apply using branch name
- Once stable, create tag:

  ```bash
  git checkout main # or prod
  git pull origin main
  git tag v1.0.1
  git push origin v1.0.1
  ```

- Run `terraform-apply.yml` with:
  - `env: dev`, `version_tag: v1.0.1` → deploy to dev
  - then `env: prod`, `version_tag: v1.0.1` → deploy to prod (from `prod` branch only)

Rollback? Just redeploy a previous version:

```text
env: prod
version_tag: v1.0.0
```

---

## Notes

- Direct auto-apply on `push` is disabled
- Production deployments require manual approval + version tag
- `main` branch is used as staging for `dev`, `prod` is protected
