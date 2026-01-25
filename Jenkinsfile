pipeline {
    agent any

    environment {
        DOCKERHUB_USER  = "ishanj10"
        FRONTEND_IMAGE  = "incops-frontend"
        BACKEND_IMAGE   = "incops-backend"
        KUBECONFIG      = "/var/lib/jenkins/.kube/config"
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
                dir("frontend") {
                    git credentialsId: 'github-creds',
                        url: 'https://github.com/ishan-j/INCOPS_Frontend.git',
                        branch: 'main'
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

        stage("SAST with CodeQL") {
            steps {
                sh "rm -f *.sarif"
                sh """
                codeql database create backend-db --language=javascript --source-root=backend --overwrite
                codeql database analyze backend-db codeql/javascript-queries:codeql-suites/javascript-security-and-quality.qls --format=sarif-latest --output=backend-report.sarif
                codeql database create frontend-db --language=javascript --source-root=frontend --overwrite
                codeql database analyze frontend-db codeql/javascript-queries:codeql-suites/javascript-security-and-quality.qls --format=sarif-latest --output=frontend-report.sarif
                
                """
            }
        }

        stage("Build & Push Backend Image") {
            steps {
                dir("backend") {
                    script {
                        docker.withRegistry('', 'dockerhub-creds') {
                            def img = docker.build(
                                "${DOCKERHUB_USER}/${BACKEND_IMAGE}:latest",
                                "."
                            )
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
                            def img = docker.build(
                                "${DOCKERHUB_USER}/${FRONTEND_IMAGE}:latest",
                                "."
                            )
                            img.push()
                        }
                    }
                }
            }
        }

        stage("Deploy to K8s") {
            steps {
                sh '''
                    kubectl apply -f infra/k8s/
                    kubectl apply -f backend/k8s/
                    kubectl apply -f frontend/k8s/

                    kubectl rollout restart deployment backend
                    kubectl rollout restart deployment frontend
                '''
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: '*.sarif', fingerprint: true
           
        }
    }
}