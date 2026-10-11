# Embedded schema definitions derived from eoap/schemas (Copyright 2025 Terradue, Apache-2.0).
cwlVersion: v1.2
class: CommandLineTool
id: stage-out
doc: Stage-out the results to S3
inputs:
  s3_bucket:
    type: string
    label: s3 bucket
    doc: s3 bucket.
  sub_path:
    type: string
    label: sub path
    doc: sub path.
  aws_access_key_id:
    type: string
    label: aws access key id
    doc: aws access key id.
  aws_secret_access_key:
    type: string
    label: aws secret access key
    doc: aws secret access key.
  region_name:
    type: string
    label: region name
    doc: region name.
  endpoint_url:
    type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
    label: endpoint url
    doc: endpoint url.
  stac_catalog:
    type: Directory
    label: stac catalog
    doc: stac catalog.
outputs:
  s3_catalog_output:
    outputBinding:
      outputEval: '${ return {value: "s3://" + inputs.s3_bucket + "/" + inputs.sub_path + "/catalog.json"}; }'
    type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
    label: s3 catalog output
    doc: s3 catalog output.
baseCommand:
- python
- stage.py
arguments:
- $( inputs.stac_catalog.path )
- $( inputs.s3_bucket )
- $( inputs.sub_path )
requirements:
  NetworkAccess:
    networkAccess: true
  DockerRequirement:
    dockerPull: ghcr.io/eoap/mastering-app-package/stage:1.0.0@sha256:1a99609fdc7e28b47afa79d0187aafb6475f1b78a6e89b587d5ad3d1c35702da
  InlineJavascriptRequirement: {}
  EnvVarRequirement:
    envDef:
      aws_access_key_id: $( inputs.aws_access_key_id )
      aws_secret_access_key: $( inputs.aws_secret_access_key )
      aws_region_name: $( inputs.region_name )
      aws_endpoint_url: $( inputs.endpoint_url.value )
  ResourceRequirement: {}
  InitialWorkDirRequirement:
    listing:
    - entryname: stage.py
      entry: |-
        import os
        import sys
        import pystac
        import botocore
        import boto3
        import shutil
        from pystac.stac_io import DefaultStacIO, StacIO
        from urllib.parse import urlparse

        cat_url = sys.argv[1]
        bucket = sys.argv[2]
        subfolder = sys.argv[3]

        aws_access_key_id = os.environ["aws_access_key_id"]
        aws_secret_access_key = os.environ["aws_secret_access_key"]
        region_name = os.environ["aws_region_name"]
        endpoint_url = os.environ["aws_endpoint_url"]

        shutil.copytree(cat_url, "/tmp/catalog")
        cat = pystac.read_file(os.path.join("/tmp/catalog", "catalog.json"))

        class CustomStacIO(DefaultStacIO):
            """Custom STAC IO class that uses boto3 to read from S3."""

            def __init__(self):
                self.session = botocore.session.Session()
                self.s3_client = self.session.create_client(
                    service_name="s3",
                    use_ssl=True,
                    aws_access_key_id=aws_access_key_id,
                    aws_secret_access_key=aws_secret_access_key,
                    endpoint_url=endpoint_url,
                    region_name=region_name,
                )

            def write_text(self, dest, txt, *args, **kwargs):
                parsed = urlparse(dest)
                if parsed.scheme == "s3":
                    self.s3_client.put_object(
                        Body=txt.encode("UTF-8"),
                        Bucket=parsed.netloc,
                        Key=parsed.path[1:],
                        ContentType="application/geo+json",
                    )
                else:
                    super().write_text(dest, txt, *args, **kwargs)


        client = boto3.client(
            "s3",
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
            endpoint_url=endpoint_url,
            region_name=region_name,
        )

        StacIO.set_default(CustomStacIO)

        for item in cat.get_items():
            for key, asset in item.get_assets().items():
                s3_path = os.path.normpath(
                    os.path.join(os.path.join(subfolder, item.id, asset.href))
                )
                print(f"upload {asset.href} to s3://{bucket}/{s3_path}",file=sys.stderr)
                client.upload_file(
                    asset.get_absolute_href(),
                    bucket,
                    s3_path,
                )
                asset.href = f"s3://{bucket}/{s3_path}"
                item.add_asset(key, asset)

        cat.set_root(cat)
        for item in cat.get_items():
            item.set_root(cat)
        cat.normalize_hrefs(f"s3://{bucket}/{subfolder}")

        for item in cat.get_items():
            # upload item to S3
            print(f"upload {item.id} to s3://{bucket}/{subfolder}", file=sys.stderr)
            pystac.write_file(item, item.get_self_href())

        # upload catalog to S3
        print(f"upload catalog.json to s3://{bucket}/{subfolder}", file=sys.stderr)
        pystac.write_file(cat, cat.get_self_href())
        shutil.rmtree("/tmp/catalog/")
        print(f"s3://{bucket}/{subfolder}/catalog.json", file=sys.stdout)
  SchemaDefRequirement:
    types:
    - type: record
      name: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      doc: Represents a valid [URI](https://datatracker.ietf.org/doc/html/rfc3986).
      fields:
      - name: value
        type: string
        doc: A valid [URI](https://datatracker.ietf.org/doc/html/rfc3986).
$namespaces:
  s: https://schema.org/
s:softwareVersion: 0.0.1
s:codeRepository: https://github.com/eoap/stac-eoap
s:license: https://spdx.org/licenses/MIT.html
s:author:
- class: s:Person
  s:name: Fabrice Brito
  s:email: fabrice.brito@terradue.com
label: Stage out
