pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS')
        AWS_SECRET_ACCESS_KEY = credentials('AWS')
        USERNAME             = credentials('DOCKER')
        PASSWORD             = credentials('DOCKER')
    }

    stages {
        stage('Checkout-1') {
            steps {
                git branch: 'main', url: 'https://github.com/Suru-Suraj/APPLICATION.git'
            }
        }

        stage('Checkout-2') {
            steps {
                git branch: 'main', url: 'https://github.com/Suru-Suraj/INFRASTRUCTURE.git'
            }
        }

        stage('Build') {
            steps {
                git branch: 'main', url: 'https://github.com/Suru-Suraj/APPLICATION.git'
                sh 'docker build -t surusuraj200021/suru:node .'
                withCredentials([usernamePassword(credentialsId: 'DOCKER', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo \$PASSWORD | docker login -u \$USERNAME --password-stdin
                    """
                }
                sh "docker push surusuraj200021/suru:node"
            }
        }

        stage('Infrastructure') {
            steps {
                git branch: 'main', url: 'https://github.com/Suru-Suraj/INFRASTRUCTURE.git'
                script {
                    sh "aws configure set aws_access_key_id \$AWS_ACCESS_KEY_ID"
                    sh "aws configure set aws_secret_access_key \$AWS_SECRET_ACCESS_KEY"
                    sh "terraform init"
                    sh "terraform apply -auto-approve -input=false"
                    sh "terraform output public_ip | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+' > ~/public"
                    sh """
                        echo "all:" >> inventory.yml
                        echo "  hosts:" >> inventory.yml
                        echo "    capstone:" >> inventory.yml
                        echo "      ansible_host: \$(head -n 1 ~/public)" >> inventory.yml
                        echo "      ansible_user: ubuntu" >> inventory.yml
                        echo "      ansible_ssh_private_key_file: capstone.pem" >> inventory.yml
                    """
                    sh 'chmod 400 capstone.pem'
                    sh 'ansible --version'
                    ansiblePlaybook disableHostKeyChecking: true, installation: 'ANSIBLE', inventory: 'inventory.yml', playbook: 'playbook.yml'
                    sh "terraform destroy -auto-approve -input=false"
                }
            }
        }
    }
}
