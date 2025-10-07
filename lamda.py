import json
import boto3

def lambda_handler(event, context):
  client = boto3.client('s3')
  response = client.create_bucket(
    ACL='private',
    Bucket='adarsha2580',
    CreateBucketConfiguration={
            'LocationConstraint': 'ap-south-2',
            'Tags': [
                {
                    'Key': 'env',
                    'Value': 'Dev'
                },
            ]
        },
        ObjectLockEnabledForBucket=True,
        ObjectOwnership='BucketOwnerPreferred'
        )
        return {
            'statusCode': 200,
            'body': json.dumps('Bucket created successfully!')
        }
    