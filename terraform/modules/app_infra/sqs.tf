resource "aws_sqs_queue" "analytics_events" {
  name = "analytics-events-queue-${var.environment}"

  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400

  tags = {
    Name        = "analytics-events-${var.environment}"
    Environment = var.environment
  }
}
