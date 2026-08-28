$env:AWS_PROFILE = "AWS-personal-vscode"
$env:AWS_DEFAULT_REGION = "us-east-1"

$params = '{"commands":["systemctl is-active codedeploy-agent && echo agent-ok || echo agent-down","dotnet --version 2>/dev/null || echo dotnet-not-found","systemctl is-active helloapi 2>/dev/null || echo helloapi-not-deployed-yet"]}'

$cmdId = aws ssm send-command `
    --instance-ids i-005a945ce40339816 i-0b0d919622ff13a29 `
    --document-name AWS-RunShellScript `
    --parameters $params `
    --query Command.CommandId `
    --output text

Write-Output "Command ID: $cmdId"
Start-Sleep -Seconds 10

aws ssm list-command-invocations `
    --command-id $cmdId `
    --details `
    --query "CommandInvocations[*].{Instance:InstanceId,Status:Status,Output:CommandPlugins[0].Output}" `
    --output table
