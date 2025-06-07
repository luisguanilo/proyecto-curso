import json
import boto3
import os
import logging #añadido segunda unidad

# Porcion de codigo para el desarrollo de logs - segunda unidad
# Configuración básica de logs
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def log_structured(level, message, context=None, extra=None):
    log_entry = {
        "level": level,
        "message": message,
        "function": "prepare_emails",
        "context": {
            "request_id": context.aws_request_id if context else None
        }
    }
    if extra:
        log_entry.update(extra)
    logger.info(json.dumps(log_entry))

# Final de esta parte de codigo, en adelante es codigo de primera unidad




# Clientes de AWS
dynamodb = boto3.client('dynamodb')
s3 = boto3.client('s3')
sqs = boto3.client('sqs')

# Variables de entorno desde Terraform
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE_NAME']
S3_BUCKET = os.environ['S3_BUCKET_NAME']
SQS_QUEUE_URL = os.environ['SQS_QUEUE_URL']
TEMPLATE_PREFIX = "first-template/"

def lambda_handler(event, context):
    # Leer todos los clientes de DynamoDB (Scan solo cuando hay pocos datos)
    try:
        dynamo_response = dynamodb.scan(TableName=DYNAMODB_TABLE)
        clients = []

        for item in dynamo_response.get('Items', []):
            client_name = item.get('client_name', {}).get('S', '')
            client_email = item.get('email', {}).get('S','')
            clients.append({'client_name': client_name, 'email': client_email})

            # codigo correspondiente a logs - añadido
            log_structured("INFO", "Clientes leídos correctamente de DynamoDB", context, {"total_clients": len(clients)})
            # sigue de primera unidad


    except Exception as e:
        log_structured("ERROR", "Error leyendo DynamoDB", context, {"exception": str(e)}) # añadido de logs
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Error leyendo DynamoDB: {str(e)}'})
        }

    # Leer HTML y CSS desde S3
    try:
        html_obj = s3.get_object(Bucket=S3_BUCKET, Key=TEMPLATE_PREFIX + 'index.html')
        css_obj = s3.get_object(Bucket=S3_BUCKET, Key=TEMPLATE_PREFIX + 'style.css')

        html_content = html_obj['Body'].read().decode('utf-8')
        css_content = css_obj['Body'].read().decode('utf-8')
        log_structured("INFO", "Plantillas HTML y CSS cargadas desde S3", context) # añadido de logs

    except Exception as e:
        log_structured("ERROR", "Error leyendo desde S3", context, {"exception": str(e)}) # añadido de logs
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Error leyendo desde S3: {str(e)}'})
        }

    # Enviar a SQS (un mensaje por cliente)
    for client in clients:
        message = {
            'client': client,
            'templates': {'html': html_content, 'css': css_content}
        }
        
        sqs.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps(message)
        )
    log_structured("INFO", "Mensajes enviados a SQS", context, {"count": len(clients)}) # añadido de logs

    return {
        'statusCode': 200,
        'body': json.dumps({'status': 'OK', 'messages_sent': len(clients)})
    }