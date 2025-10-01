// Jenkinsfile - Java/Maven Edition
pipeline {
    agent any
    tools {
        maven 'Maven-3.8.6' // The name from Jenkins Global Tool Configuration
    }

    environment {
        NEXUS_URL = 'localhost:8081'
        NEXUS_CREDENTIALS_ID = 'nexus-credentials'
        SONAR_TOKEN = credentials('sonarqube-token-id')
        DOCKER_IMAGE_NAME = "localhost:5000/docker-hosted/my-java-app:${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                // !!! IMPORTANT: CHANGE THIS TO YOUR REPO URL !!!
                git 'https://github.com/your-username/your-java-repo.git'
            }
        }

        stage('Scan for Secrets (Gitleaks)') {
            steps {
                docker.image('zricethezav/gitleaks:latest').inside {
                    sh 'gitleaks detect --source . --verbose --no-git || exit 0'
                }
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('SCA Scan (OWASP Dependency Check)') {
            steps {
                sh 'mvn org.owasp:dependency-check-maven:check'
            }
            post {
                always {
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'target',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'OWASP Dependency-Check Report'
                    ])
                }
            }
        }

        stage('SAST Scan & Quality Gate (SonarQube)') {
            steps {
                sh 'mvn sonar:sonar'
            }
            post {
                always {
                    timeout(time: 1, unit: 'HOURS') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage('Publish Artifact to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'NEXUS3',
                    protocol: 'http',
                    nexusUrl: NEXUS_URL,
                    groupId: 'com.devsecops.jobprep',
                    version: "1.${env.BUILD_NUMBER}",
                    repository: 'maven-releases',
                    credentialsId: NEXUS_CREDENTIALS_ID,
                    artifacts: [
                        [artifactId: 'my-app',
                         classifier: '',
                         file: "target/my-app-0.0.1-SNAPSHOT.jar",
                         type: 'jar']
                    ]
                )
            }
        }

        stage('Build & Scan Docker Image (Trivy)') {
            steps {
                script {
                    def customImage = docker.build(DOCKER_IMAGE_NAME, '.')
                    sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${DOCKER_IMAGE_NAME}"
                }
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                script {
                    docker.withRegistry('http://localhost:5000', NEXUS_CREDENTIALS_ID) {
                        docker.image(DOCKER_IMAGE_NAME).push()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh 'minikube status || minikube start --driver=docker'
                    sh 'eval $(minikube -p minikube docker-env)'
                    sh "sed -i 's|image: .*|image: ${DOCKER_IMAGE_NAME}|g' deployment.yaml"
                    sh 'kubectl apply -f deployment.yaml'
                    sh 'kubectl apply -f service.yaml'
                    sh 'kubectl rollout status deployment/my-app-deployment'
                }
            }
        }
        
        stage('DAST Scan (OWASP ZAP)') {
            steps {
                script {
                    sh 'minikube service my-app-service --url > service_url.txt'
                    def APP_URL = readFile('service_url.txt').trim()
                    sleep 15
                    sh "docker run --rm --network=host owasp/zap2docker-stable zap-baseline.py -t ${APP_URL}"
                }
            }
        }
    }
}
