#!/bin/bash

CODEBUILD_WEBHOOK_HEAD_REF='refs/heads/test-branch4'
DOMAIN_NAME='azarus.io'

branch="$(cut -d'/' -f3 <<<${CODEBUILD_WEBHOOK_HEAD_REF})"
stackName="${branch}-showcase-ci-cd-stack"
fullDomainName="${branch}-showcase.${DOMAIN_NAME}"
bucketName=$fullDomainName

echo "Empty a bucket: $bucketName"
aws s3 rm s3://$bucketName --recursive

echo "Delete stack: $stackName"

aws cloudformation delete-stack --stack-name "${stackName}"

echo "done"

