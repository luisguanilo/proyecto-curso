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

  #añadido para politica en cloudwatch
  # CKV_AWS_111: Ensure IAM policies does not allow write access without constraints
  # Aquí restringimos cada write a su recurso concreto
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    # CKV_AWS_356: restringir resources en lugar de "*"
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/prepare_emails:*"
      ]
  }

}

resource "aws_iam_role_policy" "lambda_prepare_emails_policy_attach" {
  name   = "lambda_s3_dynamo_read"
  role   = aws_iam_role.lambda_prepare_emails_role.id
  policy = data.aws_iam_policy_document.lambda_prepare_emails_policy.json
}

###########################
# Dead-Letter Queue (DLQ)
###########################
resource "aws_sqs_queue" "lambda_dlq" {
  name              = "prepare-emails-dlq"
  #kms_master_key_id = aws_kms_key.sqs.arn
}

############################
# KMS Key for Lambda Envs
############################
#resource "aws_kms_key" "lambda_env" {
#  description             = "CMK para cifrar variables de entorno de prepare_emails"
#  deletion_window_in_days = 30
#}



# checkov:skip=CKV_AWS_117 "Lambda no desplegada en VPC"
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

  # CKV_AWS_116: Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  # CKV_AWS_117: Ensure that AWS Lambda function is configured inside a VPC
 

  # CKV_AWS_50: Ensure X-Ray tracing is enabled for Lambda
  tracing_config {
    mode = "Active"
  }

  # CKV_AWS_115: Ensure that AWS Lambda function is configured for function-level concurrent execution limit
  reserved_concurrent_executions = 5

  # CKV_AWS_272: Ensure AWS Lambda function is configured to validate code-signing
  #code_signing_config_arn = aws_lambda_code_signing_config.sign.arn

  # CKV_AWS_173: Check encryption settings for Lambda environmental variable
    #kms_key_arn = aws_kms_key.lambda_env.arn



  environment {
    variables = {
      S3_BUCKET_NAME      = aws_s3_bucket.email_templates.bucket
      DYNAMODB_TABLE_NAME = var.clients_table_name
      SQS_QUEUE_URL       = aws_sqs_queue.email_queue.url
    }
    
    # (Opcional) para orden de destrucción/creación
  #lifecycle {
    #create_before_destroy = true
  #}




  }
}

##############################
# Caller Identity (para ARNs)
##############################
data "aws_caller_identity" "current" {}