// Jenkinsfile - Final Corrected Version
pipeline {
    agent any
    tools {
        maven 'Maven-3.8.6'
    }

    environment {
        // Global variables that are NOT secrets
        NEXUS_URL = 'localhost:8081'
        NEXUS_CREDENTIALS_ID = 'nexus-credentials'
        DOCKER_IMAGE_NAME = "localhost:5000/docker-hosted/my-java-app:${env.BUILD_NUMBER}"
        OSSINDEX_USERNAME = 'your-email@example.com' // <-- IMPORTANT: Replace with your Sonatype email
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/yassinebenjaber/java-app.git'
            }
        }

        stage('Scan for Secrets (Gitleaks)') {
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

        stage('SCA Scan (OWASP Dependency Check)') {
            steps {
                // This block securely injects credentials as shell environment variables
                // and passes them directly to Maven using the -D flag. This is the fix.
                withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY'),
                                 string(credentialsId: 'ossindex-token', variable: 'OSSINDEX_TOKEN')]) {
                    sh '''
                        mvn org.owasp:dependency-check-maven:check \\
                            -DnvdApiKey="${NVD_API_KEY}" \\
                            -DossindexAnalyzerEnabled=true \\
                            -DossindexUsername="${OSSINDEX_USERNAME}" \\
                            -DossindexApiToken="${OSSINDEX_TOKEN}" \\
                            -DfailBuildOnCVSS=7.0
                    '''
                }
            }
        }

        stage('SAST Scan & Quality Gate (SonarQube)') {
            steps {
                // Securely injects the SonarQube token and passes it directly to Maven.
                withCredentials([string(credentialsId: 'sonarqube-token-id', variable: 'SONAR_TOKEN')]) {
                    sh 'mvn sonar:sonar -Dsonar.login="${SONAR_TOKEN}"'
                }
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