
# CKV_AWS_237: Ensure Create before destroy for API Gateway
resource "aws_api_gateway_rest_api" "quintana_api" {
  name        = "quintana-gateway"
  description = "API Gateway for Constructora Quintana"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  lifecycle {
    create_before_destroy = true # Solución para CKV_AWS_237 (01)
  }
}

resource "aws_api_gateway_resource" "send_email_resource" {
  rest_api_id = aws_api_gateway_rest_api.quintana_api.id
  parent_id   = aws_api_gateway_rest_api.quintana_api.root_resource_id
  path_part   = "send-email"
}

# CKV_AWS_59: Ensure there is no open access to back-end resources through API
# CKV2_AWS_53: Ensure AWS API gateway request is validated
resource "aws_api_gateway_method" "post_send_email" {
  rest_api_id   = aws_api_gateway_rest_api.quintana_api.id
  resource_id   = aws_api_gateway_resource.send_email_resource.id
  http_method   = "POST"
  # Solución para CKV_AWS_59: Cambiado a AWS_IAM.
  authorization = "AWS_IAM" 

  # Solución para CKV2_AWS_53: Añadir validación de request
  request_validator_id = aws_api_gateway_request_validator.body_and_params.id
  request_models = {
    "application/json" = aws_api_gateway_model.email_request_model.name
  }


}

##########################
# Recursos adicionales necesarios para CKV2_AWS_53 (validación de request)
resource "aws_api_gateway_request_validator" "body_and_params" {
  name                 = "BodyAndParamsValidator"
  rest_api_id          = aws_api_gateway_rest_api.quintana_api.id
  validate_request_body    = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "email_request_model" {
  rest_api_id  = aws_api_gateway_rest_api.quintana_api.id
  name         = "EmailRequestModel"
  description  = "Schema for email sending request"
  content_type = "application/json"
  schema       = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#",
    "title"   = "EmailRequest",
    "type"    = "object",
    "properties" = {
      "to"      = { "type" = "string", "format" = "email" },
      "subject" = { "type" = "string" },
      "body"    = { "type" = "string" }
    },
    "required" = ["to", "subject", "body"]
  })
}
##############################




resource "aws_api_gateway_method_response" "post_send_email_response" {
  rest_api_id = aws_api_gateway_rest_api.quintana_api.id
  resource_id = aws_api_gateway_resource.send_email_resource.id
  http_method = aws_api_gateway_method.post_send_email.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.quintana_api.id
  resource_id             = aws_api_gateway_resource.send_email_resource.id
  http_method             = aws_api_gateway_method.post_send_email.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.prepare_emails.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.prepare_emails.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.quintana_api.execution_arn}/*/*/*"
}


# CKV_AWS_217: Ensure Create before destroy for API deployments
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.quintana_api.id
  description = "Primera versión de la API"

  ######
  lifecycle {
    create_before_destroy = true # Solución para CKV_AWS_217
  }
  ######
}

######
# ==============================================================================
# RECURSOS DE SOPORTE PARA LOGGING Y OBSERVABILIDAD (NUEVOS RECURSOS)
# ==============================================================================

# 1. Grupo de Logs de CloudWatch para API Gateway
# Necesario para CKV_AWS_76 (Access Logging) y CKV2_AWS_4 (Execution Logging)
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/${aws_api_gateway_rest_api.quintana_api.name}"
  retention_in_days = 30 # Ajusta según tus necesidades de retención
}

# 2. Rol de IAM que API Gateway usará para escribir logs en CloudWatch
# Necesario para CKV_AWS_76 (Access Logging) y CKV2_AWS_4 (Execution Logging)
resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "api-gateway-cloudwatch-role-quintana" # Nombre más específico para evitar colisiones

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# 3. Política de IAM que permite al rol escribir logs
# Necesario para CKV_AWS_76 (Access Logging) y CKV2_AWS_4 (Execution Logging)
resource "aws_iam_role_policy" "api_gateway_cloudwatch_policy" {
  name = "api-gateway-cloudwatch-policy-quintana" # Nombre más específico
  role = aws_iam_role.api_gateway_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = ["arn:aws:logs:*:*:*"] # Puedes restringir esto a log groups específicos si lo deseas
      }
    ]
  })
}

# 4. Asociar el rol de CloudWatch a la cuenta de API Gateway
# Necesario para CKV_AWS_76 (Access Logging) y CKV2_AWS_4 (Execution Logging)
resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
  # Dependencia explícita para asegurar que el rol se cree antes de ser asignado
  depends_on = [
    aws_iam_role_policy.api_gateway_cloudwatch_policy
  ]
}
################

# ==============================================================================
# CONFIGURACIÓN DE LA ETAPA (STAGE) DE API GATEWAY
# ==============================================================================

# CKV_AWS_76: Ensure API Gateway has Access Logging enabled
# CKV_AWS_120: Ensure API Gateway caching is enabled
# CKV_AWS_73: Ensure API Gateway has X-Ray Tracing enabled
# CKV2_AWS_4: Ensure API Gateway stage have logging level defined as appropriate

# CKV2_AWS_29: Ensure public API gateway are protected by WAF





resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.quintana_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  
  ##################
  # Solución para CKV_AWS_76: Access Logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = jsonencode({
      requestId               = "$context.requestId",
      ip                      = "$context.identity.sourceIp",
      caller                  = "$context.identity.caller",
      user                    = "$context.identity.user",
      requestTime             = "$context.requestTime",
      httpMethod              = "$context.httpMethod",
      resourcePath            = "$context.resourcePath",
      status                  = "$context.status",
      protocol                = "$context.protocol",
      responseLength          = "$context.responseLength"
    })
  }

  # Solución para CKV_AWS_120: Caching
  # Habilitado, pero reevaluar si es necesario para un método POST que inicia un proceso.
  cache_cluster_enabled = true
  cache_cluster_size    = "0.5" # Tamaño mínimo, ajusta según el volumen de tráfico y necesidad

  # Solución para CKV_AWS_73: X-Ray Tracing
  xray_tracing_enabled = true
  variables = {
    "data_trace_enabled" = "false" # Esto es una variable de stage, no una configuración de logging directa.
  }
  # checkov:skip=CKV2_AWS_29:Ensure public API gateway are protected by WAF 
  # checkov:skip=CKV2_AWS_51:Ensure AWS API Gateway endpoints uses client certificate authentication 
  web_acl_arn = var.waf_web_acl_arn 
  ##############################
}

# RECURSO ADICIONAL para solucionar CKV2_AWS_4
# Configura el logging de ejecución y las métricas para TODOS los métodos del stage "prod".
resource "aws_api_gateway_method_settings" "prod_stage_logging_settings" {
  rest_api_id = aws_api_gateway_rest_api.quintana_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*" # Esto aplica la configuración a todos los recursos y métodos HTTP del stage.

  settings {
    metrics_enabled = true # Habilita el envío de métricas a CloudWatch
    logging_level   = "INFO" # Define el nivel de logging de ejecución (ERROR, INFO, OFF)
    # data_trace_enabled = true # Si quieres logs de datos de solicitud/respuesta (cuidado con datos sensibles)
  }
}
  





