# CloudDevOpsProject

# Docker Compose Deployment

## Overview

This task focuses on containerizing the application and running the complete application stack using **Docker Compose**.

The application consists of:

* **Frontend** — Node.js / Express
* **Auth Service** — Python / Flask
* **Roadmap Service** — Java / Spring Boot
* **MySQL** — Database

Docker Compose is used to define, build, and run all services together in a single multi-container environment.

---

## Architecture

```text
                         Browser
                            |
                            |
                    Frontend :3000
                            |
                 ---------------------
                 |                   |
                 |                   |
          Auth Service       Roadmap Service
             :5000                 :8080
                 |
                 |
              MySQL :3306
```

All services communicate through the Docker Compose network using **service names** rather than container IP addresses.

---

## Docker Compose Configuration

The `docker-compose.yml` file defines the application services, including:

* Docker image/build configuration
* Port mappings
* Environment variables
* Service dependencies
* Database configuration
* Inter-service communication

Example service communication:

```text
frontend
   |
   +----> auth-service:5000
   |
   +----> roadmap-service:8080

auth-service
   |
   +----> mysql:3306
```

---

## Running the Application

### 1. Build the Images

```bash
docker compose build
```

This builds the Docker images defined for the application services.

### 2. Start the Application

```bash
docker compose up
```

To run the application in detached mode:

```bash
docker compose up -d
```

### 3. Verify Running Containers

```bash
docker ps
```

The expected containers are:

```text
frontend-service
auth-service
roadmap-service
mysql
```

---

## Application Verification

The frontend application is available at:

```text
http://localhost:3000
```

The application was verified by:

1. Opening the frontend.
2. Creating a new user account.
3. Logging in with the created credentials.
4. Accessing the roadmap page.

Successful verification confirmed communication between:

```text
Frontend → Auth Service
Auth Service → MySQL
Frontend → Roadmap Service
```

---

# Troubleshooting

## Docker Build Failed: No Space Left on Device

### Problem

During the Docker image build, the following error occurred:

```text
no space left on device
```

The Docker build failed because the Ubuntu VM's root filesystem had reached **100% disk usage**.

Disk usage was checked using:

```bash
df -h
```

The result showed:

```text
Filesystem      Size  Used Avail Use%
/dev/sda3        29G   29G     0 100% /
```

### Cause

Docker requires free disk space for:

* Docker images
* Image layers
* Build cache
* Temporary build files
* Container data

The available VM storage was insufficient for the Docker build process.

### Initial Solution

Docker disk usage was inspected:

```bash
docker system df
```

Unused Docker resources were then removed:

```bash
docker system prune
```

This recovered approximately:

```text
1.904 GB
```

However, additional storage was still required.

### Permanent Solution

The VM virtual disk was expanded from the VMware settings.

After increasing the virtual disk size, the Linux partition and filesystem were also expanded.

The partition was resized using:

```bash
sudo parted /dev/sda
```

Inside `parted`:

```bash
resizepart 3 100%
```

Then the filesystem was expanded:

```bash
sudo resize2fs /dev/sda3
```

Finally, the available disk space was verified:

```bash
df -h /
```

After expanding the storage, the Docker build completed successfully.

---

# Result

The complete application stack was successfully containerized and deployed locally using Docker Compose.

### Completed

* Containerized the application services.
* Built Docker images.
* Created a multi-container environment.
* Configured service-to-service communication.
* Connected the Auth Service to MySQL.
* Exposed the frontend through port `3000`.
* Verified the complete application flow.
* Resolved the VM storage issue that prevented Docker builds.

---

# Next Steps

The next DevOps stages are:

1. Push Docker images to a container registry.
2. Implement a CI/CD pipeline.
3. Automate image building and deployment.
4. Deploy the application to a cloud/server environment.

