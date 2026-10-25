# Terraform Deployment Guide — Danish

## Objective

Deploy a Flask backend and an Express frontend on AWS in three configurations:

1. Both apps on one EC2 instance.
2. Apps on separate EC2 instances with a custom VPC and security groups.
3. Dockerized apps in ECR and ECS Fargate behind an Application Load Balancer.

## Architecture summary

### Part 1 — single EC2
Terraform creates one Ubuntu EC2 instance and a security group. EC2 user-data installs Python, Flask/Gunicorn, Node.js, and Express. `systemd` keeps each service running. Express listens on TCP 3000; Flask listens on TCP 5000.

### Part 2 — separate EC2
Terraform creates a VPC, public subnet, internet gateway, route table, two EC2 instances, and app security groups. The frontend receives the backend private IP as user-data and forwards `/api/hello` requests to Flask. The backend security group allows port 5000 from the frontend security group and from `allowed_cidr` for direct verification.

### Part 3 — containers
Terraform creates two ECR repositories, a VPC with two public subnets, security groups, an ECS cluster, Fargate task definitions/services, CloudWatch log groups, an ALB, and two target groups. ALB `/api/*` traffic goes to Flask; all other paths go to Express. Docker images must be built and pushed to ECR before the ECS services can become healthy.

## Validation workflow

Run these commands separately in each part directory:

```bash
terraform fmt -recursive
terraform init
terraform validate
terraform plan
```

Review the plan before applying:

```bash
terraform apply
terraform output
```

Do not run `terraform apply -auto-approve` blindly. Review resource counts and estimated cost first.

## State management

The default configuration stores state locally in each part folder. Terraform state is necessary to track managed resources, but local state is not ideal for team collaboration. For an S3 remote backend, first create a private S3 bucket with versioning and encryption, then configure the backend block in each root module and migrate state with `terraform init -migrate-state`. Backend bucket names are globally unique and cannot safely be guessed in this document. Do not put credentials into Terraform files.

## Security and cost notes

- Change `allowed_cidr` from `0.0.0.0/0` to your own public IP in `/32` form where practical.
- The Part 3 ALB is internet-facing and HTTP-only for assignment demonstration. For production, use HTTPS with ACM, private ECS subnets, NAT or VPC endpoints, least-privilege IAM, and stricter logging.
- EC2, ALB, ECS Fargate, ECR storage, and data transfer can incur charges.
- Run `terraform destroy` after capturing evidence if you do not need the resources. Be sure to preserve screenshots and repository source first.

## Test commands

```bash
curl -i http://EC2_PUBLIC_IP:3000/
curl -i http://EC2_PUBLIC_IP:5000/api/hello
curl -i http://ALB_DNS_NAME/
curl -i http://ALB_DNS_NAME/api/hello
```

Expected Flask API response includes `status: ok` and a greeting. Expected Express frontend shows an Express status page. The actual public IP/DNS and responses must be recorded from the deployment you perform.

## Evidence log

Use this table after deployment and replace each placeholder with the actual result.

| Item | Actual result / screenshot filename |
|---|---|
| Part 1 `terraform validate` | Pending — capture real output |
| Part 1 EC2 instance ID / public IP | Pending — record actual output |
| Part 1 frontend and Flask API | Pending — test and capture |
| Part 2 EC2 instance IDs / URLs | Pending — record actual output |
| Part 2 frontend-to-backend proxy | Pending — test and capture |
| Part 3 ECR image URIs | Pending — record actual output |
| Part 3 ECS service running count | Pending — record actual output |
| Part 3 ALB URL and healthy targets | Pending — test and capture |
| GitHub repository URL | Not provided yet |
| Final ZIP inspected | Pending |

## Known prerequisite

This package was generated without access to the user's AWS account or local terminal. Therefore it cannot honestly certify that resources are running, that Terraform validation has passed in the user's environment, or that screenshots exist. Run the commands, fix any provider/region/account-specific issues, add genuine evidence, and only then mark the assignment complete.
