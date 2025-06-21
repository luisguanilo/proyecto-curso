pipeline {
    agent {
        docker {
            image 'proyecto-terraform' 
        }
    }

    environment {
        DOCKER_HOST = 'tcp://host.docker.internal:2375'
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {
        stage('Clonar Repositorio') {
            steps {
                git branch: 'main', url: 'https://github.com/luisguanilo/proyecto-curso.git'
            }
        }

        stage('Init Terraform') {
            steps {
                sh 'terraform init -input=false'
            }
        }

        stage('Plan Terraform') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Apply Terraform') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }

        stage('Verificar ejecución Lambda y SQS') {
            steps {
                echo ' Verificando logs de Lambda y estado de SQS'

                sh '''
                echo "Últimos logs de Lambda:"
                aws logs filter-log-events --log-group-name "/aws/lambda/send-emails" --limit 10 || echo "Error al leer logs"

                echo "Ejecutando Lambda directamente:"
                aws lambda invoke --function-name arn:aws:lambda:us-east-1:322957919239:function:send-emails output.json || echo "Error al invocar Lambda"
                cat output.json
                rm -f output.json

                echo "Verificando SQS:"
                aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/322957919239/email-queue || echo "No se encontraron mensajes"
                '''
            }
        }
    }

    post {
        always {
            echo ' Pipeline completado'
        }
        success {
            echo ' Despliegue exitoso'
        }
        failure {
            echo '===Error=== El despliegue falló. Revisa los logs.'
        }
    }
}
