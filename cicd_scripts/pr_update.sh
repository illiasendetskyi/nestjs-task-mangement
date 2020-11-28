#!/bin/bash

branch="$(cut -d'/' -f3 <<<${CODEBUILD_WEBHOOK_HEAD_REF})"
stackName="${branch}-showcase-ci-cd-stack"
fullDomainName="${branch}-showcase.${DOMAIN_NAME}"
bucketName=$fullDomainName
stackLogicalResourceId="WebsiteCloudfront"

snsMessage="{\"ResourceType\":\"AWS::CustomCiCd::Showcase\", \"ResourceStatus\": \"UPDATE_IN_PROGRESS\", \"StackName\": \"${stackName}\"}"
echo $snsMessage
aws sns publish --topic-arn $SNS_ARN --message "$snsMessage"

echo "Sync a bucket: $bucketName"
aws s3 sync "$CODEBUILD_SRC_DIR/dist-test" s3://$bucketName

echo "Getting cloudfront resource from cloudformation, stack: $stackName, logical resource id: $stackLogicalResourceId"

distributionId=null
resourceInfo=$(aws cloudformation describe-stack-resource --stack-name $stackName --logical-resource-id $stackLogicalResourceId)
echo "Resource info from cloudformation: $resourceInfo"

distributionId=$(jq 'if (.StackResourceDetail != null and .StackResourceDetail.PhysicalResourceId != null) then .StackResourceDetail.PhysicalResourceId else null end' <<< "$resourceInfo")
distributionId=$(sed -e 's/^"//' -e 's/"$//' <<<"$distributionId")
echo "Got distribution id: $distributionId"

invalidationResponse=$(aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*")
echo "Cloudfront invalidation response: $invalidationResponse"
invalidationId=$(jq 'if (.Invalidation != null and .Invalidation.Id != null) then .Invalidation.Id else null end' <<< "$invalidationResponse")
invalidationId=$(sed -e 's/^"//' -e 's/"$//' <<<"$invalidationId")
echo "Got invalidation id: $invalidationId"

invalidated=false

i=1
while [ "$invalidated" == false ] || [ "$invalidated" == "" ]
do
  echo "Getting invalidation, iteration: $i"
  invalidatioInfo=$(aws cloudfront get-invalidation --distribution-id $distributionId --id $invalidationId)
  echo "Cloudfront invalidation info response:"
  echo "$invalidatioInfo"
  invalidated=$(jq 'if (.Invalidation != null and .Invalidation.Status == "Completed") then true else false end' <<< "$invalidatioInfo")
  # bucketResource=$(jq 'if (.StackEvents != null and .StackEvents[0] != null and (.StackEvents | map(.ResourceType + .ResourceStatus) | contains(["AWS::S3::Bucket", "CREATE_COMPLETE"]))) then .StackEvents[] | select( .ResourceType == "AWS::S3::Bucket" and .ResourceStatus == "CREATE_COMPLETE") else null end' test.json)
  if [ "$invalidated" == false ] || [ "$invalidated" == "" ]
  then
    sleep 5
  fi
  i=$(( $i + 1 ))
done

snsMessage="{\"ResourceType\":\"AWS::CustomCiCd::Showcase\", \"ResourceStatus\": \"UPDATE_COMPLETE\", \"StackName\": \"${stackName}\"}"
echo $snsMessage
aws sns publish --topic-arn $SNS_ARN --message "$snsMessage"
echo "done"

