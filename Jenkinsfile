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
                        dir("backend") {
                            def backendImg = docker.build("${DOCKERHUB_USER}/${BACKEND_IMAGE}:latest")
                            backendImg.push()
                        }
                        
                        // dir("frontend") {
                        //     def frontendImg = docker.build("${DOCKERHUB_USER}/${FRONTEND_IMAGE}:latest")
                        //     frontendImg.push()
                        // }
                    }
                }
            }
        }

        stage('Trivy Security Scan') {
            steps {
                script {
                   
                    sh "mkdir -p reports"
                    sh "trivy clean --scan-cache"
                    
                    
                    sh """
                    trivy image --skip-db-update --no-progress --scanners vuln --exit-code 0 --severity HIGH,CRITICAL ${DOCKERHUB_USER}/${BACKEND_IMAGE}:latest > reports/trivy-backend-report.txt || true
                    trivy image --skip-db-update --no-progress --scanners vuln --exit-code 0 --severity HIGH,CRITICAL ${DOCKERHUB_USER}/${FRONTEND_IMAGE}:latest > reports/trivy-frontend-report.txt || true
                    """
                    archiveArtifacts artifacts: 'reports/*.txt', fingerprint: true
                }
            }
        }

        stage("Deploy to K8s") {
            steps {
                sh '''
                    mkdir -p /var/lib/jenkins/.kube
                    microk8s config | sed 's/https:\\/\\/.*:16443/https:\\/\\/127.0.0.1:16443/' > ${KUBECONFIG}
                    chmod 600 ${KUBECONFIG}

                    kubectl apply -f infra/k8s/
                    kubectl apply -f backend/k8s/
                    kubectl apply -f frontend/k8s/

                    kubectl rollout restart deployment backend || true
                    kubectl rollout restart deployment frontend || true
                '''
            }
        }

        stage('DAST') {
            steps {

                sh '''
                    echo "Starting Frontend Scan..."
                    docker run --user root --rm -v $(pwd)/reports:/zap/wrk/:rw \
                        zaproxy/zap-stable zap-baseline.py \
                        -t http://app.local \
                        -I -r zap-frontend-report.html || true
                    echo "Starting Backend Scan..."
                    docker run --user root --rm -v $(pwd)/reports:/zap/wrk/:rw \
                        zaproxy/zap-stable zap-baseline.py \
                        -t http://app.local/api \
                        -I -r zap-backend-report.html || true
                '''
                archiveArtifacts artifacts: 'reports/zap-*.html', fingerprint: true
            }


        }
        
        stage("Verify & Monitor") {
            steps {
                sh '''
                    echo "Checking Pod Status..."
                    kubectl get pods
                    
                    echo "--- Prometheus Health Check ---"
                    # We check if Prometheus service is reachable and query the 'up' status
                    # This assumes microk8s observability is enabled
                    curl -s "http://localhost:9090/api/v1/query?query=up" | grep "status\":\"success" || echo "Prometheus not reachable yet"
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
                def vmIp = sh(script: "ip addr show ens33 2>/dev/null | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1 || echo 'VM_IP'", returnStdout: true).trim()
                echo "--------------------------------------------------------"
                echo "SUCCESS: App is deployed!"
                echo "Monitoring: http://${vmIp}:3000 (Grafana)"
                echo "App URL: http://app.local"
                echo "--------------------------------------------------------"
            }
        }
    }
}