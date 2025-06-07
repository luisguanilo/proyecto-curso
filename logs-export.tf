resource "aws_s3_bucket" "logs_bucket" {
  bucket        = "quintana-lambda-logs"
  force_destroy = true

  tags = {
    Purpose = "Lambda Logs Export"
  }
}

resource "aws_s3_bucket_public_access_block" "logs_block" {
  bucket = aws_s3_bucket.logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "cloudwatch_to_s3" {
  name = "cloudwatch_logs_export_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "logs.${var.aws_region}.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudwatch_export_policy" {
  name   = "logs_export_to_s3"
  role   = aws_iam_role.cloudwatch_to_s3.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:PutObject",
        "s3:GetBucketLocation"
      ],
      Resource = "${aws_s3_bucket.logs_bucket.arn}/*"
    }]
  })
}

resource "null_resource" "export_logs" {
  provisioner "local-exec" {
    command = <<EOT
    aws logs create-export-task \
      --log-group-name /aws/lambda/prepare_emails \
      --from $(date -u -d '1 hour ago' +%s)000 \
      --to $(date -u +%s)000 \
      --destination ${aws_s3_bucket.logs_bucket.id} \
      --destination-prefix exported-logs/prepare \
      --role-name cloudwatch_logs_export_role
    EOT
  }

  depends_on = [aws_iam_role.cloudwatch_to_s3, aws_s3_bucket.logs_bucket]
}