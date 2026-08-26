# HelloApi — Sandbox CodeDeploy Demo

A minimal ASP.NET Core (.NET 8) Web API wired to a GitHub Actions → AWS CodeDeploy pipeline,
running entirely in a personal sandbox AWS account.

---

## Repository layout

```
.
├── HelloApi/                   # .NET Web API project
│   └── Program.cs              # /hello, /hello/{name}, /health endpoints
├── infra/
│   ├── terraform/              # All AWS infrastructure (IaC)
│   │   ├── main.tf             # S3, IAM, EC2, CodeDeploy resources
│   │   ├── variables.tf        # Input variable definitions
│   │   ├── outputs.tf          # Values you'll need after apply
│   │   ├── terraform.tfvars    # Your personal sandbox values (gitignored)
│   │   └── user_data.sh        # EC2 bootstrap: installs .NET + CodeDeploy agent
│   └── codedeploy/
│       ├── appspec.yml         # CodeDeploy lifecycle hooks config
│       ├── helloapi.service    # Reference systemd unit file
│       └── hooks/
│           ├── stop_service.sh
│           ├── clean_old_files.sh
│           ├── set_permissions.sh
│           ├── start_service.sh
│           └── validate_health.sh
└── .github/workflows/
    └── deploy-sandbox.yml      # Manual-only GitHub Actions workflow
```

---

## Step 1 — Prerequisites

| Tool | Min version | Install |
|------|-------------|---------|
| Terraform | 1.6+ | https://developer.hashicorp.com/terraform/install |
| AWS CLI | 2.x | https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html |
| AWS credentials | — | Configure a profile with admin access to your **personal sandbox** account |

Verify:
```bash
terraform version
aws sts get-caller-identity   # should show your personal account ID: 974336481127
```

---

## Step 2 — Apply the Terraform

```bash
cd infra/terraform

# Initialize providers
terraform init

# Preview what will be created
terraform plan

# Apply — this creates ~15 resources in your sandbox account
terraform apply
```

After `apply` completes, note the outputs:

```
s3_artifact_bucket      = "sandbox-api-deploy-artifacts-974336481127"
github_actions_role_arn = "arn:aws:iam::974336481127:role/sandbox-api-deploy-github-actions-role"
codedeploy_app_name     = "sandbox-api-deploy"
codedeploy_deployment_group = "sandbox-api-deploy-dg"
instance_public_ips     = ["<ip1>", "<ip2>"]
```

**Wait ~3 minutes** for the EC2 user-data script to finish installing .NET and the CodeDeploy agent before triggering a deployment.

---

## Step 3 — Set GitHub repository variables/secrets

Go to your repo → **Settings → Secrets and variables → Actions → Variables tab**
and add these **variables** (not secrets — none are sensitive):

| Variable name | Value (from terraform output) |
|---|---|
| `SANDBOX_DEPLOY_ROLE_ARN` | `arn:aws:iam::974336481127:role/sandbox-api-deploy-github-actions-role` |
| `SANDBOX_AWS_REGION` | `us-east-1` |
| `SANDBOX_ARTIFACT_BUCKET` | `sandbox-api-deploy-artifacts-974336481127` |
| `SANDBOX_CODEDEPLOY_APP` | `sandbox-api-deploy` |
| `SANDBOX_CODEDEPLOY_DG` | `sandbox-api-deploy-dg` |

> No secrets needed — the workflow uses OIDC to assume the IAM role directly.
> There are no long-lived AWS access keys anywhere.

---

## Step 4 — Trigger a first test deployment

1. Go to your repo → **Actions** → **Deploy to Sandbox**
2. Click **Run workflow** → **Run workflow**
3. Watch the workflow run. It will:
   - Build and publish the .NET app
   - Zip it with `appspec.yml` and the hook scripts
   - Upload to S3
   - Trigger a CodeDeploy rolling deployment (HalfAtATime)
   - Wait for CodeDeploy to finish — fails the workflow if CodeDeploy reports failure

4. After it succeeds, test the live API on each instance:
   ```bash
   curl http://<instance_public_ip>:5000/health
   curl http://<instance_public_ip>:5000/hello
   curl http://<instance_public_ip>:5000/hello/Sanjay
   ```

---

## Step 5 — Deliberately break a deploy (confirm rollback works)

**Goal**: Cause the `validate_health.sh` hook to fail so CodeDeploy triggers automatic rollback.

### Option A — Bad health check response (easiest)

Edit `HelloApi/Program.cs`, change the `/health` endpoint to return 500:

```csharp
app.MapGet("/health", () => Results.StatusCode(500));
```

Commit, push, run the workflow. The `ValidateService` hook will time out after 60 s, CodeDeploy will mark the deployment FAILED, and the auto-rollback will restore the previous revision.

### Option B — App that crashes on startup

Add `throw new Exception("intentional crash");` at the top of `Program.cs`.
The service won't start, so `/health` is never reachable → same rollback path.

### Confirming the rollback

In AWS Console → **CodeDeploy → Deployments**, you'll see:
- The failed deployment with status `Failed`
- An automatic rollback deployment immediately following it
- Both deployments appear in the deployment history log

---

## Tearing down

When you're done testing, remove **all** sandbox resources:

```bash
cd infra/terraform
terraform destroy
```

This deletes the S3 bucket (including all artifacts, because `force_destroy = true`),
IAM roles, EC2 instances, security group, and CodeDeploy application.
Nothing in your company's production account is affected.

---

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health probe — must return 200 for CodeDeploy to accept the deployment |
| GET | `/hello` | Returns `{"message":"Hello, World!"}` |
| GET | `/hello/{name}` | Returns a personalized greeting |
