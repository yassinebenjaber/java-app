pipeline {
    agent any
    tools {
        maven 'Maven-3.8.6'
    }

    environment {
        NEXUS_URL = 'localhost:8081'
        NEXUS_CREDENTIALS_ID = 'nexus-credentials'
        DOCKER_IMAGE_NAME = "localhost:5000/docker-hosted/my-java-app:${env.BUILD_NUMBER}"
        OSSINDEX_USERNAME = 'yassinejaber99@outlook.com'
        NAMESPACE = 'my-app-preprod'
        DAST_NETWORK = 'dast-net'
        DAST_TARGET_NAME = 'my-app-dast-target'
    }

    stages {
        stage('Scan for Secrets') {
            steps {
                sh '''
                    docker run --rm --name gitleaks-scanner \\
                        -v $PWD:/workspace \\
                        zricethezav/gitleaks:latest detect --source /workspace --verbose --no-git
                '''
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('SCA Scan') {
            steps {
                withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY'),
                                 string(credentialsId: 'ossindex-token', variable: 'OSSINDEX_TOKEN')]) {
                    sh '''
                        mvn org.owasp:dependency-check-maven:check \\
                            -Dnvd.apiKey="${NVD_API_KEY}" \\
                            -Dossindex.analyzer.enabled=true \\
                            -Dossindex.username="${OSSINDEX_USERNAME}" \\
                            -Dossindex.apiToken="${OSSINDEX_TOKEN}" \\
                            -DfailBuildOnCVSS=11.0
                    '''
                }
            }
        }

        stage('SAST Scan') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Publish Maven Artifact') {
            steps {
                withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh 'mvn deploy -Dmaven.test.skip=true --settings settings.xml'
                }
            }
        }

        stage('Build Container Image') {
            steps {
                script {
                    docker.build(DOCKER_IMAGE_NAME, '.')
                }
            }
        }

        stage('Scan Container Image') {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        sh "trivy image --exit-code 1 --format table --output trivy-report.txt --severity HIGH,CRITICAL ${DOCKER_IMAGE_NAME}"
                    }
                    if (currentBuild.currentResult == 'UNSTABLE') {
                        def report = readFile 'trivy-report.txt'
                        emailext (
                            subject: "Vulnerability Alert for ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                            body: """<h1>Trivy Scan Report</h1><p>Vulnerabilities found.</p><pre>${report}</pre>""",
                            to: "yassinejaber99@outlook.com",
                            mimeType: 'text/html'
                        )
                    }
                }
            }
        }

        stage('Push Container Image') {
            steps {
                script {
                    docker.withRegistry('http://localhost:5000', NEXUS_CREDENTIALS_ID) {
                        docker.image(DOCKER_IMAGE_NAME).push()
                    }
                }
            }
        }
        
        stage('DAST Scan') {
            steps {
                sh "docker network create ${DAST_NETWORK} || true"
                sh "docker run -d --rm --name ${DAST_TARGET_NAME} --network ${DAST_NETWORK} ${DOCKER_IMAGE_NAME}"
                sleep 20
                sh "docker run --rm --network ${DAST_NETWORK} zaproxy/zap-stable:2.16.1 zap-baseline.py -t http://${DAST_TARGET_NAME}:8080 -I"
            }
            post {
                always {
                    sh "docker stop ${DAST_TARGET_NAME} || true"
                    sh "docker network rm ${DAST_NETWORK} || true"
                }
            }
        }
        
        stage('Shut down Sonarqube') {
            steps {
                echo 'Stopping SonarQube container to free up memory for Minikube...'
                sh 'cd /vagrant && docker compose stop sonarqube'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh 'minikube status || minikube start --driver=docker'
                    sh 'eval $(minikube -p minikube docker-env)'
                    
                    sh 'kubectl create namespace ${NAMESPACE} || true'
                    sh "sed -i 's|image: .*|image: ${DOCKER_IMAGE_NAME}|g' deployment.yaml"
                    
                    sh 'kubectl apply -f deployment.yaml -n ${NAMESPACE}'
                    sh 'kubectl apply -f service.yaml -n ${NAMESPACE}'
                    sh 'kubectl rollout status deployment/my-app-deployment -n ${NAMESPACE}'
                }
            }
        }

        stage('Monitoring + Health Check') {
            steps {
                script {
                    sleep 15
                    
                    sh 'minikube service my-app-service -n ${NAMESPACE} --url > service_url.txt'
                    def APP_URL = readFile('service_url.txt').trim()
                    
                    echo "---"
                    echo "Application is running at: ${APP_URL}"
                    echo "Checking application health..."
                    
                    sh "curl -sS --fail ${APP_URL}/actuator/health"
                    
                    echo "Application is healthy!"
                    echo "---"
                    echo "View your monitoring dashboards:"
                    echo "Prometheus Targets: http://localhost:9090"
                    echo "Grafana Dashboard:  http://localhost:3000"
                }
            }
        }
    }

    post {
        always {
            script {
                echo 'Restarting SonarQube container...'
                sh 'cd /vagrant && docker compose start sonarqube'
            }
        }
    }
}
```eof