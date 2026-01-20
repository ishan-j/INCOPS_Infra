pipeline {
    agent any
    
    environment {
        DOCKER_USER = 'ishanj10'
        // Application Repositories
        BACKEND_REPO = 'https://github.com/ishan-j/INCOPS_Backend.git'
        FRONTEND_REPO = 'https://github.com/ishan-j/INCOPS_Frontend.git'
    }

    stages {
        stage('Cleanup & Checkout') {
            steps {
                // Wipe the workspace to ensure a clean build
                deleteDir()
                
                // 1. Re-checkout the INFRA repo (this brings back the docker/ and k8s/ folders)
                checkout scm
                
                // 2. Clone the application repositories into specific subfolders
                dir('backend') {
                    git url: "${BACKEND_REPO}", branch: 'main'
                }
                dir('frontend') {
                    git url: "${FRONTEND_REPO}", branch: 'main'
                }
                
                // 3. Debugging: List files to verify everything is present in the console output
                sh "ls -R"
            }
        }

        stage('Build & Push Backend') {
            steps {
                script {
                    docker.withRegistry('', 'dockerhub-creds') {
                        // Builds using the Dockerfile in infra-repo/docker/
                        // Uses the current directory (.) as context to include the 'backend' folder
                        def backendImg = docker.build("${DOCKER_USER}/incops-backend:latest", "-f docker/backend.Dockerfile .")
                        backendImg.push()
                    }
                }
            }
        }

        stage('Build & Push Frontend') {
            steps {
                script {
                    // Get Minikube IP to inject into the React build
                    def minikubeIp
                    try {
                        minikubeIp = sh(script: "minikube ip", returnStdout: true).trim()
                    } catch (Exception e) {
                        // Use the default Minikube IP if the command fails
                        minikubeIp = "192.168.49.2" 
                        echo "Minikube command failed, using fallback IP: ${minikubeIp}"
                    }
                    
                    docker.withRegistry('', 'dockerhub-creds') {
                        def frontendImg = docker.build("${DOCKER_USER}/incops-frontend:latest", "--build-arg REACT_APP_API_URL=http://${minikubeIp}:30001 -f docker/frontend.Dockerfile .")
                        frontendImg.push()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                // Apply all manifests from the k8s folder in the infra repo
                sh "kubectl apply -f k8s/configmap.yaml"
                sh "kubectl apply -f k8s/mysql-deployment.yaml"
                sh "kubectl apply -f k8s/backend-deployment.yaml"
                sh "kubectl apply -f k8s/frontend-deployment.yaml"
                
                echo "Deployment successful! Use 'minikube service frontend-service --url' to access the site."
            }
        }
    }

    post {
        always {
            echo "Pipeline execution finished."
        }
        failure {
            echo "Pipeline failed. Check the logs above for 'lstat' or 'context' errors."
        }
    }
}