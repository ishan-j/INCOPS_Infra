pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "ishanj10"
        FRONTEND_IMAGE = "incops-frontend"
        BACKEND_IMAGE  = "incops-backend"
    }

    stages {
        stage("System Cleanup") {
            steps {
                echo "Reclaiming disk space before build..."
                sh 'docker system prune -f || true'
                cleanWs()
            }
        }

        stage("Checkout Repos") {
            steps {
                // Specifying 'main' - change to 'master' if needed
                dir("frontend") {
                    git credentialsId: 'github-creds', url: 'https://github.com/ishan-j/INCOPS_Frontend.git', branch: 'main'
                }
                dir("backend") {
                    git credentialsId: 'github-creds', url: 'https://github.com/ishan-j/INCOPS_Backend.git', branch: 'main'
                }
                dir("infra") {
                    git credentialsId: 'github-creds', url: 'https://github.com/ishan-j/INCOPS_Infra.git', branch: 'main'
                }
            }
        }

        stage("Build & Push Backend Image") {
            steps {
                dir("backend") {
                    script {
                        docker.withRegistry('', 'dockerhub-creds') {
                            // Because the file is named 'Dockerfile', we don't need the -f flag
                            def img = docker.build("${DOCKERHUB_USER}/${BACKEND_IMAGE}:latest", ".")
                            img.push()
                        }
                    }
                }
            }
        }

        stage("Build & Push Frontend Image") {
            steps {
                dir("frontend") {
                    script {
                        docker.withRegistry('', 'dockerhub-creds') {
                            def img = docker.build("${DOCKERHUB_USER}/${FRONTEND_IMAGE}:latest", ".")
                            img.push()
                        }
                    }
                }
            }
        }

        stage("Deploy to K8s") {
            steps {
                // Deploying all at once
                sh """
                kubectl apply -f infra/k8s/
                kubectl apply -f backend/k8s/
                kubectl apply -f frontend/k8s/
                kubectl rollout restart deployment backend
                kubectl rollout restart deployment frontend
                """
            }
        }
    }

    post {
        always {
            // CRITICAL: Remove the local images after pushing to save your 1GB disk space
            sh "docker rmi ${DOCKERHUB_USER}/${BACKEND_IMAGE}:latest || true"
            sh "docker rmi ${DOCKERHUB_USER}/${FRONTEND_IMAGE}:latest || true"
        }
    }
}