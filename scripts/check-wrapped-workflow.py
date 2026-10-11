"""Execute notebook 05's composed workflow and inspect its real S3 raster."""
import json
import os
import posixpath
from pathlib import Path
import subprocess
import sys
from urllib.parse import urlparse
import boto3
from botocore.config import Config
import numpy as np
from rasterio.io import MemoryFile
import yaml

root = Path(__file__).resolve().parents[1]
workspace = root / 'notebooks'
inputs = yaml.safe_load((workspace / 'cwl-workflow/wrapped-inputs.yaml').read_text())
endpoint = os.environ.get('STAC_S3_ENDPOINT', inputs['endpoint_url']['value'])
inputs['endpoint_url']['value'] = endpoint
job = workspace / 'acceptance-wrapped-inputs.yaml'
job.write_text(yaml.safe_dump(inputs))
command = ['cwltool', '--podman']
if os.environ.get('CWL_CUSTOM_NET'):
    command += ['--custom-net', os.environ['CWL_CUSTOM_NET']]
command += ['--outdir', 'acceptance-wrapped-output', '.main.cwl', job.name]
subprocess.run(['cwltool', '--validate', '.main.cwl'], cwd=workspace, check=True)
result = subprocess.run(command, cwd=workspace, check=True, stdout=subprocess.PIPE, text=True)
(workspace / 'acceptance-wrapped-results.json').write_text(result.stdout)
output = json.loads(result.stdout)
href = output['stac_catalog']['value']
assert href == 's3://results/run-005/catalog.json', output
client = boto3.client('s3', endpoint_url=endpoint, aws_access_key_id='test',
    aws_secret_access_key='test', region_name='us-east-1',
    config=Config(s3={'addressing_style': 'path'}))
def read(href):
    address = urlparse(href)
    assert address.scheme == 's3', href
    return client.get_object(Bucket=address.netloc, Key=address.path.lstrip('/'))['Body'].read()
def resolve(base, target):
    if urlparse(target).scheme:
        return target
    address = urlparse(base)
    path = posixpath.normpath(posixpath.join(posixpath.dirname(address.path), target))
    return f"{address.scheme}://{address.netloc}{path}"

catalog = json.loads(read(href))
assert resolve(href, next(link['href'] for link in catalog['links'] if link['rel'] == 'root')) == href
item_href = next(link['href'] for link in catalog['links'] if link['rel'] == 'item')
item_href = resolve(href, item_href)
item = json.loads(read(item_href))
assert resolve(item_href, next(link['href'] for link in item['links'] if link['rel'] == 'root')) == href
rasters = 0
for asset in item['assets'].values():
    if not asset['href'].endswith('.tif'):
        continue
    with MemoryFile(read(resolve(item_href, asset['href']))) as memory, memory.open() as raster:
        assert raster.crs.to_epsg() == 32611
        assert raster.width > 0 and raster.height > 0
        pixels = raster.read(1, masked=True)
        assert pixels.count() > 0
        assert set(np.unique(pixels.compressed())) <= {0, 1}
        rasters += 1
assert rasters > 0
print('Composed workflow passed: S3 root links and real binary raster verified')
