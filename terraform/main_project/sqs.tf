resource "aws_sqs_queue" "analytics_events" {
  name                       = "analytics-events-queue"
  message_retention_seconds  = 3600
  visibility_timeout_seconds = 60
  receive_wait_time_seconds  = 10
  tags = {
    Environment = "dev"
    Project     = "analytics"
  }
}