# Automate Provisioning and Deployment with Jenkins, Terraform, and Ansible

This repository contains a complete CI/CD pipeline setup to provision AWS infrastructure using **Terraform**, configure instances and deploy applications using **Ansible**, all orchestrated by **Jenkins**. The pipeline securely manages SSH keys, establishes passwordless SSH access, and handles AWS CLI installation on EC2 instances.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
  - [1. Jenkins Credentials Setup](#1-jenkins-credentials-setup)
  - [2. Terraform Infrastructure Provisioning](#2-terraform-infrastructure-provisioning)
  - [3. Fetching Terraform Outputs](#3-fetching-terraform-outputs)
  - [4. Ansible Inventory Generation](#4-ansible-inventory-generation)
  - [5. Establish Passwordless SSH](#5-establish-passwordless-ssh)
  - [6. AWS CLI Installation on EC2](#6-aws-cli-installation-on-ec2)
  - [7. Docker Image Deployment](#7-docker-image-deployment)
- [Jenkins Pipeline](#jenkins-pipeline)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Overview

- **Terraform** provisions EC2 instances, VPC, subnets, and networking components.
- **Jenkins** runs the pipeline to initialize Terraform, apply infrastructure changes, and trigger Ansible.
- **Ansible** configures EC2 instances, installs AWS CLI, pulls Docker images, and runs containers.
- SSH keys are securely managed via Jenkins credentials, with passwordless SSH established automatically.
- The pipeline handles common issues like SSH readiness, Python environment restrictions, and AWS CLI installation quirks.

---

## Prerequisites

- Jenkins server with:
  - **Pipeline Utility Steps Plugin** (for `readJSON`)
  - **SSH Agent Plugin** (optional but recommended)
- AWS account with proper IAM permissions
- Terraform installed on Jenkins agents
- Ansible installed on Jenkins agents
- Docker installed on EC2 instances
- PEM private key file for EC2 SSH access

---

## Setup Instructions

### 1. Jenkins Credentials Setup

- Add your PEM private key as a **Secret file** credential in Jenkins.
  - ID example: `terraform_ansible.pem`
- This key will be injected securely into the pipeline as an environment variable.
- Add the github token as the **username and password** credentials in jenkins
  - ID : `github-repo`
- This key will be injected securely into the pipeline to pull the code 
- Jenkins `Pipeline Utility Steps` Plugin install on jenkins console.

### 2. Terraform Infrastructure Provisioning

- Use Terraform code to define AWS infrastructure.
- Outputs should include:
  - `ec2_instance_ids`
  - `ec2_instance_public_ips`
  - Network components (VPC, subnets, route tables)
- Run `terraform init`, `plan`, and `apply` in Jenkins pipeline.

### 3. Fetching Terraform Outputs

- Use `terraform output -json ec2_instance_public_ips` to get instance IPs.
- Store output JSON in an environment variable for later use.

### 4. Ansible Inventory Generation

- Parse the JSON IP list with `readJSON`.
- Generate a dynamic inventory YAML file inside the `ansible` directory.
- Reference the PEM file path securely in inventory using environment variables.

### 5. Establish Passwordless SSH

- Generate the public key from PEM file if not already present.
- Wait for SSH availability on each EC2 instance before copying keys.
- Use `ssh-copy-id` to copy the public key to EC2 instances.
- Handle known_hosts cleanup with `ssh-keygen -R`.
- Retry SSH connection until success to avoid timing issues.

### 6. AWS CLI Installation on EC2

- Install `unzip` package first to extract AWS CLI installer.
- Download AWS CLI v2 installer using `curl` (avoid Ansible `get_url` due to Python 3.12+ issues).
- Extract and install AWS CLI v2 using the official bundled installer.
- Avoid installing AWS CLI via `pip` or `apt` to prevent environment conflicts.

### 7. Docker Image Deployment

- Define Docker images and container metadata in variables without Jinja2 templating inside.
- Pull Docker images using `docker pull`.
- Run Docker containers conditionally based on inventory hostname.
- Prefer using Ansible `community.docker` modules for idempotency.

---

## Jenkins Pipeline


---

## Best Practices

- **Secure PEM key management:** Use Jenkins credentials and avoid printing secrets.
- **Wait for SSH readiness:** Retry SSH connections before copying keys.
- **Use official AWS CLI installer:** Avoid pip/apt for AWS CLI v2.
- **Avoid Jinja2 in variables:** Build commands dynamically in tasks.
- **Use Ansible modules for Docker:** Prefer `community.docker` modules for idempotency.
- **Isolate Ansible directory:** Keep inventory and playbooks organized under `ansible/`.

---

## Troubleshooting

| Issue                                  | Cause                                         | Solution                                     |
|---------------------------------------|-----------------------------------------------|----------------------------------------------|
| `No such DSL method 'readJSON'`       | Missing Pipeline Utility Steps Plugin          | Install plugin in Jenkins                     |
| PEM file path masked as `****`         | Groovy string interpolation with secrets       | Use single quotes and `$PEM_FILE` in shell   |
| SSH-copy-id fails first run             | SSH service not ready on EC2                    | Add SSH wait/retry loop before copying keys  |
| AWS CLI install errors                  | Python 3.12+ PEP 668 restrictions              | Use official AWS CLI v2 bundled installer     |
| `unzip` command missing                 | `unzip` not installed on EC2                    | Install `unzip` package via apt               |
| Jinja2 templating inside variables      | Ansible does not recursively render variables   | Build commands in tasks, not in variable defs|

---

## References

- [Jenkins Pipeline Utility Steps Plugin](https://plugins.jenkins.io/pipeline-utility-steps/)
- [Ansible Docker Collection](https://docs.ansible.com/ansible/latest/collections/community/docker/docker_container_module.html)
- [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [PEP 668 – Python Packaging](https://peps.python.org/pep-0668/)
- [Ansible wait_for Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/wait_for_module.html)

---


## Author

Chandramani 

---

Overview:
![alt text](<Project.png>)