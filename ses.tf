resource "aws_ses_email_identity" "sender_email" {
  email = var.sender_email
}