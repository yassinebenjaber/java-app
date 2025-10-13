# DevSecOps Pipeline Project

[![Code Scanning](https://img.shields.io/badge/Code%20Scanning-GitLeaks-red)](https://github.com/zricethezav/gitleaks)
[![SCA](https://img.shields.io/badge/SCA-OWASP_Dependency_Check-blue)](https://owasp.org/www-project-dependency-check/)
[![SAST](https://img.shields.io/badge/SAST-SonarQube-brightgreen)](https://www.sonarqube.org/)
[![IaC Security](https://img.shields.io/badge/IaC-Checkov-orange)](https://www.checkov.io/)
[![Artifact Management](https://img.shields.io/badge/Artifacts-Nexus-red)](https://help.sonatype.com/repomanager3)
[![Container Scanning](https://img.shields.io/badge/Container-Trivy-purple)](https://aquasec.com/trivy)
[![DAST](https://img.shields.io/badge/DAST-OWASP_ZAP-yellow)](https://www.zaproxy.org/)
[![Kubernetes](https://img.shields.io/badge/Deployment-Kubernetes-blueviolet)](https://kubernetes.io/)
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%26%20Grafana-lightgrey)](https://prometheus.io/)


> End-to-end **DevSecOps pipeline** automating security, artifact management, containerization, and Minikube deployment.

---

## 📖 Table of Contents
- [Overview](#overview)
- [Pipeline Workflow](#pipeline-workflow)
- [Tools & Technologies](#tools--technologies)
- [Challenges & Fixes](#challenges--fixes)
- [Future Work](#future-work)
- [Author](#author)

---

## 🛠️ Overview
This repository demonstrates a complete CI/CD pipeline for an application with:

- Automated security scanning (SAST, SCA, DAST, IaC)
- Docker containerization & image scanning
- Artifact management using Nexus
- Deployment to Kubernetes with monitoring via Prometheus & Grafana

> **Note:** Infrastructure provisioning (Vagrant/Ansible) is **not included** in this repo.

---

## 🔄 Pipeline Workflow

| Step | Tool | Description |
|------|------|-------------|
| **1. Secret Scanning** | GitLeaks | Scan source code for hard-coded secrets |
| **2. Build & Security Analysis** | Maven, OWASP Dependency Check, SonarQube, CycloneDX | Build app, SCA, SAST, generate SBOM |
| **3. IaC Security** | Checkov | Scan Dockerfile and Kubernetes manifests |
| **4. Docker & DAST** | Docker, Trivy | Build, scan, run container for DAST, push to Nexus |
| **5. Kubernetes Deployment** | kubectl, Prometheus, Grafana | Deploy app, monitor cluster and app |

---

## 🧰 Tools & Technologies

| Category | Tools |
|----------|------|
| CI/CD & Security | Jenkins, GitLeaks, SonarQube, OWASP Dependency Check, Checkov, Trivy, CycloneDX |
| Containers | Docker, Docker Compose, Minikube |
| Artifact Management | Nexus Repository |
| Monitoring | Prometheus, Grafana |
| Kubernetes | Deployment manifests, Service configuration |

---

## ⚠️ Challenges & Fixes

### Jenkins & Pipeline
- **Permission errors** → Added Jenkins user to Docker group & sudoers  
- **Unrecognized commands** → Installed Jenkins plugins (Docker Pipeline, SonarQube Scanner, Nexus Artifact Uploader)  
- **Port forwarding issues** → Ran `vagrant reload`  

### Security Scanning
- **SCA authentication errors** → Configured NVD & OSS Index API keys  
- **Plugin parsing errors** → Upgraded `dependency-check-maven` plugin  
- **DAST Docker image blocked** → Logged into Docker Hub & pre-pulled image  

### Artifact & Container Management
- **Nexus 405 error** → Changed repo policy to Allow redeploy  
- **Docker push refused** → Enabled HTTP connector & Docker Bearer Token Realm  
- **Trivy not found** → Installed Trivy  

### Kubernetes Deployment
- **Deployment hanging** → Increased VM resources & temporarily stopped SonarQube  
- **Rollout status failed** → Fixed deployment name typos  
- **Stuck pods** → Added cleanup step to delete old deployments  

---

## 🔮 Future Work
- Integrate **Falco** for runtime scanning  
- Optimize resources for fully automated deployment  
- Extend pipeline to **multi-microservice architecture**

---

## 👤 Author
**Yassine ben Jaber**  
DevSecOps Enthusiast | Cybersecurity | Container Security  

