#! /bin/sh

region=${region:-us-east-1}
profile=${profile:-default}
std_awscli_args="--output text --region ${region} --profile ${profile}"
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)

function _detach_role_policy {
aws iam detach-role-policy --role-name $1 --policy-arn $2
}

_detach_role_policy myapp-device-advisor-service-role arn:aws:iam::aws:policy/service-role/AWSIoTThingsRegistration
_detach_role_policy myapp-device-advisor-service-role arn:aws:iam::aws:policy/service-role/AWSIoTLogging
_detach_role_policy myapp-device-advisor-service-role arn:aws:iam::aws:policy/service-role/AWSIoTRuleActions
_detach_role_policy myapp-device-advisor-service-role arn:aws:iam::aws:policy/AWSIoTDataAccess
aws iam delete-role --role-name myapp-device-advisor-service-role

_detach_role_policy myapp-codepipeline-service-role arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codepipeline-service
aws iam delete-role --role-name myapp-codepipeline-service-role

_detach_role_policy myapp-codecommit-build-role arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codebuild-build
_detach_role_policy myapp-codecommit-build-role arn:aws:iam::${ACCOUNT_ID}:policy/myapp-secrets-manager
_detach_role_policy myapp-codecommit-build-role arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codecommit-pull
aws iam delete-role --role-name myapp-codebuild-build-role

_detach_role_policy myapp-codecommit-test-role arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codebuild-integration-test
_detach_role_policy myapp-codecommit-test-role arn:aws:iam::${ACCOUNT_ID}:policy/myapp-secrets-manager
_detach_role_policy myapp-codecommit-test-role arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codecommit-pull
_detach_role_policy myapp-codecommit-test-role arn:aws:iam::${ACCOUNT_ID}:policy/myapp-device-advisor-access
aws iam delete-role --role-name myapp-codebuild-test-role

aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codebuild-build
aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codebuild-integration-test
aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codecommit-pull
aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codepipeline-events
aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codepipeline-service
aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-device-advisor-access
aws iam delete-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-secrets-manager

