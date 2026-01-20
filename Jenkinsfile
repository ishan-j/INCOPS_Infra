pipeline {
    agent any
    environment {
        DOCKER_USER = 'ishanj10'
        BACKEND_REPO = 'https://github.com/ishan-j/INCOPS_Backend.git'
        FRONTEND_REPO = 'https://github.com/ishan-j/INCOPS_Frontend.git'
    }
    stages {
        stage('Cleanup') {
            steps {
                deleteDir()
            }
        }
        stage('Checkout Code') {
            steps {
                // Cloning the application repos into subfolders
                dir('backend') { git url: "${BACKEND_REPO}", branch: 'main' }
                dir('frontend') { git url: "${FRONTEND_REPO}", branch: 'main' }
            }
        }
        stage('Build & Push Backend') {
            steps {
                script {
                    docker.withRegistry('', 'dockerhub-creds') {
                        // Correct pathing: Dockerfile is in infra-repo root/docker/
                        def backendImg = docker.build("${DOCKER_USER}/incops-backend:latest", "-f docker/backend.Dockerfile .")
                        backendImg.push()
                    }
                }
            }
        }
        stage('Build & Push Frontend') {
            steps {
                script {
                    // 1. Get IP first
                    def minikubeIp = sh(script: "minikube ip", returnStdout: true).trim()
                    
                    // 2. Build and push inside ONE registry block
                    docker.withRegistry('', 'dockerhub-creds') {
                        def frontendImg = docker.build("${DOCKER_USER}/incops-frontend:latest", "--build-arg REACT_APP_API_URL=http://${minikubeIp}:30001 -f docker/frontend.Dockerfile .")
                        frontendImg.push()
                    }
                }
            }
        }
        stage('Deploy to Minikube') {
            steps {
                // Ensure Jenkins has the 'kubectl' context for Minikube
                sh "kubectl apply -f k8s/configmap.yaml"
                sh "kubectl apply -f k8s/mysql-deployment.yaml"
                sh "kubectl apply -f k8s/backend-deployment.yaml"
                sh "kubectl apply -f k8s/frontend-deployment.yaml"
            }
        }
    }
}