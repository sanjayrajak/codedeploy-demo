# ---------------------------------------------------------------
# Fill in your personal sandbox values.
# NEVER commit real credentials. This file is .gitignored.
# ---------------------------------------------------------------

aws_account_id = "974336481127"
aws_region     = "us-east-1"
github_org     = "sanjayrajak"
github_repo    = "codedeploy-demo"
github_branch  = "main"

app_name       = "sandbox-api-deploy"
instance_type  = "t3.micro"
instance_count = 2

# Leave empty to auto-discover the default VPC/subnets:
vpc_id     = ""
subnet_ids = []

# Tighten to your own IP for real testing, e.g. "203.0.113.5/32"
allowed_ssh_cidr = "0.0.0.0/0"
