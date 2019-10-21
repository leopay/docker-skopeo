# Overview
This is a utility to programatically build a Docker config file.

### ECR-Helper
Create an environment variable with the prefix `ECR_LOGIN_`
```bash
ECR_LOGIN_MY_ACCOUNT__US_EAST1="123456789876.dkr.ecr.us-east-1.amazonaws.com"
ECR_LOGIN_MY_ACCOUNT__US_WEST2="123456789876.dkr.ecr.us-west-2.amazonaws.com"
ECR_LOGIN_ANOTHERR_1__US_EAST1="567898765432.dkr.ecr.us-east-1.amazonaws.com"
```

### Registry Credentials
```bash
DKR_AUTH_NEXUS="https://nexus.myorg.net"
DKR_AUTH_NEXUS__USER="nexus_user"
DKR_AUTH_NEXUS__PASS="nexus_pass"
DKR_AUTH_GITLAB="https://gitlab.myorg.net"
DKR_AUTH_GITLAB__AUTH="gitlab_token"
```
You can pull values from AWS SSM ParameterStore by setting `KCFG_ENABLE_AWS_PSTORE` and ensuring you pass a valid Parameter ARN
```bash
KCFG_ENABLE_AWS_PSTORE=1
DKR_AUTH_GITLAB=https://gitlab.myorg.net
DKR_AUTH_GITLAB__AUTH=arn:aws:ssm:us-east-1::parameter/path/to/credential/value
```
