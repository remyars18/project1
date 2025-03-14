pipeline {
    agent any
    parameters {
        string(name: 'DOCKER_IMAGE_NAME', defaultValue: 'car-image', description: 'Name of the Docker image')
        choice(name: 'TERRAFORM_ACTION', choices: ['apply', 'destroy', 'plan'], description: 'Select Terraform action to perform')
        string(name: 'USER_NAME', defaultValue: 'Arun', description: 'Specify who is running the code')
        string(name: 'EKS_CLUSTER_NAME', defaultValue: 'k8-cluster', description: 'EKS Cluster Name')
        string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS Region')
    }

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws_credential')
         KUBECONFIG = '/tmp/kubeconfig'
    }

    stages {
        stage('Code checkout from Git') {
            steps {
                checkout scmGit(
                    branches: [[name: '*/main']], 
                    extensions: [], 
                    userRemoteConfigs: [[credentialsId: 'jenkin-git', url: 'https://github.com/remyars18/project1.git']]
                )
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Log in to Docker Hub before building the image
                    withCredentials([usernamePassword(credentialsId: 'jenkins-dockerhub', passwordVariable: 'pwd', usernameVariable: 'usr')])  {
                        sh "echo '${pwd}' | docker login -u ${usr} --password-stdin"
                    }
                    
                    // Check Docker version
                    sh 'docker --version'

                    // Build the Docker image
                    sh  "docker build -t ${params.DOCKER_IMAGE_NAME}:latest -f Dockerfile ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    // Log in to Docker Hub using credentials
                    withCredentials([usernamePassword(credentialsId: 'jenkins-dockerhub', passwordVariable: 'pwd', usernameVariable: 'user')]) {
                        sh "echo '${pwd}' | docker login -u ${user} --password-stdin"
                        
                        // Tag and push the built Docker image to Docker Hub
                        sh "docker tag ${params.DOCKER_IMAGE_NAME}:latest ${user}/${params.DOCKER_IMAGE_NAME}:latest"
                        sh "docker push ${user}/${params.DOCKER_IMAGE_NAME}:latest"
                    }
                }
            }
        }
        stage('terraform init') {
            steps {
                script {
                    sh "terraform init"
                }
            }
        }
        stage('Terraform Action') {
            steps {
                script {
                    // Perform selected Terraform action
                    if (params.TERRAFORM_ACTION == 'apply') {
                        sh 'terraform apply -auto-approve'
                    } else if (params.TERRAFORM_ACTION == 'destroy') {
                        sh 'terraform destroy -auto-approve'
                    } else if (params.TERRAFORM_ACTION == 'plan') {
                        sh 'terraform plan'
                    } else {
                        error "Invalid Terraform action selected: ${params.TERRAFORM_ACTION}"
                    }
                }
            }
        }
        stage('kubectl-setup') {
            steps {
                script {
                    echo "Setting up kubectl config..."
                    
                    // Update kubeconfig for EKS using AWS CLI and store it in KUBECONFIG
                    sh """
                    aws eks --region ${params.AWS_REGION} update-kubeconfig --name ${params.EKS_CLUSTER_NAME} --kubeconfig ${env.KUBECONFIG}
                    """
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                script {
                    echo "Checking Kubernetes Nodes..."
                    // Verify the kubectl setup by listing Kubernetes nodes
                    sh "kubectl --kubeconfig ${env.KUBECONFIG} get nodes"
                    sh "kubectl --kubeconfig ${env.KUBECONFIG} apply -f blue-deployment.yaml"
                    sh "kubectl --kubeconfig ${env.KUBECONFIG} apply -f blue-service.yaml"
                    sh "kubectl --kubeconfig ${env.KUBECONFIG} get svc blue-app-svc -o wide"
                }
            }
        }
    }
}
