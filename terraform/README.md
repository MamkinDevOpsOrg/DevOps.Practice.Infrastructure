# Terraform AWS Infrastructure (Multi-Environment)

This project manages AWS infrastructure using Terraform across multiple isolated environments (`dev`, `prod`) with strict version control and CI/CD via GitHub Actions.

---

## Features

- Fully modularized infrastructure (`terraform/modules`)
- Dedicated environments: `terraform/environments/dev` and `prod`
- Remote state stored in S3 per environment
- CI/CD via GitHub Actions:
  - `terraform-plan.yml`: validation and plan (on PR or manually)
  - `terraform-apply.yml`: manual apply with flexible image tag resolution
- Controlled deployment via Git tags
- Safe manual promotion from `dev` to `prod`
- ECS Fargate integration with ALB and Docker image tag management via AWS SSM

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
terraform apply -var="image_tag=v1.0.1"
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

- Triggered manually via **workflow_dispatch**
- Deploys selected infrastructure version and Docker image
- Inputs:
  - `env`: `dev` or `prod`
  - `infra_version`: Git branch or tag to deploy from
  - `image_tag`:
    - optional for `dev` — auto-resolves from SSM if omitted
    - required for `prod` — validated against ECR
- Verifies Git tag existence (for `prod`)
- Verifies ECR image existence (for `prod`)
- Passes `image_tag` into Terraform as `TF_VAR_image_tag`

---

## Versioning Strategy

- Changes are merged to `main`
- Optionally tested on `dev` via manual apply using branch or SSM tag
- Once stable, create tag:

```bash
git checkout main
git pull origin main
git tag v1.0.1-infra
git push origin v1.0.1-infra
```

- Run `terraform-apply.yml` with:
  - `env: dev`, `infra_version: main`, `image_tag: optional`
  - then `env: prod`, `infra_version: v1.0.1-infra`, `image_tag: v1.0.1`

Rollback? Just redeploy a previous version:

```
env: prod
infra_version: v1.0.0-infra
image_tag: v1.0.0
```

---

## 🔀 How to promote a specific version tag (e.g. `v1.0.0`) from `main` to `prod`

Sometimes you want to merge a specific version (tag) to `prod`, without bringing all newer changes from `main`. Here's how to safely do it:

### 1. Switch to the `prod` branch

```bash
git checkout prod
git pull origin prod  # make sure your local branch is up-to-date
```

---

### 2. Merge the **tag**, not the whole `main` branch

```bash
git merge v1.0.0-infra
```

---

### 3. Resolve conflicts if any (there shouldn't be any if `prod` is behind)

---

### 4. Push the changes to remote `prod` branch

```bash
git push origin prod
```

---

✅ Now `prod` contains exactly the version `v1.0.0-infra` you tested. You can safely deploy it via `terraform-apply.yml` with:

```
env: prod
infra_version: v1.0.0-infra
image_tag: v1.0.0
```

---

## Notes

- Direct auto-apply on `push` is disabled
- Production deployments require manual approval + image version
- `main` branch is used as staging for `dev`, `prod` is protected
- Docker tag resolution is automatic for `dev` via AWS SSM
