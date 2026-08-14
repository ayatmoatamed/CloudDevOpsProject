# Ansible — Jenkins EC2 Configuration

## Overview

This directory contains the Ansible automation used to configure the Jenkins EC2 instance provisioned by Terraform.

The purpose of this configuration is to automate the installation and basic setup of the software required by the Jenkins CI environment.

The playbook uses:

* Ansible Roles
* Dynamic Inventory
* AWS EC2 discovery
* SSH
* Amazon Linux 2023 package management
* Privilege escalation

The configuration installs:

* Java 21
* Jenkins
* Docker
* Trivy

---

## Configuration Flow

The Ansible workflow is:

```text
AWS
 │
 │ EC2 instances
 ▼
Dynamic Inventory
 │
 │ discovers Jenkins EC2
 ▼
Ansible
 │
 ▼
Jenkins Role
 │
 ├── Install Java
 ├── Add Jenkins Repository
 ├── Install Jenkins
 ├── Start Jenkins
 ├── Install Docker
 ├── Start Docker
 ├── Add Trivy Repository
 └── Install Trivy
```

---

## Why Ansible?

Terraform is responsible for creating the Jenkins EC2 instance, but Terraform should not be responsible for installing and configuring every package inside the server.

Ansible handles the configuration layer.

This creates a clear separation:

```text
Terraform → Infrastructure Provisioning
Ansible   → Server Configuration
```

---

## Directory Structure

```text
Ansible/
│
├── inventory.aws_ec2.yml
├── site.yaml
│
└── roles/
    └── jenkins/
        └── tasks/
            └── main.yaml
```

---

# Dynamic Inventory

The project uses the AWS EC2 Dynamic Inventory plugin instead of maintaining a static list of IP addresses.

The inventory file is:

```text
inventory.aws_ec2.yml
```

The plugin:

```yaml
plugin: amazon.aws.aws_ec2
```

allows Ansible to query AWS and discover EC2 instances dynamically.

The configured AWS region is:

```yaml
regions:
  - us-east-1
```

The inventory filters EC2 instances using the Jenkins server tag:

```yaml
filters:
  tag:Name: ivolve-jenkins-server
```

This means Ansible does not depend on a manually maintained IP address.

---

## SSH Configuration

The Jenkins EC2 instance is accessed using the EC2 private key.

The inventory specifies:

```yaml
compose:
  ansible_host: public_ip_address
  ansible_user: "'ec2-user'"
  ansible_ssh_private_key_file: "'/home/ayat/Downloads/ansible-key.pem'"
```

The `ec2-user` account is used because the Jenkins server runs Amazon Linux 2023.

The private key is stored locally and must **never be committed to GitHub**.

For another machine, the key path should be changed to the appropriate local path.

---

# Testing Dynamic Inventory

To display the discovered hosts:

```bash
ansible-inventory -i inventory.aws_ec2.yml --graph
```

The inventory should discover the Jenkins EC2 instance.

To test connectivity:

```bash
ansible all -i inventory.aws_ec2.yml -m ping
```

A successful result contains:

```text
SUCCESS
"ping": "pong"
```

This confirms that:

* AWS Dynamic Inventory works
* The Jenkins instance was discovered
* SSH authentication works
* Ansible can reach the EC2 instance

---

# Jenkins Role

The project follows the Ansible Role structure required by the task.

The Jenkins role is located at:

```text
roles/jenkins/
```

Its main task file is:

```text
roles/jenkins/tasks/main.yaml
```

The role contains the server configuration tasks.

---

## Java Installation

Jenkins requires Java to run.

The role installs Java 21 using the Amazon Linux package manager:

```yaml
- name: Install Java
  ansible.builtin.dnf:
    name: java-21-amazon-corretto
    state: present
```

`java-21-amazon-corretto` is the Amazon Corretto Java 21 package.

`dnf` is the package manager used by Amazon Linux 2023.

---

# Jenkins Installation

Jenkins is installed from the official Jenkins repository.

The official repository is added first:

```yaml
- name: Add Jenkins repository
  ansible.builtin.get_url:
    url: https://pkg.jenkins.io/redhat-stable/jenkins.repo
    dest: /etc/yum.repos.d/jenkins.repo
```

The repository GPG key is imported:

```yaml
- name: Import Jenkins GPG key
  ansible.builtin.rpm_key:
    key: https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    state: present
```

After the repository is available, Jenkins is installed:

```yaml
- name: Install Jenkins
  ansible.builtin.dnf:
    name: jenkins
    state: present
```

Finally, Jenkins is started and enabled:

```yaml
- name: Start Jenkins
  ansible.builtin.systemd:
    name: jenkins
    state: started
    enabled: true
```

`enabled: true` ensures that Jenkins starts automatically after a server reboot.

---

# Docker Installation

Docker is required because Jenkins will later be used to build Docker images as part of the CI/CD pipeline.

The role installs Docker:

```yaml
- name: Install Docker
  ansible.builtin.dnf:
    name: docker
    state: present
```

Then starts it and enables it at boot:

```yaml
- name: Start Docker
  ansible.builtin.systemd:
    name: docker
    state: started
    enabled: true
```

---

# Trivy Installation

Trivy is used later in the Jenkins CI pipeline to scan container images for known security vulnerabilities.

Trivy is not installed directly from the default Amazon Linux repository in this configuration.

Instead, the official Trivy repository is added:

```yaml
- name: Add Trivy repository
  ansible.builtin.yum_repository:
    name: trivy
    description: Trivy repository
    baseurl: https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
    enabled: true
    gpgcheck: true
    gpgkey: https://aquasecurity.github.io/trivy-repo/rpm/public.key
```

Then Trivy is installed:

```yaml
- name: Install Trivy
  ansible.builtin.dnf:
    name: trivy
    state: present
```

---

# Main Playbook

The main playbook is:

```text
site.yaml
```

Its purpose is to apply the Jenkins role to the EC2 host group discovered by the Dynamic Inventory.

Example:

```yaml
---
- name: Configure Jenkins server
  hosts: aws_ec2
  become: true

  roles:
    - jenkins
```

### `hosts`

```yaml
hosts: aws_ec2
```

selects the Ansible inventory group containing the discovered EC2 instance.

### `become`

```yaml
become: true
```

allows Ansible to execute tasks with elevated privileges.

This is required because package installation and system configuration require administrative privileges.

### `roles`

```yaml
roles:
  - jenkins
```

tells Ansible to execute the tasks defined in the Jenkins role.

---

# Running the Playbook

After verifying the Dynamic Inventory:

```bash
ansible-inventory -i inventory.aws_ec2.yml --graph
```

test connectivity:

```bash
ansible all -i inventory.aws_ec2.yml -m ping
```

Then execute the configuration playbook:

```bash
ansible-playbook -i inventory.aws_ec2.yml site.yaml
```

Ansible will connect to the Jenkins EC2 instance and execute the Jenkins role.

---

# Expected Result

A successful playbook run should finish with:

```text
failed=0
```

The target server should have:

```text
Java 21       ✓
Jenkins       ✓
Docker        ✓
Trivy         ✓
```

The services should also be running and enabled.

---

# Verification

After the playbook finishes, the Jenkins server can be tested through SSH.

Example:

```bash
ssh -i /path/to/ansible-key.pem ec2-user@<JENKINS_PUBLIC_IP>
```

Check Java:

```bash
java -version
```

Check Docker:

```bash
docker --version
```

Check Trivy:

```bash
trivy --version
```

Check Jenkins:

```bash
sudo systemctl status jenkins
```

Check Docker service:

```bash
sudo systemctl status docker
```

---

# Troubleshooting

## Jenkins package not found

If Ansible reports:

```text
No package jenkins available.
```

the Jenkins repository has not been added or refreshed correctly.

The Jenkins repository must be configured before running:

```bash
dnf install jenkins
```

The role handles this automatically.

---

## SSH Permission Denied

If Ansible reports:

```text
Permission denied (publickey)
```

check:

1. The EC2 key is the correct private key.
2. The key file exists.
3. The key has restricted permissions.

Example:

```bash
chmod 400 /path/to/ansible-key.pem
```

Test SSH manually:

```bash
ssh -i /path/to/ansible-key.pem ec2-user@<JENKINS_PUBLIC_IP>
```

---

## No Hosts Matched

If the playbook reports that no hosts matched, inspect the Dynamic Inventory:

```bash
ansible-inventory -i inventory.aws_ec2.yml --graph
```

Make sure the `hosts:` value in `site.yaml` matches an actual Ansible inventory group.

---

# Security

Never commit the following to GitHub:

```text
*.pem
private keys
AWS credentials
passwords
.env files
```

The SSH private key is required only on the machine running Ansible.

The `.pem` file should be excluded using `.gitignore`.

Example:

```gitignore
*.pem
```

---

# Validation Checklist

* [x] AWS Dynamic Inventory configured
* [x] Jenkins EC2 discovered dynamically
* [x] SSH connectivity verified
* [x] Ansible ping successful
* [x] Jenkins Ansible Role created
* [x] Java 21 installed
* [x] Jenkins repository configured
* [x] Jenkins installed
* [x] Jenkins service started
* [x] Jenkins enabled at boot
* [x] Docker installed
* [x] Docker service started
* [x] Docker enabled at boot
* [x] Trivy repository configured
* [x] Trivy installed
* [x] Playbook completed successfully
* [x] No failed Ansible tasks

---

# Relationship With Terraform

Terraform and Ansible have separate responsibilities in this project.

Terraform creates the Jenkins EC2 instance:

```text
Terraform
    │
    ▼
Jenkins EC2
    │
    ▼
Ansible Dynamic Inventory
    │
    ▼
Jenkins Role
    │
    ├── Java
    ├── Jenkins
    ├── Docker
    └── Trivy
```

This approach follows the Infrastructure as Code and Configuration Management separation of responsibilities.

Terraform provisions the infrastructure, while Ansible configures the operating system and required software.

