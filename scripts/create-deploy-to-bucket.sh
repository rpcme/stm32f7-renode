#! /bin/sh

region=${region:-us-east-1}
profile=${profile:-default}
std_awscli_args="--output text --region ${region} --profile ${profile}"
ACCOUNT_ID=$(aws ${std_awscli_args} sts get-caller-identity --output text --query Account)
DEPLOYTO_BUCKET=${ACCOUNT_ID}-myapp-deliver

aws s3api create-bucket \
    --bucket ${DEPLOYTO_BUCKET} \
    --query Location \
    --region ${region}

aws s3api put-bucket-versioning \
    --bucket ${DEPLOYTO_BUCKET} \
    --versioning-configuration "MFADelete=Disabled,Status=Enabled"

user_principal=$(aws sts get-caller-identity --query Arn --output text)

cat <<EOF > /tmp/deployto-bucket-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com",
        "AWS": "${user_principal}"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::${DEPLOYTO_BUCKET}/*",
        "arn:aws:s3:::${DEPLOYTO_BUCKET}"
      ]
    }
  ]
}
EOF

aws s3api put-bucket-policy \
    --bucket ${DEPLOYTO_BUCKET} \
    --policy file:///tmp/deployto-bucket-policy.json


