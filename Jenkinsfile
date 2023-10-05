pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS')
        AWS_SECRET_ACCESS_KEY = credentials('AWS')
        USERNAME             = credentials('DOCKER')
        PASSWORD             = credentials('DOCKER')
    }

    stages {
        stage('Checkout-Application') {
            steps {
                git branch: 'main', url: 'https://github.com/Suru-Suraj/APPLICATION.git'
            }
        }

        stage('Checkout-Infrastructure') {
            steps {
                git branch: 'main', url: 'https://github.com/Suru-Suraj/INFRASTRUCTURE.git'
            }
        }

        stage('Application Build and push to DockerHub') {
            steps {
                git branch: 'main', url: 'https://github.com/Suru-Suraj/APPLICATION.git'
                script {
                    sh 'pwd'
                    sh 'ls'
                    sh 'docker build -t surusuraj200021/suru:node .'
                    withCredentials([usernamePassword(credentialsId: 'DOCKER', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo \$PASSWORD | docker login -u \$USERNAME --password-stdin
                    """
                    }
                    sh "docker push surusuraj200021/suru:node"
                }
            }
        }

        stage('Step-1 and Ansible') {
            steps {
                git branch: 'main', url: 'https://github.com/Suru-Suraj/INFRASTRUCTURE.git'
                script {
                    sh "cd Step-1"
                    sh "ls"
                    dir('Step-1') {
                        sh "aws configure set aws_access_key_id \$AWS_ACCESS_KEY_ID"
                        sh "aws configure set aws_secret_access_key \$AWS_SECRET_ACCESS_KEY"
                        sh "terraform init"
                        sh "terraform apply -auto-approve -input=false"
                        sh "terraform output public_ip | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+' > ~/public"
                        sh "terraform output instance_id > ~/instance"
                        sh "cat ~/instance"
                        sh "terraform output instance_id"
                        sh "cp capstone.pem ~/capstone.pem"
                    }
                    dir('ANSIBLE') {
                        sh "pwd"
                        sh '''
                            echo "all:" >> inventory.yml
                            echo "  hosts:" >> inventory.yml
                            echo "    capstone:" >> inventory.yml
                            echo "      ansible_host: $(head -n 1 ~/public)" >> inventory.yml
                            echo "      ansible_user: ubuntu" >> inventory.yml
                            echo "      ansible_ssh_private_key_file: capstone.pem" >> inventory.yml
                        '''
                        sh "cat inventory.yml"
                        sh 'echo "$(cat ~/capstone.pem)" >> ./capstone.pem'
                        sh "ls"
                        sh 'chmod 400 capstone.pem'
                        sh 'ansible --version'
                        ansiblePlaybook disableHostKeyChecking: true, installation: 'ANSIBLE', inventory: 'inventory.yml', playbook: 'playbook.yml'
                    }
                    dir('AMI') {
                        sh "cat ~/instance"
                        sh '''
                            echo 'variable "source_instance_id" {' >> var.tf
                            echo '  description = "The ID of the source AWS EC2 instance from which to create the AMI."' >> var.tf
                            echo '  type        = string' >> var.tf
                            echo '  default     = $(head -n 1 ~/instance)' >> var.tf
                            echo '}' >> var.tf
                        '''
                        cat var.tf
                        sh "terraform init"
                        sh "terraform apply -auto-approve -input=false"
                        sh "terraform output -raw ami_id > ~/ami"
                    }
                    dir('Step-1') {
                        sh "terraform destroy -auto-approve -input=false"
                    }
                }
            }
        }
    }
}
