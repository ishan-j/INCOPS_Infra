pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "ishanj10"
        FRONTEND_IMAGE = "incops-frontend"
        BACKEND_IMAGE  = "incops-backend"
        // Fixed: Use curly braces for environment variables to avoid issues
        KUBECONFIG = "${HOME}/.kube/config"
    }

    stages {
        // NEW: Cleanup stage to fix your < 1GB disk space issue
        stage("System Cleanup") {
            steps {
                echo "Reclaiming disk space..."
                sh 'docker system prune -f || true'
                // Optional: Clean up workspace from previous failed runs
                cleanWs()
            }
        }

        stage("Checkout Repos") {
    steps {
        dir("frontend") {
            git credentialsId: 'github-creds', 
                url: 'https://github.com/ishan-j/INCOPS_Frontend.git',
                branch: 'main'  // Change to 'master' if your repo actually uses master
        }
        dir("backend") {
            git credentialsId: 'github-creds', 
                url: 'https://github.com/ishan-j/INCOPS_Backend.git',
                branch: 'main'
        }
        dir("infra") {
            git credentialsId: 'github-creds', 
                url: 'https://github.com/ishan-j/INCOPS_Infra.git',
                branch: 'main'
        }
    }
}

        stage("Build & Push Backend Image") {
            steps {
                dir("backend") {
                    script {
                        docker.withRegistry('', 'dockerhub-creds') {
                            /* FIX: Pointing to the specific Dockerfile path 
                               '-f' specifies the file, '.' is the build context
                            */
                            def img = docker.build("${DOCKERHUB_USER}/${BACKEND_IMAGE}:latest", "-f docker/backend.Dockerfile .")
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
                            // Assuming Frontend follows the same pattern: docker/frontend.Dockerfile
                            def img = docker.build("${DOCKERHUB_USER}/${FRONTEND_IMAGE}:latest", "-f docker/frontend.Dockerfile .")
                            img.push()
                        }
                    }
                }
            }
        }

        stage("Deploy MySQL & Infra") {
            steps {
                dir("infra/k8s") {
                    sh """
                    kubectl apply -f mysql-secret.yaml
                    kubectl apply -f mysql-deployment.yaml
                    kubectl apply -f mysql-service.yaml
                    kubectl apply -f ingress.yaml
                    """
                }
            }
        }

        stage("Deploy Backend") {
            steps {
                // Ensure this path matches your Backend repo structure
                dir("backend/k8s") {
                    sh """
                    kubectl apply -f backend-deployment.yaml
                    kubectl apply -f backend-service.yaml
                    kubectl rollout restart deployment backend
                    """
                }
            }
        }

        stage("Deploy Frontend") {
            steps {
                dir("frontend/k8s") {
                    sh """
                    kubectl apply -f frontend-deployment.yaml
                    kubectl apply -f frontend-service.yaml
                    kubectl rollout restart deployment frontend
                    """
                }
            }
        }
    }

    post {
        always {
            // Clean up the image from the Jenkins agent to save space for the next run
            sh "docker rmi ${DOCKERHUB_USER}/${BACKEND_IMAGE}:latest || true"
            sh "docker rmi ${DOCKERHUB_USER}/${FRONTEND_IMAGE}:latest || true"
        }
        success {
            echo "✅ INCOPS deployed successfully"
        }
        failure {
            echo "❌ Deployment failed — check logs"
        }
    }
}