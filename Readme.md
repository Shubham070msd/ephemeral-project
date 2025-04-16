# Ephemeral Environment Deployment Platform

---

## Objective

This project provides a DevOps platform to **deploy feature branches on-demand** into **temporary AWS environments** using ECS Fargate.  
Each environment is:
- **Isolated**
- **Auto-destructs after 24 hours** (based on TTL)
- Can also be **manually destroyed** by the developer

---

## Features

- CLI to input GitHub repo URL and branch name
- Checkout and deploy code from a feature branch
- Deploy infrastructure using **Terraform**
- Create **ECS Fargate + ALB + VPC** with 2 public subnets
- Build Docker image and push to **ECR**
- Expose the app via **ALB public DNS**
- Auto-destroy logic using TTL tags + cleanup script
- Manual destroy support with a script
- Clear separation of infra and lifecycle logic

---

---

## 🖥️ How to Use

---

### 1️⃣ Deploy a Feature Branch

Run the deploy script:

```bash
bash scripts/deploy.sh
```

You will be prompted to enter:
- GitHub repository URL
- Branch name

This script will:
- Clone the repo and checkout the specified branch
- Build a Docker image and push to ECR
- Trigger Terraform to deploy the environment on AWS
- Output the public ALB URL to access your app

✅ ECS services are tagged with `created_at` and `ttl` for cleanup tracking

---

### 2️⃣ Manual Cleanup (Destroy Environment)

Run this when you want to delete a deployed environment early:

```bash
bash scripts/manual-destroy.sh
```

#### Manual Cleanup Logic

- Asks for the branch name (e.g. `qa`)
- Builds the ECS service name internally (e.g. `ephemeral-service-qa`)
- Scales the service to 0 and then deletes it from ECS
- ALB target group becomes free

You can use this anytime to manually clean up an environment.

---

### 3️⃣ Auto-Destroy Script

Use this script to simulate automatic cleanup based on TTL (Time To Live):

```bash
bash scripts/auto-destroy.sh
```

#### Auto-Destroy Logic Explanation

- Each ECS service is tagged with:
  - `created_at` – deployment timestamp
  - `ttl` – Time To Live in hours (e.g., 24h)
- The script:
  - Lists all ECS services with those tags
  - Calculates if the service has exceeded its TTL
  - If expired → scales to 0 and deletes the service

This simulates **auto-deletion after 24 hours of inactivity** as required in the assignment.

---

