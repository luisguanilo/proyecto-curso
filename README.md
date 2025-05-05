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
