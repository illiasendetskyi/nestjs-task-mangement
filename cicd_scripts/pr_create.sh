#!/bin/bash

branch="$(cut -d'/' -f3 <<<${CODEBUILD_WEBHOOK_HEAD_REF})"
stackName="${branch}-showcase-ci-cd-stack"
fullDomainName="${branch}-showcase.${DOMAIN_NAME}"
bucketName=$fullDomainName

aws cloudformation create-stack --stack-name "${stackName}" --template-body file://cf-stack.yml --parameters ParameterKey=DomainName,ParameterValue="${DOMAIN_NAME}" ParameterKey=FullDomainName,ParameterValue="${fullDomainName}" ParameterKey=AcmCertificateArn,ParameterValue="${ACM_CERTIFICATE_ARN}" --notification-arns "${SNS_ARN}"

npm install

bucketResource=null
i=1
while [ "$bucketResource" == null ] || [ "$bucketResource" == "" ]
do
  echo "Getting stack events, iteration: $i"
  stackEvents=$(aws cloudformation describe-stack-events --stack-name "${stackName}")
  echo "Cloudfront response:"
  echo "$stackEvents"
  bucketResource=$(jq 'if (.StackEvents != null and .StackEvents[0] != null and (.StackEvents | map(.ResourceType + .ResourceStatus) | contains(["AWS::S3::Bucket", "CREATE_COMPLETE"]))) then .StackEvents[] | select( .ResourceType == "AWS::S3::Bucket" and .ResourceStatus == "CREATE_COMPLETE") else null end' <<< "$stackEvents")
  # bucketResource=$(jq 'if (.StackEvents != null and .StackEvents[0] != null and (.StackEvents | map(.ResourceType + .ResourceStatus) | contains(["AWS::S3::Bucket", "CREATE_COMPLETE"]))) then .StackEvents[] | select( .ResourceType == "AWS::S3::Bucket" and .ResourceStatus == "CREATE_COMPLETE") else null end' test.json)
  if [ "$bucketResource" == null ] || [ "$bucketResource" == "" ]
  then
    sleep 5
  fi
  i=$(( $i + 1 ))
done

echo "Bucket resource received:"
echo $bucketResource
echo "Bucket name: $bucketName"

aws s3 sync dist-test s3://$bucketName

echo "done"
