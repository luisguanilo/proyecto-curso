pipeline {
    agent {
        docker {
            image 'hashicorp/terraform:latest'  // Usar la imagen Docker de Terraform
            //label 'docker-agent'  // usando agente
            args '-v /var/run/docker.sock:/var/run/docker.sock'  // Permite que Terraform use Docker dentro del contenedor
        }
    }

    environment {
      
        AWS_DEFAULT_REGION = 'us-east-1'  
    }
    stages {
        stage('Clonar Repositorio') {
            steps {
                git 'https://github.com/luisguanilo/proyecto-curso.git'
            }
        }

        stage('Preparar Terraform') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Ejecutar Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }

        stage('Aplicar Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }

        stage('Verificar Envío de Correos') {
            steps {
                echo 'Verificando que el envío de correos haya sido exitoso'
                // Verificar los logs de Lambda
                sh 'aws logs filter-log-events --log-group-name "/aws/lambda/send-emails" --limit 10'
                
                // Opcional: Verificar si la Lambda está invocando correctamente
                sh 'aws lambda invoke --function-name arn:aws:lambda:us-east-1:322957919239:function:send-emails output.txt'

                sh 'cat output.txt'
                
                // Opcional: Verificar la cola SQS (si aplica)
                sh 'aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/322957919239/email-queue'
            }
        }
    }

    post {
        always {
            echo 'Pipeline completado'
        }
        success {
            echo 'Despliegue exitoso'
        }
        failure {
            echo 'El despliegue falló. Revisa los logs para más detalles.'
        }
    }
}