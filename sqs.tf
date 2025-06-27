resource "aws_sqs_queue" "email_queue" {
  name                        = var.sqs_queue_name
  visibility_timeout_seconds   = 30
  message_retention_seconds    = 900
  max_message_size             = 51200
  delay_seconds                = 0
  # CKV_AWS_27	Cola SQS no encriptada
  #kms_master_key_id           = aws_kms_key.sqs.arn
  #
}
####
#resource "aws_kms_key" "sqs" {
#  description             = "CMK para cifrar la cola SQS email_queue"
#  deletion_window_in_days = 30
#}
####