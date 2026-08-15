pipeline {
    agent any

    environment {

        AWS_REGION = 'us-east-1'

        AWS_ACCOUNT_ID = '579017679500'

        ECR_REPOSITORY = 'helloworld'

        ECR_REGISTRY = '579017679500.dkr.ecr.us-east-1.amazonaws.com'

        IMAGE_NAME = '579017679500.dkr.ecr.us-east-1.amazonaws.com/helloworld:latest'

        EKS_CLUSTER = 'my-eks-cluster'

        MAVEN_HOME = 'C:\\Users\\hp\\Downloads\\apache-maven-3.10.0-rc-1-bin\\apache-maven-3.10.0-rc-1'

        PATH = "${MAVEN_HOME}\\bin;${env.PATH}"
    }

    stages {

        stage('Check Tools') {
            steps {
                bat '''
                    echo ==============================
                    echo Checking required tools
                    echo ==============================

                    aws --version
                    kubectl version --client
                    docker --version
                    git --version

                    echo.
                    echo Checking Maven
                    "%MAVEN_HOME%\\bin\\mvn.cmd" -version
                '''
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Java Application') {
            steps {
                bat '''
                    echo ==============================
                    echo Building Java WAR
                    echo ==============================

                    "%MAVEN_HOME%\\bin\\mvn.cmd" clean package -DskipTests
                '''
            }
        }

        stage('Check WAR') {
            steps {
                bat '''
                    echo Checking generated WAR...

                    if exist "target\\helloworld.war" (
                        echo WAR file found successfully.
                    ) else (
                        echo ERROR: WAR file not found.
                        exit /b 1
                    )
                '''
            }
        }

        stage('Configure AWS') {
            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {

                    bat '''
                        echo Configuring AWS credentials...

                        aws configure set aws_access_key_id "%AWS_ACCESS_KEY_ID%"
                        aws configure set aws_secret_access_key "%AWS_SECRET_ACCESS_KEY%"
                        aws configure set default.region "%AWS_REGION%"

                        echo Checking AWS identity...

                        aws sts get-caller-identity
                    '''
                }
            }
        }

        stage('Login to ECR') {
            steps {

                bat '''
                    echo Logging into Amazon ECR...

                    aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_REGISTRY%
                '''
            }
        }

        stage('Build Docker Image') {
            steps {

                bat '''
                    echo Building Docker image...

                    docker build -t %IMAGE_NAME% .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {

                bat '''
                    echo Pushing Docker image to ECR...

                    docker push %IMAGE_NAME%
                '''
            }
        }

        stage('Configure kubectl') {
            steps {

                bat '''
                    echo Updating kubeconfig...

                    aws eks update-kubeconfig --region %AWS_REGION% --name %EKS_CLUSTER%

                    echo Checking EKS connection...

                    kubectl get nodes
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {

                bat '''
                    echo ==============================
                    echo Deploying application
                    echo ==============================

                    kubectl apply -f deploymentjava.yaml

                    kubectl apply -f servicelb.yaml
                '''
            }
        }

        stage('Wait for Deployment') {
            steps {

                bat '''
                    echo Waiting for rollout...

                    kubectl rollout status deployment/java-app --timeout=180s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {

                bat '''
                    echo ==============================
                    echo Deployment Status
                    echo ==============================

                    kubectl get deployment java-app

                    echo.
                    kubectl get pods -o wide

                    echo.
                    kubectl get svc java-app-service

                    echo.
                    kubectl describe deployment java-app
                '''
            }
        }
    }

    post {

        success {

            echo '''
            ==========================================
            PIPELINE SUCCESS
            ==========================================
            Java application built successfully.
            Docker image pushed to ECR.
            Application deployed to EKS.
            ==========================================
            '''
        }

        failure {

            echo '''
            ==========================================
            PIPELINE FAILED
            ==========================================
            Check the failed stage and console output.
            ==========================================
            '''
        }
    }
}
