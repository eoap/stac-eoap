"""Initialize the isolated acceptance bucket after SeaweedFS becomes ready."""
import os
import time
import boto3
from botocore.config import Config

client = boto3.client(
    's3', endpoint_url=os.environ['STAC_S3_ENDPOINT'],
    aws_access_key_id='test', aws_secret_access_key='test', region_name='us-east-1',
    config=Config(s3={'addressing_style': 'path'}, connect_timeout=2, read_timeout=2),
)
for attempt in range(60):
    try:
        client.list_buckets()
        break
    except Exception:
        if attempt == 59:
            raise
        time.sleep(2)
client.create_bucket(Bucket='results')
print('Acceptance S3 bucket ready')
