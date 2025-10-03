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
        PREPROD_NAMESPACE = 'my-app-preprod'
        PROD_NAMESPACE = 'my-app-prod'
        DAST_NETWORK = 'dast-net'
        DAST_TARGET_NAME = 'my-app-dast-target'
    }

    stages {
        stage('Scan for Secrets & Static Analysis') {
            parallel {
                stage('Gitleaks') {
                    steps {
                        sh '''
                            docker run --rm --name gitleaks-scanner \\
                                -v $PWD:/workspace \\
                                zricethezav/gitleaks:latest detect --source /workspace --verbose --no-git
                        '''
                    }
                }
                stage('SAST & SCA') {
                    steps {
                        sh 'mvn clean install'
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
                        withSonarQubeEnv('sonarqube') {
                            sh 'mvn sonar:sonar'
                        }
                    }
                }
            }
        }

        stage('Publish Artifacts & Containerize') {
            steps {
                withCredentials([usernamePassword(credentialsId: NEXUS_CREDENTIALS_ID, usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    // 1. Deploy the Maven artifact to Nexus
                    sh 'mvn deploy -Dmaven.test.skip=true --settings settings.xml'

                    // 2. Build the Docker image using a raw shell command
                    sh "docker build -t ${DOCKER_IMAGE_NAME} ."
                    
                    // 3. Scan the newly built image with Trivy
                    sh "trivy image --severity CRITICAL ${DOCKER_IMAGE_NAME}"

                    // 4. Log in and push the Docker image to Nexus
                    sh "echo '${NEXUS_PASS}' | docker login http://localhost:5000 -u '${NEXUS_USER}' --password-stdin"
                    sh "docker push ${DOCKER_IMAGE_NAME}"
                }
            }
        }
        
        stage('Dynamic Analysis (DAST)') {
            steps {
                sh "docker network create ${DAST_NETWORK} || true"
                sh "docker run -d --rm --name ${DAST_TARGET_NAME} --network ${DAST_NETWORK} ${DOCKER_IMAGE_NAME}"
                sleep 20
                sh "docker run --rm --network ${DAST_NETWORK} owasp/zap2docker-stable zap-baseline.py -t http://${DAST_TARGET_NAME}:8080"
            }
            post {
                always {
                    sh "docker stop ${DAST_TARGET_NAME} || true"
                    sh "docker network rm ${DAST_NETWORK} || true"
                }
            }
        }
        
        stage('Deploy to Pre-Prod') {
            steps {
                script {
                    echo 'Stopping SonarQube container to free up memory for Minikube...'
                    sh 'cd /vagrant && docker compose stop sonarqube'
                    
                    sh 'minikube status || minikube start --driver=docker'
                    sh 'eval $(minikube -p minikube docker-env)'
                    
                    sh 'kubectl create namespace ${PREPROD_NAMESPACE} || true'
                    sh "sed -i 's|image: .*|image: ${DOCKER_IMAGE_NAME}|g' deployment.yaml"
                    
                    sh 'kubectl apply -f deployment.yaml -n ${PREPROD_NAMESPACE}'
                    sh 'kubectl apply -f service.yaml -n ${PREPROD_NAMESPACE}'
                    sh 'kubectl rollout status deployment/my-app-deployment -n ${PREPROD_NAMESPACE}'
                }
            }
        }

        stage('Approval for Production') {
            steps {
                input message: 'All tests passed on Pre-Prod. Ready to deploy to Production?', submitter: 'admin'
            }
        }

        stage('Deploy to Production') {
            steps {
                script {
                    sh 'kubectl create namespace ${PROD_NAMESPACE} || true'
                    sh 'kubectl apply -f deployment.yaml -n ${PROD_NAMESPACE}'
                    sh 'kubectl apply -f service.yaml -n ${PROD_NAMESPACE}'
                    sh 'kubectl rollout status deployment/my-app-deployment -n ${PROD_NAMESPACE}'
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