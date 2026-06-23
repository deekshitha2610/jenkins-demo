pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                // Pull code from GitHub
                checkout scm
            }
        }

        stage('Build Java App') {
            steps {
                script {
                    // Compile your Hello.java program
                    sh 'javac Hello.java'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image from Dockerfile
                    sh 'docker build -t jenkins-demo:latest .'
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding',
                    credentialsId: 'aws-ecr-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh '''
                    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                    aws configure set default.region eu-north-1
                    aws ecr get-login-password --region eu-north-1 \
                    | docker login --username AWS --password-stdin 579017679500.dkr.ecr.eu-north-1.amazonaws.com
                    '''
                }
            }
        }

        stage('Tag & Push to ECR') {
            steps {
                script {
                    sh '''
                    docker tag jenkins-demo:latest 579017679500.dkr.ecr.eu-north-1.amazonaws.com/jenkins-demo-repo:latest
                    docker push 579017679500.dkr.ecr.eu-north-1.amazonaws.com/jenkins-demo-repo:latest
                    '''
                }
            }
        }
    }
}
