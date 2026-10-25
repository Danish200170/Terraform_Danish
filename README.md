# Terraform Assignment — Flask + Express on AWS

**Folder / ZIP name:** `Terraform_Danish` / `Terraform_Danish.zip`  
**Status:** Starter project package. AWS deployments and screenshots must be verified by the owner before submission.

## Project layout

- `part1_single_ec2/` — Flask and Express on one EC2 instance.
- `part2_separate_ec2/` — Flask and Express on separate EC2 instances in a custom VPC.
- `part3_ecs_ecr_alb/` — ECR repositories, VPC, ECS Fargate services, and an Application Load Balancer.
- `app/` — Flask and Express source code and Dockerfiles shared by Part 3.
- `docs/` — deployment guide and evidence checklist.
- `screenshots/` — add genuine screenshots from your own AWS account and terminal here.

## Prerequisites

1. An AWS account with permissions to create EC2, VPC, IAM, ECR, ECS, CloudWatch Logs, and ELB resources.
2. AWS CLI configured (`aws configure` or an approved SSO login).
3. Terraform 1.5+ and Git installed.
4. Docker installed and running for Part 3.
5. A GitHub repository you own, if you need to share source code.

Use the AWS region `ap-south-1` by default; change `aws_region` if required. AWS resources can incur charges. Destroy test infrastructure when finished.

## Application endpoints

- Flask: `GET /api/hello` returns JSON.
- Express: `GET /` returns a frontend status page.
- Express: `GET /api/hello` forwards to Flask using `FLASK_URL` if configured; otherwise it returns a clear configuration response.

## Part 1 — one EC2 instance

```bash
cd part1_single_ec2
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

Open the `frontend_url` output in a browser. The instance user-data installs Python and Node.js, writes both apps, and starts systemd services. First boot can take several minutes. Check cloud-init and services over SSH if needed:

```bash
sudo tail -n 100 /var/log/cloud-init-output.log
sudo systemctl status flask-app express-app --no-pager
curl -i http://127.0.0.1:5000/api/hello
curl -i http://127.0.0.1:3000/
```

The security group exposes TCP 3000 and 5000 to the internet for assignment testing. Restrict `allowed_cidr` to your own public IP `/32` where possible.

## Part 2 — separate EC2 instances

```bash
cd ../part2_separate_ec2
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

Use `frontend_url` for Express and `backend_url` for Flask. Security groups expose the app ports to `allowed_cidr`; frontend-to-backend traffic is permitted only from the frontend security group. The Express instance is configured with the Flask private IP. Check each instance's cloud-init log and systemd services if first boot takes time.

## Part 3 — ECR + ECS Fargate + ALB

### 1. Create ECR repositories

```bash
cd ../part3_ecs_ecr_alb
terraform init
terraform fmt -recursive
terraform validate
terraform plan -target=aws_ecr_repository.flask -target=aws_ecr_repository.express
terraform apply -target=aws_ecr_repository.flask -target=aws_ecr_repository.express
terraform output
```

### 2. Build and push images

Run from the project root (the directory containing `app/`):

```bash
aws sts get-caller-identity
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com

docker build -t flask-backend:latest -f app/flask/Dockerfile app/flask
docker build -t express-frontend:latest -f app/express/Dockerfile app/express

docker tag flask-backend:latest YOUR_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/terraform-danish-flask:latest
docker tag express-frontend:latest YOUR_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/terraform-danish-express:latest

docker push YOUR_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/terraform-danish-flask:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/terraform-danish-express:latest
```

Replace `YOUR_ACCOUNT_ID` with the account ID returned by `aws sts get-caller-identity`. If you use another region, update the region and repository URLs. Do not commit AWS credentials.

### 3. Deploy ECS and ALB

```bash
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

The ECS task definitions expect image tags `latest` in the ECR repositories. Ensure both images have been pushed before applying the complete stack. Open `alb_url` in a browser; `/` routes to Express and `/api/*` routes to Flask.

### 4. Verify

```bash
aws ecs list-clusters --region ap-south-1
aws ecs list-services --cluster "$(terraform output -raw ecs_cluster_name)" --region ap-south-1
aws ecs describe-services --cluster "$(terraform output -raw ecs_cluster_name)" --services "$(terraform output -raw express_service_name)" "$(terraform output -raw flask_service_name)" --region ap-south-1
aws elbv2 describe-target-health --target-group-arn "$(terraform output -raw express_target_group_arn)" --region ap-south-1
aws elbv2 describe-target-health --target-group-arn "$(terraform output -raw flask_target_group_arn)" --region ap-south-1
curl -i "$(terraform output -raw alb_url)/"
curl -i "$(terraform output -raw alb_url)/api/hello"
```

The target groups should show healthy targets and ECS services should reach desired count. Allow a few minutes after deployment.

## Terraform state

Terraform state contains infrastructure metadata and can contain sensitive values. Do not commit `terraform.tfstate`, `.tfstate.backup`, plan files, `.terraform/`, or credentials. This starter uses Terraform's default local state to avoid requiring a pre-existing S3 bucket. For team/production use, create a uniquely named private S3 bucket with versioning and encryption, then configure an S3 backend in a separate backend configuration and migrate state using `terraform init -migrate-state`. The S3 bucket must exist before initializing the backend. See `docs/DEPLOYMENT_GUIDE.md`.

## Cleanup

Run `terraform destroy` in each part directory for resources created by that configuration. In Part 3, destroy ECS/VPC resources first; retain ECR images only if you need them. Confirm the plan before approving destruction.

## GitHub repository

**Repository URL:** `ADD_YOUR_GITHUB_REPOSITORY_URL_HERE`

After reviewing the code and removing generated state/secrets, create a repository and push the project. Do not submit the placeholder URL. See the evidence checklist in `docs/SCREENSHOT_CHECKLIST.md`.

## Important submission note

The ZIP includes code and documentation but does **not** claim that AWS resources have been deployed or verified. Capture real screenshots from your terminal and AWS console after running the commands. Put them in `screenshots/` and update the documentation with your real GitHub URL and observed outputs before submitting.
