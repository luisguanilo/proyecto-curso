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

    # CKV_AWS_111: Ensure IAM policies does not allow write access without constraints
    # CKV_AWS_356: No "*" as a statement's resource
    resources = [
      "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:identity/${var.sender_email}"
    ]

    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [var.sender_email]
    }
  }

  # añadir politicas para cloudwatch
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    # CKV_AWS_111/356 for CloudWatch Logs: restringir recurso
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/send_emails:*"
      ]
  }
}

resource "aws_iam_role_policy" "lambda_send_emails_policy_attach" {
  name   = "lambda_send_emails_policy"
  role   = aws_iam_role.lambda_send_emails_role.id
  policy = data.aws_iam_policy_document.lambda_send_emails_policy.json
}

###########################
# Dead-Letter Queue (DLQ)
###########################
resource "aws_sqs_queue" "send_emails_dlq" {
  name              = "send-emails-dlq"
  #kms_master_key_id = aws_kms_key.sqs.arn
}

############################
# KMS Key for Lambda Envs
############################
# (Reutiliza la misma CMK o crea una distinta si prefieres)
#resource "aws_kms_key" "lambda_env_send" {
#  description             = "CMK para cifrar variables de entorno de send_emails"
#  deletion_window_in_days = 30
#}

###################################
# Code Signing Configuration
###################################
#resource "aws_lambda_code_signing_config" "sign_send" {
#  allowed_publishers {
#    signing_profile_version_arns = [
#      aws_signer_signing_profile.profile.arn
#    ]
#  }
#}







resource "aws_lambda_function" "send_emails" {
  # checkov:skip=CKV_AWS_117 "Lambda no desplegada en VPC"
  function_name = "send-emails"
  role          = aws_iam_role.lambda_send_emails_role.arn
  runtime       = "python3.9"
  handler       = "send_emails.lambda_handler"

  filename         = "${path.module}/codes/send_emails.zip"
  source_code_hash = filebase64sha256("${path.module}/codes/send_emails.zip")

  memory_size   = 200 
  timeout       = 30
  publish       = true

  # CKV_AWS_116: Dead Letter Queue configurada
  dead_letter_config {
    target_arn = aws_sqs_queue.send_emails_dlq.arn
  }

  # CKV_AWS_50: X-Ray tracing habilitado
  tracing_config {
    mode = "Active"
  }

  # CKV_AWS_115: Límite de concurrencia reservado
  reserved_concurrent_executions = 5

  # CKV_AWS_272: Code signing configurado
  #code_signing_config_arn = aws_lambda_code_signing_config.sign_send.arn

  # CKV_AWS_173: Cifrado de variables de entorno
  #kms_key_arn = aws_kms_key.lambda_env_send.arn

  ################

  environment {
    variables = {
      FROM_EMAIL   = var.sender_email
      SQS_QUEUE_URL = aws_sqs_queue.email_queue.url
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Recurso para Balanceo de trabajo en el envio de archivos, con un lote de envio de 10, activado
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.email_queue.arn
  function_name    = aws_lambda_function.send_emails.arn
  batch_size       = 10
  enabled          = true
}