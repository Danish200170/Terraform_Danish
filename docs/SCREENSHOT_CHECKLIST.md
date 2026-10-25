# Mandatory genuine evidence checklist

**Do not create mock screenshots or paste fabricated outputs.** Capture evidence from your own terminal and AWS account after running the deployment.

Save PNG/JPG files in this folder's parent `screenshots/` directory. Suggested names:

## Part 1 — single EC2
- `p1_terraform_validate.png` — successful `terraform validate`.
- `p1_terraform_apply.png` — apply summary showing resources created.
- `p1_ec2_instance.png` — EC2 console showing instance running.
- `p1_frontend.png` — browser showing Express on port 3000.
- `p1_flask_api.png` — browser/curl showing Flask `/api/hello` JSON.
- `p1_services.png` — SSH terminal showing both systemd services active.

## Part 2 — separate EC2
- `p2_terraform_apply.png` — apply summary.
- `p2_ec2_instances.png` — both EC2 instances running.
- `p2_security_groups.png` — inbound rules for app ports and frontend-to-backend access.
- `p2_frontend.png` — Express frontend URL.
- `p2_backend_api.png` — Flask API response.
- `p2_proxy_test.png` — frontend `/api/hello` response forwarding to Flask.

## Part 3 — ECR / ECS / ALB
- `p3_ecr_images.png` — both repositories with pushed image tags.
- `p3_ecs_services.png` — both ECS services and desired/running task counts.
- `p3_alb_targets.png` — both target groups showing healthy targets.
- `p3_alb_frontend.png` — ALB URL displaying Express.
- `p3_alb_flask_api.png` — ALB `/api/hello` JSON from Flask.
- `p3_terraform_outputs.png` — relevant Terraform outputs.
- `p3_cloudwatch_logs.png` — application logs, if available.

## Documentation and repository
- `github_repository.png` — your repository page and URL.
- `zip_contents.png` — File Explorer showing the final ZIP and required files.

## Before submission
- [ ] All three parts successfully validated and deployed, or clearly note what is not deployed.
- [ ] No AWS credentials, private keys, `.env` secrets, state files, or plan files in the ZIP.
- [ ] Replace `ADD_YOUR_GITHUB_REPOSITORY_URL_HERE` with your real repository URL.
- [ ] Insert genuine screenshots into `screenshots/` and add a brief caption for each in `docs/DEPLOYMENT_GUIDE.md`.
- [ ] Confirm the ZIP is named exactly `Terraform_Danish.zip`.
