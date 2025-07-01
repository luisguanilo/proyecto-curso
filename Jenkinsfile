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
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Plan Terraform') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        // --- Nuevo stage para escaneo de seguridad con Checkov ---
        stage('Security Scan – Checkov') {
            steps {
                    dir('infra') {
                        sh '''
                         # 1) Crea (o reutiliza) un virtualenv en la raíz del workspace
                        if [ ! -d "../venv" ]; then
                            python3 -m venv ../venv
                        fi

                        # 2) Activa el virtualenv e instala Checkov
                        . ../venv/bin/activate
                        pip install --upgrade pip
                        pip install checkov

                        # 3) Ejecuta el escaneo
                        echo " Ejecutando Checkov en infra/…"
                        checkov -d . \
                            --framework terraform \
                            --compact \
                            --soft-fail \
                            --output json \
                         # 4) Desactiva el virtualenv 
                        deactivate || true
                    '''
                  }
                
                }
            }
        

        // --- aqui termina el stage del escaneo checkov


        stage('Apply Terraform') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Verificar ejecución Lambda y SQS') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
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

        stage('Esperar 5 minutos') {
            steps {
                echo 'Esperando 5 minutos antes de continuar con el destroy...'
                sleep time: 20, unit: 'MINUTES'
            }
        }

        stage('Destroy Terraform') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'terraform destroy -auto-approve'
                }
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
