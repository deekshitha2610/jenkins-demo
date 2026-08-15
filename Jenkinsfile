pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '579017679500'
        ECR_REPO = 'helloworld'
        ECR_URI = '579017679500.dkr.ecr.us-east-1.amazonaws.com/helloworld'
        EKS_CLUSTER = 'my-eks-cluster'
    }

    stages {

        stage('Check Tools') {
            steps {
                bat '''
                    echo ===== Checking Tools =====
                    aws --version
                    kubectl version --client
                    docker --version
                    mvn -version
                    git --version
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
                    echo ===== Building Java Application =====
                    mvn clean package -DskipTests
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                bat '''
                    echo ===== Building Docker Image =====
                    docker build -t %ECR_URI%:latest .
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-ecr-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    bat '''
                        echo ===== Logging into AWS ECR =====

                        set AWS_DEFAULT_REGION=%AWS_REGION%

                        aws configure set aws_access_key_id %AWS_ACCESS_KEY_ID%
                        aws configure set aws_secret_access_key %AWS_SECRET_ACCESS_KEY%
                        aws configure set default.region %AWS_REGION%

                        aws sts get-caller-identity

                        aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                bat '''
                    echo ===== Pushing Docker Image =====
                    docker push %ECR_URI%:latest
                '''
            }
        }

        stage('Configure kubectl') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-ecr-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    bat '''
                        echo ===== Configuring kubectl =====

                        set AWS_DEFAULT_REGION=%AWS_REGION%

                        aws configure set aws_access_key_id %AWS_ACCESS_KEY_ID%
                        aws configure set aws_secret_access_key %AWS_SECRET_ACCESS_KEY%
                        aws configure set default.region %AWS_REGION%

                        aws eks update-kubeconfig --region %AWS_REGION% --name %EKS_CLUSTER%

                        kubectl get nodes
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                bat '''
                    echo ===== Deploying to EKS =====

                    kubectl apply -f deploymentjava.yaml
                    kubectl apply -f servicelb.yaml

                    kubectl set image deployment/java-app java-app=%ECR_URI%:latest

                    kubectl rollout status deployment/java-app --timeout=180s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                bat '''
                    echo ===== Deployment Status =====

                    kubectl get deployment
                    kubectl get pods -o wide
                    kubectl get svc java-app-service

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
            Check the failed stage and Console Output.
            ==========================================
            '''
        }
    }
}
