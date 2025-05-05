resource "aws_api_gateway_rest_api" "quintana_api" {
  name        = "quintana-gateway"
  description = "API Gateway for Constructora Quintana"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "send_email_resource" {
  rest_api_id = aws_api_gateway_rest_api.quintana_api.id
  parent_id   = aws_api_gateway_rest_api.quintana_api.root_resource_id
  path_part   = "send-email"
}

resource "aws_api_gateway_method" "post_send_email" {
  rest_api_id   = aws_api_gateway_rest_api.quintana_api.id
  resource_id   = aws_api_gateway_resource.send_email_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

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

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.quintana_api.id
  description = "Primera versión de la API"
}

resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.quintana_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}