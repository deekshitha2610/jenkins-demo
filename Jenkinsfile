pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                sh 'javac Hello.java'
            }
        }

        stage('Test') {
            steps {
                echo 'Testing...'
                sh 'java Hello'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying to AWS EC2...'
                sshPublisher(publishers: [
                    sshPublisherDesc(
                        configName: 'aws-ec2',
                        transfers: [
                            sshTransfer(
                                sourceFiles: 'Hello.class',
                                remoteDirectory: '/home/ec2-user/app',
                                execCommand: 'java Hello'
                            )
                        ]
                    )
                ])
            }
        }
    }
}
