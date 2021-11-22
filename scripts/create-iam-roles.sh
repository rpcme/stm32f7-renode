#! /bin/sh

basedir=$(dirname $0)/..
region=${region:-us-west-2}
profile=${profile:-default}
std_awscli_args="--output text --region ${region} --profile ${profile}"
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)

function create_role_trust () {
#id=$(uuidgen)
#      "Sid": "${id}",
cat <<EOF > $2
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "$1"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

function create_managed_policy () {
    sed -e "s/ACCOUNT_ID/${ACCOUNT_ID}/g" \
        -e "s/REGION/${region}/g" \
        -e "s,DA_ROLE,${3},g" \
        $2 > /tmp/$(basename $2)
    aws iam create-policy --policy-name $1 --policy-document file:///tmp/$(basename $2)  --output text --query Policy.PolicyName
}


create_role_trust iotdeviceadvisor.amazonaws.com /tmp/device-advisor-trust.json
create_role_trust codebuild.amazonaws.com /tmp/codebuild-trust.json
create_role_trust codepipeline.amazonaws.com /tmp/codepipeline-trust.json
create_role_trust events.amazonaws.com /tmp/events-trust.json

#
# Role for the Device Advisor test suite definition
#
# All attached policies are AWS managed policies.
#
da_role_arn=$(aws iam create-role \
                  --role-name myapp-device-advisor-service-role \
                  --assume-role-policy-document file:///tmp/device-advisor-trust.json \
                  --query Role.Arn --output text)
aws iam attach-role-policy \
    --role-name myapp-device-advisor-service-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSIoTThingsRegistration
aws iam attach-role-policy \
    --role-name myapp-device-advisor-service-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSIoTLogging
aws iam attach-role-policy \
    --role-name myapp-device-advisor-service-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSIoTRuleActions
aws iam attach-role-policy \
    --role-name myapp-device-advisor-service-role \
    --policy-arn arn:aws:iam::aws:policy/AWSIoTDataAccess


create_managed_policy myapp-codebuild-build ${basedir}/configuration/iam-policy-codebuild-build.json
create_managed_policy myapp-codebuild-integration-test ${basedir}/configuration/iam-policy-codebuild-integration-test.json
create_managed_policy myapp-codecommit-pull ${basedir}/configuration/iam-policy-codecommit-pull.json
create_managed_policy myapp-codepipeline-events ${basedir}/configuration/iam-policy-codepipeline-events.json
create_managed_policy myapp-codepipeline-service ${basedir}/configuration/iam-policy-codepipeline-service.json
create_managed_policy myapp-device-advisor-access ${basedir}/configuration/iam-policy-device-advisor-access.json ${da_role_arn}
create_managed_policy myapp-secrets-manager ${basedir}/configuration/iam-policy-secrets-manager.json

cp_core_arn=$(aws iam create-role \
                  --role-name myapp-codepipeline-service-role \
                  --assume-role-policy-document file:///tmp/codepipeline-trust.json \
                  --query Role.Arn --output text)

aws iam attach-role-policy \
    --role-name myapp-codepipeline-service-role \
    --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codepipeline-service

#cp_cwe_arn=$(aws iam create-role \
#                 --role-name myapp-codepipeline-events-role \
#                 --assume-role-policy-document /tmp/events-trust.json \
#                 --query Role.RoleArn --output text)

cc_build_arn=$(aws iam create-role \
                   --role-name myapp-codebuild-build-role \
                   --assume-role-policy-document file:///tmp/codebuild-trust.json \
                   --query Role.Arn --output text)
aws iam attach-role-policy \
    --role-name myapp-codebuild-build-role \
    --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codebuild-build
aws iam attach-role-policy \
    --role-name myapp-codebuild-build-role \
    --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-secrets-manager
aws iam attach-role-policy \
    --role-name myapp-codebuild-build-role \
    --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codecommit-pull

cc_test_arn=$(aws iam create-role \
                  --role-name myapp-codebuild-test-role \
                  --assume-role-policy-document file:///tmp/codebuild-trust.json \
                  --query Role.Arn --output text)
aws iam attach-role-policy \
    --role-name myapp-codebuild-test-role \
    --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codebuild-integration-test
aws iam attach-role-policy \
    --role-name myapp-codebuild-test-role \
    --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-secrets-manager
aws iam attach-role-policy \
    --role-name myapp-codebuild-test-role \
    --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-codecommit-pull
aws iam attach-role-policy \
    --role-name myapp-codebuild-test-role \
    --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/myapp-device-advisor-access

