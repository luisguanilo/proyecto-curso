import json
import boto3
import os

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
    except Exception as e:
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
    except Exception as e:
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

    return {
        'statusCode': 200,
        'body': json.dumps({'status': 'OK', 'messages_sent': len(clients)})
    }