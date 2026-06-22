pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building the project...'
                // Example: sh 'javac Hello.java'
            }
        }
        stage('Test') {
            steps {
                echo 'Running tests...'
                // Add test commands here
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying application...'
                // Later we’ll add AWS EC2 deployment steps
            }
        }
    }
}
