import json
import boto3
import os
import logging # añadido por logs

# Configuración básica de logs
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def log_structured(level, message, context=None, extra=None):
    log_entry = {
        "level": level,
        "message": message,
        "function": "send_emails",
        "context": {
            "request_id": context.aws_request_id if context else None
        }
    }
    if extra:
        log_entry.update(extra)
    logger.info(json.dumps(log_entry))
# codigo siguiente de primera unidad


# Clientes de AWS
ses = boto3.client('ses')
sqs = boto3.client('sqs')

# Variables de entorno desde Terraform
FROM_EMAIL = os.environ['FROM_EMAIL']    # Correo verificado en SES
SQS_QUEUE_URL = os.environ['SQS_QUEUE_URL']

def lambda_handler(event, context):
    # Iterar sobre cada mensaje recibido desde SQS
    for record in event['Records']:
        # El mensaje está en el body, que está en formato JSON
        message_body = json.loads(record['body'])

        client = message_body.get('client', {})
        templates = message_body.get('templates', {})

        client_name = client.get('client_name', 'Unknown')
        client_email = client.get('email', '')
        html_content = templates.get('html', '')
        css_content = templates.get('css', '')

        if not client_email:
            print(f"Missing email for client {client_name}. Skipping.")
            log_structured("WARNING", "Cliente sin correo. No se envió el email.", context, {"client_name": client_name}) # Añadido por logs
            continue
        
        # Crear el contenido del correo electrónico con el HTML y CSS
        email_body = f"""
        <html>
        <head><style>{css_content}</style></head>
        <body>
            <h1>Hello, {client_name}!</h1>
            {html_content}
        </body>
        </html>
        """

        # Enviar el correo usando SES
        try:
            response = ses.send_email(
                Source=FROM_EMAIL,
                Destination={
                    'ToAddresses': [client_email]
                },
                Message={
                    'Subject': {
                        'Data': f"Special offer for {client_name}!"
                    },
                    'Body': {
                        'Html': {
                            'Data': email_body}}
                        }
            )
            log_structured("INFO", "Correo enviado exitosamente", context, { # añadido de logs
                "client_name": client_name, # añadido de logs
                "client_email": client_email # añadido de logs

                }
            )

            # Eliminar el mensaje de la cola de SQS
            # sqs.delete_message(
            #     QueueUrl=SQS_QUEUE_URL,
            #     ReceiptHandle=record['receiptHandle']
            # )

        except Exception as e:
            log_structured("ERROR", "Error al enviar correo", context, {
                "client_email": client_email,
                "exception": str(e)}) # añadido por logs
            continue

    return {
        'statusCode': 200,
        'body': json.dumps('Emails sent successfully.')
    }