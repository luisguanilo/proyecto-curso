output "s3_bucket_name" {
  value = aws_s3_bucket.email_templates.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.clients.name
}

output "sqs_queue_url" {
  value = aws_sqs_queue.email_queue.url
}

output "sender_email" {
  value = var.sender_email
}