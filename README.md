# Proyecto de clase de Infraestructura como Codigo
**Enunciado de la problemática:**
La empresa “Constructora Quintana”, dedicada a la ejecución de proyectos de construcción civil, cuenta con su oficina central en Cajamarca, así como una planta de concreto que abastece tanto a sus propias obras como a clientes externos. En su operación diaria, existen dos necesidades críticas que ya no pueden ser gestionadas de forma manual:
1.	Los trabajadores en oficina, obra y planta necesitan compartir y acceder a documentación esencial en tiempo real (planos, informes, reportes de materiales, etc.). Actualmente, este proceso depende de métodos informales como correos o dispositivos físicos, lo cual dificulta la colaboración fluida y puede causar demoras operativas.	

2.	Con el crecimiento de su base de clientes interesados en la compra de concreto, el equipo de oficina ya no puede enviar manualmente propuestas, promociones o campañas informativas a todos los contactos. Esto ha generado cuellos de botella y una carga excesiva para el equipo.
------
# Desarrollo:
se cree conveniente el uso de los siguientes archivos
main.tf    --> es la infraestructura principal, se definen recursos
variables.tf  --> se definen las variables tanto globales como especificas
outputs.tf  --> salidas de la infraestructura 
carpeta templates, con archivos index.html y el archivo styles.css  --> es el archivo de plantilla html y css
carpeta codes con los archivos prepare_emails.zip y send_emails.zip --> que son los codigos de lqas funciones lambda empaquetdos

lso recursos se definen  crean e archivos individuales para mantener una mejor practica de manejo del codigo.

el proyecto en su estado actual logra desplegar el envio de correos a personas autenticadas,  por ser una cuenta con restricciones el emisor de correo debe de ser validado manualmente.

NOTA: el proyecto se hizo nuevamente en un nuevo repositorio por problemas en la implementacion del github que daba error al momento del push, no subia los arhivos al repositorio, razon por l cual tube que implementar de urgencia el nuevo repositorio para ejecucion y demostracion del proyecto.

* se ejecuto pruebas del despliegue del codigo, dando resultados optimos.



Luis Guanilo Esteves
Hector reyna Gomez
Luis Carranza Leon

# **Desarrollo de Logs para el proyecto**
##  Integración con CloudWatch

Este proyecto utiliza **Amazon CloudWatch** para monitorear funciones Lambda y servicios AWS:

- Logs estructurados desde `prepare_emails` y `send_emails` enviados a **CloudWatch Logs**.
- Métricas como invocaciones, errores y duración de ejecución están disponibles automáticamente en **CloudWatch Metrics**.
- Exportación de logs a **Amazon S3** usando `aws logs create-export-task` vía Terraform (`null_resource`).
- Los permisos necesarios están declarados en las políticas IAM asociadas a las funciones Lambda.

## Integración con CloudWatch

Este proyecto utiliza **Amazon CloudWatch** como herramienta central de monitoreo y registro para los distintos componentes desplegados en AWS, integrados mediante Terraform.

### ¿Qué se monitorea?

- **Funciones Lambda (`prepare_emails`, `send_emails`)**
  - Invocaciones totales
  - Errores en tiempo de ejecución
  - Duración promedio por invocación
  - Logs estructurados con formato JSON para fácil análisis
- **Cola SQS**
  - Métricas de mensajes visibles y en vuelo
- **Eventos registrados automáticamente**
  - Por API Gateway (si falla una invocación)

### Logs centralizados en CloudWatch Logs

Ambas funciones Lambda están configuradas para enviar logs directamente a **CloudWatch Logs**, utilizando `logging` en el código Python y políticas IAM apropiadas:

```python
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Log estructurado
log_structured("INFO", "Correo enviado exitosamente", context, {
    "client_name": client_name,
    "client_email": client_email
})
```

### Exportación automatizada de logs a S3
Los logs pueden ser exportados automáticamente a un bucket S3 `(quintana-lambda-logs)` usando un `null_resource` en Terraform que ejecuta el comando 
`aws logs create-export-task`
```
resource "null_resource" "export_logs" {
  provisioner "local-exec" {
    command = <<-EOT
      powershell -Command "$from = [int]([System.DateTime]::UtcNow.AddHours(-1) - [System.DateTime]::UnixEpoch).TotalSeconds * 1000;
      $to = [int]([System.DateTime]::UtcNow - [System.DateTime]::UnixEpoch).TotalSeconds * 1000;
      & 'C:\\Program Files\\Amazon\\AWSCLIV2\\aws.exe' logs create-export-task --log-group-name /aws/lambda/prepare_emails --from $from --to $to --destination 'quintana-lambda-logs' --destination-prefix 'exported-logs/prepare' --role-arn 'arn:aws:iam::xxxxxxxxxxxx:role/cloudwatch_logs_export_role'"
    EOT
  }
}
```
### Seguridad y permisos
Las funciones Lambda tienen permisos explícitos para escribir logs en CloudWatch, definidos en las políticas IAM
```
actions = [
  "logs:CreateLogGroup",
  "logs:CreateLogStream",
  "logs:PutLogEvents"
]
```
## Dashboard en CloudWatch

Como parte de la integración con **Amazon CloudWatch**, se creó un dashboard visual personalizado que centraliza el monitoreo del sistema:

- Invocaciones y duración de funciones Lambda (`prepare_emails`, `send-emails`)
- Tasa de errores 4XX/5XX de API Gateway
- Actividad de SQS (mensajes recibidos, vacíos, tamaño)
- Estadísticas de uso de DynamoDB (lectura/escritura)
- Envío y entrega de correos en Amazon SES
- Volumen de logs generados en Lambda

 El archivo `cloudwatch/dashboard.json` contiene la configuración completa del dashboard exportado directamente desde AWS. Puede ser reutilizado para recrear el dashboard en cualquier cuenta con la misma arquitectura.

 Todas las métricas visualizadas provienen de los servicios configurados por Terraform, y los permisos de las funciones Lambda permiten el envío de logs y generación de métricas automáticamente.

###  Comparativa de Invocaciones Lambda

El dashboard ahora incluye un panel informativo que muestra, en tiempo real, cuál de las funciones Lambda (`prepare_emails` vs `send-emails`) recibe más peticiones. Esto permite detectar:

- Funciones más utilizadas
- Picos de tráfico por evento
- Comportamientos anómalos en el sistema

El panel utiliza datos de CloudWatch Metrics en la dimensión `AWS/Lambda > Invocations`, con periodo de 1 minuto.




