pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '579017679500'

        EKS_CLUSTER = 'my-eks-cluster'

        ECR_REPOSITORY = 'helloworld'
        IMAGE_TAG = 'latest'
        IMAGE_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}"

        // Maven installed on your Windows machine
        MAVEN_HOME = 'C:\\Users\\hp\\Downloads\\apache-maven-3.10.0-rc-1-bin\\apache-maven-3.10.0-rc-1'

        KUBECONFIG = "${WORKSPACE}\\kubeconfig"
    }

    stages {

        stage('Check Tools') {
            steps {
                bat '''
                    echo ===== Checking Tools =====

                    aws --version
                    kubectl version --client
                    docker --version
                    git --version

                    echo ===== Checking Maven =====
                    "%MAVEN_HOME%\\bin\\mvn.cmd" -version

                    echo ===== Checking Java =====
                    java -version
                '''
            }
        }

        stage('Checkout') {
            steps {
                echo '===== Checking out source code ====='
                checkout scm

                bat '''
                    echo ===== Repository Contents =====
                    dir
                '''
            }
        }

        stage('Build Java Application') {
            steps {
                echo '===== Building Java application ====='

                bat '''
                    "%MAVEN_HOME%\\bin\\mvn.cmd" clean package -DskipTests
                '''
            }
        }

        stage('Verify WAR') {
            steps {
                bat '''
                    echo ===== Checking generated WAR =====
                    dir target

                    if not exist "target\\*.war" (
                        echo ERROR: WAR file was not generated.
                        exit /b 1
                    )

                    echo WAR file generated successfully.
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
                        echo ===== Configuring AWS credentials =====

                        set AWS_DEFAULT_REGION=%AWS_REGION%

                        aws sts get-caller-identity

                        echo AWS account and credentials verified.
                    '''
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    bat '''
                        echo ===== Logging into ECR =====

                        aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com

                        if errorlevel 1 (
                            echo ERROR: Docker login to ECR failed.
                            exit /b 1
                        )

                        echo ECR login successful.
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '===== Building Docker image ====='

                bat '''
                    docker build -t %IMAGE_URI% .

                    if errorlevel 1 (
                        echo ERROR: Docker image build failed.
                        exit /b 1
                    )

                    docker images %IMAGE_URI%
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    bat '''
                        echo ===== Pushing Docker image to ECR =====

                        docker push %IMAGE_URI%

                        if errorlevel 1 (
                            echo ERROR: Docker push failed.
                            exit /b 1
                        )

                        echo Docker image pushed successfully.
                    '''
                }
            }
        }

        stage('Configure kubectl') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    bat '''
                        echo ===== Configuring kubectl for EKS =====

                        if exist "%KUBECONFIG%" del /f /q "%KUBECONFIG%"

                        aws eks update-kubeconfig ^
                            --region %AWS_REGION% ^
                            --name %EKS_CLUSTER% ^
                            --kubeconfig "%KUBECONFIG%"

                        if errorlevel 1 (
                            echo ERROR: Failed to configure kubeconfig.
                            exit /b 1
                        )

                        echo ===== Checking EKS connection =====

                        kubectl --kubeconfig "%KUBECONFIG%" get nodes

                        if errorlevel 1 (
                            echo ERROR: Cannot connect to EKS.
                            exit /b 1
                        )
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    bat '''
                        echo ===== Deploying Java application to EKS =====

                        echo Applying Deployment...
                        kubectl --kubeconfig "%KUBECONFIG%" apply -f deploymentjava.yaml

                        if errorlevel 1 (
                            echo ERROR: Deployment manifest failed.
                            exit /b 1
                        )

                        echo Applying LoadBalancer Service...
                        kubectl --kubeconfig "%KUBECONFIG%" apply -f servicelb.yaml

                        if errorlevel 1 (
                            echo ERROR: Service manifest failed.
                            exit /b 1
                        )

                        echo ===== Deployment applied successfully =====
                    '''
                }
            }
        }

        stage('Update Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    bat '''
                        echo ===== Updating deployment image =====

                        kubectl --kubeconfig "%KUBECONFIG%" set image deployment/java-app java-app=%IMAGE_URI%

                        if errorlevel 1 (
                            echo ERROR: Failed to update deployment image.
                            exit /b 1
                        )

                        echo Image updated successfully.
                    '''
                }
            }
        }

        stage('Wait for Rollout') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    bat '''
                        echo ===== Waiting for rollout =====

                        kubectl --kubeconfig "%KUBECONFIG%" rollout status deployment/java-app --timeout=180s

                        if errorlevel 1 (
                            echo ERROR: Deployment rollout failed.
                            kubectl --kubeconfig "%KUBECONFIG%" get pods -o wide
                            kubectl --kubeconfig "%KUBECONFIG%" describe deployment java-app
                            exit /b 1
                        }

                        echo Rollout completed successfully.
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-ecr-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    bat '''
                        echo.
                        echo ==========================================
                        echo Kubernetes Deployment
                        echo ==========================================

                        kubectl --kubeconfig "%KUBECONFIG%" get deployment java-app

                        echo.
                        echo ==========================================
                        echo Pods
                        echo ==========================================

                        kubectl --kubeconfig "%KUBECONFIG%" get pods -o wide

                        echo.
                        echo ==========================================
                        echo Service
                        echo ==========================================

                        kubectl --kubeconfig "%KUBECONFIG%" get svc java-app-service

                        echo.
                        echo ==========================================
                        echo Endpoints
                        echo ==========================================

                        kubectl --kubeconfig "%KUBECONFIG%" get endpoints java-app-service
                    '''
                }
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
            Kubernetes rollout completed successfully.

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

        always {
            echo 'Pipeline execution completed.'
        }
    }
}
