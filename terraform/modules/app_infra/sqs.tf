resource "aws_sqs_queue" "analytics_events" {
  name = "analytics-events-queue"

  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400

  tags = {
    Name        = "analytics-events"
    Environment = var.environment
  }
}
