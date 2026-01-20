pipeline {
    agent any
    
    environment {
        DOCKER_USER = 'ishanj10'
        BACKEND_REPO = 'https://github.com/ishan-j/INCOPS_Backend.git'
        FRONTEND_REPO = 'https://github.com/ishan-j/INCOPS_Frontend.git'
    }

    stages {
        stage('Cleanup & Checkout') {
            steps {
                deleteDir() 
                checkout scm // REQUIRED: This brings back your 'docker' and 'k8s' folders
                
                dir('backend') { git url: "${BACKEND_REPO}", branch: 'main' }
                dir('frontend') { git url: "${FRONTEND_REPO}", branch: 'main' }
                
                sh "ls -R" // Verify files are present in the Jenkins console
            }
        }

        stage('Build & Push Backend') {
            steps {
                script {
                    docker.withRegistry('', 'dockerhub-creds') {
                        def backendImg = docker.build("${DOCKER_USER}/incops-backend:latest", "-f docker/backend.Dockerfile .")
                        backendImg.push()
                    }
                }
            }
        }

        stage('Build & Push Frontend') {
            steps {
                script {
                    // Try to get Minikube IP; fallback to default if command fails
                    def minikubeIp = sh(script: "minikube ip || echo '192.168.49.2'", returnStdout: true).trim()
                    
                    docker.withRegistry('', 'dockerhub-creds') {
                        // Pass API URL as a build argument using the Minikube IP and Backend NodePort
                        def frontendImg = docker.build("${DOCKER_USER}/incops-frontend:latest", "--build-arg REACT_APP_API_URL=http://${minikubeIp}:30001 -f docker/frontend.Dockerfile .")
                        frontendImg.push()
                    }
                }
            }
        }

        stage('Deploy to Minikube') {
            steps {
                // Apply all 3 layers: DB, Backend, and Frontend
                sh "kubectl apply -f k8s/configmap.yaml"
                sh "kubectl apply -f k8s/mysql-deployment.yaml"
                sh "kubectl apply -f k8s/backend-deployment.yaml"
                sh "kubectl apply -f k8s/frontend-deployment.yaml"
            }
        }
    }
}