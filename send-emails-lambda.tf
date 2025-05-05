resource "aws_iam_role" "lambda_send_emails_role" {
  name = "lambda_send_emails_role"

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

data "aws_iam_policy_document" "lambda_send_emails_policy" {
  statement {
    sid    = "AllowSQSReceive"
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [aws_sqs_queue.email_queue.arn]
  }

  statement {
    sid    = "AllowSESSend"
    effect = "Allow"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [var.sender_email]
    }
  }
}

resource "aws_iam_role_policy" "lambda_send_emails_policy_attach" {
  name   = "lambda_send_emails_policy"
  role   = aws_iam_role.lambda_send_emails_role.id
  policy = data.aws_iam_policy_document.lambda_send_emails_policy.json
}

resource "aws_lambda_function" "send_emails" {
  function_name = "send-emails"
  role          = aws_iam_role.lambda_send_emails_role.arn
  runtime       = "python3.9"
  handler       = "send_emails.lambda_handler"

  filename         = "${path.module}/codes/send_emails.zip"
  source_code_hash = filebase64sha256("${path.module}/codes/send_emails.zip")

  memory_size   = 200 
  timeout       = 30
  publish       = true

  environment {
    variables = {
      FROM_EMAIL   = var.sender_email
      SQS_QUEUE_URL = aws_sqs_queue.email_queue.url
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.email_queue.arn
  function_name    = aws_lambda_function.send_emails.arn
  batch_size       = 10
  enabled          = true
}