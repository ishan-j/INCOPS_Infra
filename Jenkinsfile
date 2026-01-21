pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "ishanj10"
        FRONTEND_IMAGE = "incops-frontend"
        BACKEND_IMAGE  = "incops-backend"
        KUBECONFIG = "$HOME/.kube/config"
    }

    stages {

        stage("Show Jenkinsfile") {
             steps {
                    sh '''
                    echo "================ JENKINSFILE CONTENT ================="
                       cat Jenkinsfile
                       echo "======================================================="
                       '''
                      }
                    }


        stage("Checkout Repos") {
            steps {
                cleanWs()
                dir("frontend") {
                    git credentialsId: 'github-creds',
                        url: 'https://github.com/ishan-j/INCOPS_Frontend.git'
                }
                dir("backend") {
                    git credentialsId: 'github-creds',
                        url: 'https://github.com/ishan-j/INCOPS_Backend.git'
                }
                dir("infra") {
                    git credentialsId: 'github-creds',
                        url: 'https://github.com/ishan-j/INCOPS_Infra.git'
                }
            }
        }

        stage("Build & Push Backend Image") {
            steps {
                dir("backend") {
                    script {
                        docker.withRegistry('', 'dockerhub-creds') {
                            def img = docker.build("${DOCKERHUB_USER}/${BACKEND_IMAGE}:latest")
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
                            def img = docker.build("${DOCKERHUB_USER}/${FRONTEND_IMAGE}:latest")
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
        success {
            echo "✅ INCOPS deployed successfully"
        }
        failure {
            echo "❌ Deployment failed — check logs"
        }
    }
}
