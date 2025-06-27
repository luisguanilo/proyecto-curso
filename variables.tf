variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS CLI Profile"
  default     = "proyecto_quintana"
}

variable "email_templates_bucket" {
  description = "S3 Bucket for Email Templates"
  default     = "email-templates-quintana"
}

variable "clients_table_name" {
  description = "DynamoDB Table Name"
  default     = "clients"
}

variable "sender_email" {
  description = "Email address for sending emails"
  default     = "guanilo99@gmail.com"
}

variable "sqs_queue_name" {
  description = "SQS Queue Name"
  default     = "email-queue"
}


#######################
# AÑADE ESTA NUEVA VARIABLE
variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL to associate with the API Gateway stage. Defaults to empty if no WAF is used."
  type        = string
  default     = "" # Añade este default aquí
}

variable "lambda_security_group_ids" {
  description = "Lista de Security Group IDs asignados a la Lambda"
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "Lista de subnets privadas donde se desplegará la Lambda"
  type        = list(string)
  default     = []
}
