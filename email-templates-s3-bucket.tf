resource "aws_s3_bucket" "email_templates" {
  bucket = var.email_templates_bucket
  force_destroy = true

  tags = {
    Purpose = "Email Templates"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.email_templates.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.email_templates.id
  key          = "first-template/index.html"
  source       = "${path.module}/templates/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "style_css" {
  bucket       = aws_s3_bucket.email_templates.id
  key          = "first-template/style.css"
  source       = "${path.module}/templates/styles.css"
  content_type = "text/css"
}