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
        bat 'javac Hello.java'
    }
}

stage('Build Docker Image') {
    steps {
        bat 'docker build -t jenkins-demo:latest .'
    }
}

stage('Login to ECR') {
    steps {
        withCredentials([[$class: 'UsernamePasswordMultiBinding',
            credentialsId: 'aws-ecr-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            bat '''
            aws configure set aws_access_key_id %AWS_ACCESS_KEY_ID%
            aws configure set aws_secret_access_key %AWS_SECRET_ACCESS_KEY%
            aws configure set default.region eu-north-1
            for /f "tokens=*" %%i in ('aws ecr get-login-password --region eu-north-1') do docker login --username AWS --password %%i 579017679500.dkr.ecr.eu-north-1.amazonaws.com
            '''
        }
    }
}

stage('Tag & Push to ECR') {
    steps {
        bat '''
        docker tag jenkins-demo:latest 579017679500.dkr.ecr.eu-north-1.amazonaws.com/jenkins-demo-repo:latest
        docker push 579017679500.dkr.ecr.eu-north-1.amazonaws.com/jenkins-demo-repo:latest
        '''
    }
}

