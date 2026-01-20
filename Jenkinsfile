pipeline {
    agent any
    
    environment {
        DOCKER_USER = 'ishanj10'
        BACKEND_REPO = 'https://github.com/ishan-j/INCOPS_Backend.git'
        FRONTEND_REPO = 'https://github.com/ishan-j/INCOPS_Frontend.git'
        // Hardcode your Minikube IP if 'minikube ip' continues to fail in Jenkins
        MINIKUBE_IP = '192.168.49.2' 
    }

    stages {
        stage('Cleanup & Checkout') {
            steps {
                deleteDir()
                // 1. Re-checkout the INFRA repo (this brings back docker/ and k8s/ folders)
                checkout scm 
                
                // 2. Clone application code into subfolders
                dir('backend') { git url: "${BACKEND_REPO}", branch: 'main' }
                dir('frontend') { git url: "${FRONTEND_REPO}", branch: 'main' }
                
                sh "ls -R" // Verify the 'docker' folder is now visible
            }
        }

        stage('Build & Push Backend') {
            steps {
                script {
                    docker.withRegistry('', 'dockerhub-creds') {
                        // Context is '.' so it can see the 'backend' folder
                        def backendImg = docker.build("${DOCKER_USER}/incops-backend:latest", "-f docker/backend.Dockerfile .")
                        backendImg.push()
                    }
                }
            }
        }

        stage('Build & Push Frontend') {
            steps {
                script {
                    docker.withRegistry('', 'dockerhub-creds') {
                        // Using the IP defined in environment
                        def frontendImg = docker.build("${DOCKER_USER}/incops-frontend:latest", "--build-arg REACT_APP_API_URL=http://${MINIKUBE_IP}:30001 -f docker/frontend.Dockerfile .")
                        frontendImg.push()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                // Ensure we apply the new frontend-deployment.yaml you created
                sh "kubectl apply -f k8s/configmap.yaml"
                sh "kubectl apply -f k8s/init-db-config.yaml" // The table creator
                sh "kubectl apply -f k8s/mysql-deployment.yaml"
                sh "kubectl apply -f k8s/backend-deployment.yaml"
                sh "kubectl apply -f k8s/frontend-deployment.yaml"
            }
        }
    }
}