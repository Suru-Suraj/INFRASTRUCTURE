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
                    sh 'docker build -t surusuraj200021/suru:caps .'
                    withCredentials([usernamePassword(credentialsId: 'DOCKER', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo \$PASSWORD | docker login -u \$USERNAME --password-stdin
                    """
                    }
                    sh "docker push surusuraj200021/suru:caps"
                }
            }
        }

        stage('TERRAFORM AND ANSIBLE') {
            steps {
                git branch: 'main', url: 'https://github.com/Suru-Suraj/INFRASTRUCTURE.git'
                script {
                    sh "ls"
                    dir('TERRAFORM') {
                        sh "aws configure set aws_access_key_id \$AWS_ACCESS_KEY_ID"
                        sh "aws configure set aws_secret_access_key \$AWS_SECRET_ACCESS_KEY"
                        sh "terraform init"
                        sh "terraform apply -auto-approve -input=false"
                        sh "terraform output public_ip | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+' > ~/public"
                        sh 'rm -rf ~/instance'
                        sh "terraform output -raw instance_id > ~/instance"
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
                        sh "terraform init"
                        sh 'terraform apply -auto-approve -input=false -var source_instance_id=$(head -n 1 ~/instance)'
                        sh "terraform output -raw ami_id"
                        sh 'rm -rf ~/ami'
                        sh "terraform output -raw ami_id > ~/ami"
                    }
                    dir('TERRAFORM') {
                        sh "terraform destroy -auto-approve -input=false"
                    }
                    dir('CAPSTONE') {
                        sh "terraform init"
                        sh "terraform apply -auto-approve -input=false -var ami_id=\$(head -n 1 ~/ami | grep -oP 'ami-\\w+')"
                    }
                }
            }
        }
    }
}
