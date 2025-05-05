resource "aws_iam_role" "lambda_prepare_emails_role" {
  name = "lambda_prepare_emails_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy_document" "lambda_prepare_emails_policy" {
  statement {
    sid    = "DynamoDBReadAccess"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:DescribeTable"
    ]

    resources = [
      aws_dynamodb_table.clients.arn
    ]
  }

  statement {
    sid    = "S3ReadTemplates"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.email_templates.arn,
      "${aws_s3_bucket.email_templates.arn}/*"
    ]
  }

  statement {
    sid    = "SQSSendMessages"
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [
      aws_sqs_queue.email_queue.arn
    ]
  }
}

resource "aws_iam_role_policy" "lambda_prepare_emails_policy_attach" {
  name   = "lambda_s3_dynamo_read"
  role   = aws_iam_role.lambda_prepare_emails_role.id
  policy = data.aws_iam_policy_document.lambda_prepare_emails_policy.json
}

resource "aws_lambda_function" "prepare_emails" {
  function_name = "prepare_emails"
  role          = aws_iam_role.lambda_prepare_emails_role.arn
  runtime       = "python3.9"
  handler       = "prepare_emails.lambda_handler"

  filename         = "${path.module}/codes/prepare_emails.zip"
  source_code_hash = filebase64sha256("${path.module}/codes/prepare_emails.zip")

  memory_size = 200
  timeout     = 10
  publish     = true

  environment {
    variables = {
      S3_BUCKET_NAME      = aws_s3_bucket.email_templates.bucket
      DYNAMODB_TABLE_NAME = var.clients_table_name
      SQS_QUEUE_URL       = aws_sqs_queue.email_queue.url
    }
  }
}