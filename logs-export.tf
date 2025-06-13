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

# añadido para exportar los logs al s3
#resource "null_resource" "export_logs" {
  #provisioner "local-exec" {
    #command = "cmd /C powershell -Command \"& { C:\\Program Files\\Amazon\\AWSCLIV2\\aws.exe logs create-export-task --log-group-name /aws/lambda/prepare_emails --from (Get-Date).AddHours(-1).ToUniversalTime().ToFileTime() / 10000 --to (Get-Date).ToUniversalTime().ToFileTime() / 10000 --destination 'quintana-lambda-logs' --destination-prefix 'exported-logs/prepare' --role-name 'cloudwatch_logs_export_role' }\""
  #}

  #depends_on = [aws_iam_role.cloudwatch_to_s3, aws_s3_bucket.logs_bucket]
#}


# añadido posteriormente
resource "null_resource" "export_logs" {
  provisioner "local-exec" {
    command = <<-EOT
      powershell -Command "\$from = [int]([System.DateTime]::UtcNow.AddHours(-1) - [System.DateTime]::UnixEpoch).TotalSeconds * 1000; 
      \$to = [int]([System.DateTime]::UtcNow - [System.DateTime]::UnixEpoch).TotalSeconds * 1000;
      & 'C:\\Program Files\\Amazon\\AWSCLIV2\\aws.exe' logs create-export-task --log-group-name /aws/lambda/prepare_emails --from \$from --to \$to --destination 'quintana-lambda-logs' --destination-prefix 'exported-logs/prepare' --role-arn 'arn:aws:iam::322957919239:role/cloudwatch_logs_export_role'"
    EOT
  }

  depends_on = [
    aws_iam_role.cloudwatch_to_s3,
    aws_s3_bucket.logs_bucket
  ]
}
