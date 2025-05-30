# Как создать S3-бакет для ALB Access Logs с поддержкой ACL и общим префиксом

Эта инструкция создаёт S3-бакет для хранения access-логов ALB, поддерживает переиспользование и задаёт гибкий префикс (`app1-prod`, `dev-alb`, и т.п.). Полностью совместима с Terraform и AWS требованиями.

---

### ✅ Шаг 1: Задать имя бакета и префикс

```bash
BUCKET_NAME="alb-access-logs-storage-for-mamkindevops-production"
LOG_PREFIX="app1-prod" # можно заменить на dev, prod, app2, test и т.д.
```

---

### ✅ Шаг 2: Создать S3-бакет в регионе us-east-1

```bash
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region us-east-1
```

📌 В `us-east-1` не указываем `--create-bucket-configuration` — это особенность региона.

---

### ❓ Почему в us-east-1 не указываем `--create-bucket-configuration` и что делать в других регионах

Когда создаёшь S3-бакет, поведение AWS зависит от региона:

- В `us-east-1` (Вирджиния) **нельзя указывать** `--create-bucket-configuration`.  
  ✅ Пример корректной команды:

```bash
aws s3api create-bucket \
  --bucket my-bucket \
  --region us-east-1
```

- Во **всех остальных регионах** (например, `us-west-2`, `eu-central-1`) **обязательно нужно указывать** `LocationConstraint`, иначе будет ошибка.  
  ✅ Пример:

```bash
aws s3api create-bucket \
  --bucket my-bucket \
  --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2
```

🧠 Это связано с тем, что `us-east-1` — исторически особый регион, и AWS ожидает иное поведение от API.

---

### 🔁 Пример условной логики в bash-скрипте (для автоматизации):

```bash
if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION"
else
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"
fi
```

📦 Это позволяет безопасно создавать бакет в любом регионе.

---

### ✅ Шаг 3: Изменить режим владения на BucketOwnerPreferred, включить ACL и дать права LogDelivery

```bash
aws s3api put-bucket-ownership-controls \
  --bucket alb-access-logs-storage-for-mamkindevops-production \
  --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerPreferred}]' \
  --region us-east-1
```

```bash
aws s3api put-bucket-acl \
  --bucket "$BUCKET_NAME" \
  --grant-write 'URI="http://acs.amazonaws.com/groups/s3/LogDelivery"' \
  --grant-read-acp 'URI="http://acs.amazonaws.com/groups/s3/LogDelivery"' \
  --region us-east-1
```

🔐 Без этого ALB не сможет писать логи в бакет, даже при наличии policy.

---

### ✅ Шаг 4: Создать bucket policy с гибким путём

Создай `bucket-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSALBLogsWriteAccess",
      "Effect": "Allow",
      "Principal": {
        "Service": "logdelivery.elasticloadbalancing.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::alb-access-logs-storage-for-mamkindevops-production/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Sid": "AWSALBLogsGetAcl",
      "Effect": "Allow",
      "Principal": {
        "Service": "logdelivery.elasticloadbalancing.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::alb-access-logs-storage-for-mamkindevops-production"
    }
  ]
}
```

📌 Мы разрешаем всё пространство `/*`, чтобы использовать любые префиксы (`app1-prod`, `dev`, `staging` и т.д.)

---

### ✅ Шаг 5: Применить bucket policy

```bash
aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --policy file://bucket-policy.json \
  --region us-east-1
```

---

### ✅ Шаг 6: Настройка в Terraform

В `terraform/environments/prod/variables.tf`:

```hcl
variable "access_log_bucket" {
  default = "alb-access-logs-storage-for-mamkindevops-production"
}

variable "access_log_prefix" {
  default = "app1-prod"
}
```

В модуле ALB:

```hcl
access_logs = {
  bucket  = var.access_log_bucket
  prefix  = var.access_log_prefix
  enabled = true
}
```

---

### 🧠 Что ты получаешь:

| Возможность                                 | Благодаря чему                               |
| ------------------------------------------- | -------------------------------------------- |
| Использовать один бакет для многих ALB      | `prefix = ...`, `Resource = /*`              |
| Совместимость с ALB                         | ACL + `x-amz-acl: bucket-owner-full-control` |
| Безопасность через GetBucketAcl + Condition | Bucket policy                                |
| Без ошибок AccessDenied                     | ACL, policy, права LogDelivery               |
