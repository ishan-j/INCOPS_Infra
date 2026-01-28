pipeline {
    agent any

    environment {
        DOCKERHUB_USER  = "ishanj10"
        FRONTEND_IMAGE  = "incops-frontend"
        BACKEND_IMAGE   = "incops-backend"
        // Stable path for Jenkins Kubeconfig
        KUBECONFIG      = "/var/lib/jenkins/.kube/config"
    }

    stages {
        stage("System Cleanup") {
            steps {
                echo "Reclaiming disk space..."
                sh 'docker system prune -f || true'
                cleanWs()
            }
        }

        stage("Checkout Repos") {
            steps {
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

        stage("Build & Push Images") {
            steps {
                script {
                    docker.withRegistry('', 'dockerhub-creds') {
                        // Backend
                        dir("backend") {
                            def backendImg = docker.build("${DOCKERHUB_USER}/${BACKEND_IMAGE}:latest")
                            backendImg.push()
                        }
                        // Frontend
                        // dir("frontend") {
                        //     def frontendImg = docker.build("${DOCKERHUB_USER}/${FRONTEND_IMAGE}:latest")
                        //     frontendImg.push()
                        // }
                    }
                }
            }
        }
        stage  ('Trivy Security Scan') {
            steps {
                script {
               
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') { 

                        sh "trivy image --skip-db-update --severity CRITICAL --no-progress ishanj10/incops-frontend"
                    }
                }
            }
        }

        stage("Deploy to K8s") {
            steps {
                sh '''
                    # 1. FIX THE DYNAMIC IP PROBLEM
                    # Generate a fresh config and force it to use localhost
                    mkdir -p /var/lib/jenkins/.kube
                    microk8s config | sed 's/https:\\/\\/.*:16443/https:\\/\\/127.0.0.1:16443/' > ${KUBECONFIG}
                    chmod 600 ${KUBECONFIG}

                    # 2. DEPLOY INFRASTRUCTURE (MySQL, Secrets, PVC, Ingress)
                    # Use --status-check or specific order to ensure DB is ready
                    kubectl apply -f infra/k8s/

                    # 3. DEPLOY APP
                    kubectl apply -f backend/k8s/
                    kubectl apply -f frontend/k8s/

                    # 4. FORCE RESTART APP (To pull newest images)
                    # We don't restart MySQL to avoid unnecessary downtime
                    kubectl rollout restart deployment backend
                    kubectl rollout restart deployment frontend
                '''
            }
        }
        
        stage("Verify Deployment") {
            steps {
                sh '''
                    echo "Checking Pod Status..."
                    kubectl get pods
                    echo "Checking Ingress Routing..."
                    kubectl get ingress app-ingress
                '''
            }
        }
    }

    post {
        always {
            echo "Cleaning up local images..."
            sh "docker rmi ${DOCKERHUB_USER}/${BACKEND_IMAGE}:latest || true"
            sh "docker rmi ${DOCKERHUB_USER}/${FRONTEND_IMAGE}:latest || true"
        }
        success {
            script {
                def vmIp = sh(script: "ip addr show ens33 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1", returnStdout: true).trim()
                echo "--------------------------------------------------------"
                echo "SUCCESS: App is deployed!"
                echo "URL: http://app.local"
                echo "Update your host file to: ${vmIp} app.local"
                echo "--------------------------------------------------------"
            }
        }
    }
}