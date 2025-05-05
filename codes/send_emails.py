import json
import boto3
import os

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
                            'Data': email_body
                        }
                    }
                }
            )

            # Eliminar el mensaje de la cola de SQS
            # sqs.delete_message(
            #     QueueUrl=SQS_QUEUE_URL,
            #     ReceiptHandle=record['receiptHandle']
            # )

        except Exception as e:
            #print(f"Error sending email to {client_email}: {str(e)}") # Para cloudwatch
            continue

    return {
        'statusCode': 200,
        'body': json.dumps('Emails sent successfully.')
    }