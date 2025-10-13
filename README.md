# DevSecOps Pipeline Project

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()
[![SonarQube](https://img.shields.io/badge/SAST-SonarQube-blue)]()
[![Trivy](https://img.shields.io/badge/DAST-Trivy-orange)]()
[![Nexus](https://img.shields.io/badge/Artifacts-Nexus-red)]()
[![Kubernetes](https://img.shields.io/badge/K8s-Deployment-blueviolet)]()
[![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-yellow)]()
[![Grafana](https://img.shields.io/badge/Monitoring-Grafana-orange)]()

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

