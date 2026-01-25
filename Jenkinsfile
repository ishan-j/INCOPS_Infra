pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "ishanj10"
        FRONTEND_IMAGE = "incops-frontend"
        BACKEND_IMAGE  = "incops-backend"
        KUBECONFIG     = "/var/lib/jenkins/.kube/config"

        // CodeQL
        CODEQL_HOME = "/opt/codeql"
        PATH = "/opt/codeql:${env.PATH}"
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

        stage("CodeQL Scan Backend") {
            steps {
                dir("backend") {
                    sh '''
                        rm -rf codeql-db-backend || true

                        codeql database create codeql-db-backend \
                            --language=javascript \
                            --source-root=.

                        codeql database analyze codeql-db-backend \
                            --suite=security-and-quality \
                            --format=sarifv2 \
                            --output=codeql-backend.sarif
                    '''
                }
            }
        }

        stage("CodeQL Scan Frontend") {
            steps {
                dir("frontend") {
                    sh '''
                        rm -rf codeql-db-frontend || true

                        codeql database create codeql-db-frontend \
                            --language=javascript \
                            --source-root=.

                        codeql database analyze codeql-db-frontend \
                            --suite=security-and-quality \
                            --format=sarifv2 \
                            --output=codeql-frontend.sarif
                    '''
                }
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
        always {
            archiveArtifacts artifacts: '**/codeql-*.sarif', allowEmptyArchive: true

            // Free disk space
            sh "docker rmi ${DOCKERHUB_USER}/${BACKEND_IMAGE}:latest || true"
            sh "docker rmi ${DOCKERHUB_USER}/${FRONTEND_IMAGE}:latest || true"
        }
    }
}
