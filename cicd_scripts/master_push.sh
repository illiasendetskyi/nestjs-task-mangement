#!/bin/bash
bucketName='showcase.azarus.io'
cfDistributionId='E2BX03KNEIBKOR'

echo "Sync a bucket: $bucketName"
# aws s3 sync ../dist-test s3://$bucketName

echo "Invalidating cloudfront distribution: $cfDistributionId"
# aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*"

echo "done"

