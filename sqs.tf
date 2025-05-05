resource "aws_sqs_queue" "email_queue" {
  name                        = var.sqs_queue_name
  visibility_timeout_seconds   = 30
  message_retention_seconds    = 900
  max_message_size             = 51200
  delay_seconds                = 0
}