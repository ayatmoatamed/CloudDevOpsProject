# Terraform — AWS Infrastructure

## Overview

This directory contains the Terraform infrastructure code used to provision the AWS environment for the CloudDevOpsProject.

The infrastructure is designed using reusable Terraform modules and follows a modular approach so that each major AWS component can be managed independently.

The Terraform configuration provisions the networking layer, Jenkins server, Amazon EKS cluster, and Amazon ECR repository.

Terraform state is stored remotely using an Amazon S3 backend.

---

## Architecture

The infrastructure is divided into four main modules:

```text
Terraform
│
├── Network Module
│   ├── VPC
│   ├── Public Subnet
│   ├── Private Subnet 1
│   ├── Private Subnet 2
│   ├── Internet Gateway
│   ├── NAT Gateway
│   ├── Route Tables
│   ├── Elastic IP
│   └── Network ACLs
│
├── Server Module
│   ├── Jenkins EC2 Instance
│   └── Jenkins Security Group
│
├── EKS Module
│   ├── EKS Cluster
│   ├── Cluster IAM Role
│   ├── Worker Node IAM Role
│   └── EKS Managed Node Group
│
└── ECR Module
    └── ECR Repository
```

### High-Level Architecture

```text
                         AWS
                          │
                    ┌─────┴─────┐
                    │    VPC    │
                    └─────┬─────┘
                          │
             ┌────────────┴────────────┐
             │                         │
       Public Subnet             Private Subnets
             │                    ┌────┴────┐
             │                    │         │
        Jenkins EC2          EKS Node 1  EKS Node 2
             │                    │         │
             │                    └────┬────┘
             │                         │
             │                    EKS Cluster
             │
       Internet Gateway
             │
        NAT Gateway
             │
      Private Subnet Internet Access
```

---

## Modules

### 1. Network Module

The Network module creates the networking foundation required by the application.

It includes:

* VPC
* One public subnet
* Two private subnets
* Internet Gateway
* NAT Gateway
* Elastic IP for the NAT Gateway
* Public and private route tables
* Route table associations
* Public Network ACL
* Private Network ACL

The two private subnets are used by the EKS worker nodes and are placed across different Availability Zones.

---

### 2. Server Module

The Server module provisions the EC2 server used for Jenkins.

The module includes:

* Amazon Linux 2023 AMI selection
* Jenkins EC2 instance
* Security Group
* SSH access
* Jenkins public IP output

The Jenkins server is later configured automatically using Ansible.

---

### 3. EKS Module

The EKS module provisions the Kubernetes environment.

It includes:

* Amazon EKS cluster
* EKS cluster IAM role
* Worker node IAM role
* Required IAM policy attachments
* Managed EKS node group
* Two worker nodes
* Worker nodes distributed across the private subnets

The worker nodes use the private subnets to avoid exposing them directly to the public internet.

---

### 4. ECR Module

The ECR module creates the Amazon Elastic Container Registry repository used to store Docker images built by the CI/CD pipeline.

Example repository:

```text
ivolve-repo
```

The EKS worker-node IAM role also has permission to pull images from ECR.

---

## Terraform Backend

Terraform state is stored remotely in Amazon S3.

The S3 backend prevents the Terraform state from being stored only on the local machine and allows the infrastructure state to be managed consistently.

The backend configuration should be initialized before working with the infrastructure.

```bash
terraform init
```

---

## Prerequisites

Before running Terraform, make sure the following are installed:

* Terraform
* AWS CLI
* AWS account
* AWS credentials configured
* An existing S3 bucket for the Terraform backend
* Appropriate AWS IAM permissions

Verify AWS authentication:

```bash
aws sts get-caller-identity
```

Verify Terraform:

```bash
terraform version
```

Verify AWS CLI:

```bash
aws --version
```

---

## Directory Structure

The Terraform directory follows a modular structure similar to:

```text
Terraform/
│
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── backend.tf
│
└── modules/
    │
    ├── Network/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── Server/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── EKS/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── ECR/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Terraform Workflow

### Initialize Terraform

```bash
terraform init
```

This initializes:

* The S3 backend
* Terraform modules
* AWS provider
* Required provider plugins

---

### Validate Configuration

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

---

### Format Terraform Files

```bash
terraform fmt -recursive
```

This formats Terraform configuration files consistently.

---

### Review the Execution Plan

```bash
terraform plan
```

Always review the plan before applying changes.

The plan shows whether Terraform will:

* Add resources
* Change resources
* Destroy resources
* Replace resources

For example:

```text
Plan: 25 to add, 0 to change, 0 to destroy.
```

---

### Apply Infrastructure

```bash
terraform apply
```

Terraform will ask for confirmation before creating the resources.

Type:

```text
yes
```

to continue.

---

## Outputs

Important infrastructure information is exposed using Terraform outputs.

Example:

```hcl
output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = aws_eks_cluster.eks.endpoint
}
```

The Jenkins public IP can also be retrieved using:

```bash
terraform output jenkins_public_ip
```

Or:

```bash
terraform output -raw jenkins_public_ip
```

The EKS cluster name can be retrieved using:

```bash
terraform output cluster_name
```

---

## Checking Terraform State

To list all resources currently managed by Terraform:

```bash
terraform state list
```

To inspect a specific resource:

```bash
terraform state show <resource>
```

---

## Destroying the Infrastructure

When the infrastructure is no longer required, it can be removed with:

```bash
terraform destroy
```

This deletes the AWS resources managed by the Terraform configuration.

**Important:** Do not run `terraform destroy` before committing and pushing the Terraform and Ansible code to GitHub if the infrastructure is required for demonstration or evaluation.

---

## Security Considerations

The following files and credentials must never be committed to GitHub:

```text
*.pem
terraform.tfstate
terraform.tfstate.*
.env
AWS access keys
AWS secret keys
passwords
private keys
```

The `.pem` SSH private key used to access the Jenkins EC2 instance must remain outside the Git repository.

Terraform state may contain sensitive infrastructure information, so the remote S3 bucket should be protected with appropriate IAM permissions and encryption.

---

## Validation Checklist

Before considering the Terraform infrastructure complete, verify:

* [x] VPC created
* [x] Public subnet created
* [x] Two private subnets created
* [x] Internet Gateway created
* [x] NAT Gateway created
* [x] Elastic IP allocated
* [x] Route tables configured
* [x] Network ACLs configured
* [x] Jenkins EC2 created
* [x] Jenkins Security Group created
* [x] EKS cluster created
* [x] EKS worker node group created
* [x] Worker nodes distributed across private subnets
* [x] ECR repository created
* [x] S3 backend configured
* [x] Terraform validation successful
* [x] Terraform plan reviewed

---

## Relationship With Ansible

Terraform is responsible for **provisioning the infrastructure**.

Ansible is responsible for **configuring the Jenkins EC2 instance after it has been created**.

The workflow is therefore:

```text
Terraform
   │
   ├── Creates VPC
   ├── Creates Jenkins EC2
   ├── Creates EKS
   └── Creates ECR
          │
          ▼
       Ansible
          │
          ├── Installs Java
          ├── Installs Jenkins
          ├── Installs Docker
          └── Installs Trivy
```

This separation keeps infrastructure provisioning and server configuration independent.

