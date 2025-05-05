variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS CLI Profile"
  default     = "proyecto_quintana"
}

variable "email_templates_bucket" {
  description = "S3 Bucket for Email Templates"
  default     = "email-templates-quintana"
}

variable "clients_table_name" {
  description = "DynamoDB Table Name"
  default     = "clients"
}

variable "sender_email" {
  description = "Email address for sending emails"
  default     = "guanilo99@gmail.com"
}

variable "sqs_queue_name" {
  description = "SQS Queue Name"
  default     = "email-queue"
}