# Embedded schema definitions derived from eoap/schemas (Copyright 2025 Terradue, Apache-2.0).
cwlVersion: v1.2
class: CommandLineTool
id: my-asthonishing-stage-in-directory
inputs:
  reference:
    type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
    doc: A STAC Item to stage
    label: STAC Item URL
  another_input:
    type: string
    doc: An additional input for demonstration purposes
    label: Another Input
outputs:
  staged:
    type: Directory
    outputBinding:
      glob: .
    label: staged
    doc: staged.
baseCommand:
- python
- stage.py
arguments:
- $( inputs.reference.value )
- $( inputs.another_input )
requirements:
  NetworkAccess:
    networkAccess: true
  SchemaDefRequirement:
    types:
    - type: record
      name: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      doc: Represents a valid [URI](https://datatracker.ietf.org/doc/html/rfc3986).
      fields:
      - name: value
        type: string
        doc: A valid [URI](https://datatracker.ietf.org/doc/html/rfc3986).
  DockerRequirement:
    dockerPull: ghcr.io/eoap/mastering-app-package/stage:1.0.0@sha256:1a99609fdc7e28b47afa79d0187aafb6475f1b78a6e89b587d5ad3d1c35702da
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
    - entryname: stage.py
      entry: "import pystac\nimport stac_asset\nimport asyncio\nimport os\nimport sys\n\nconfig = stac_asset.Config(warn=False,\
        \ http_client_timeout=60, http_max_attempts=3, fail_fast=True)\n\nasync def main(href: str):\n    \n   \
        \ item = pystac.read_file(href)\n    \n    os.makedirs(item.id, exist_ok=True)\n    cwd = os.getcwd()\n\
        \    \n    os.chdir(item.id)\n    item = await stac_asset.download_item(item=item, directory=\".\", config=config)\n\
        \    os.chdir(cwd)\n    \n    cat = pystac.Catalog(\n        id=\"catalog\",\n        description=f\"catalog\
        \ with staged {item.id}\",\n        title=f\"catalog with staged {item.id}\",\n    )\n    cat.add_item(item)\n\
        \    \n    cat.normalize_hrefs(\"./\")\n    cat.save(catalog_type=pystac.CatalogType.SELF_CONTAINED)\n\n\
        \    return cat\n\nhref = sys.argv[1]\nempty_arg = sys.argv[2]\n\ncat = asyncio.run(main(href))"
$namespaces:
  s: https://schema.org/
s:softwareVersion: 0.0.1
s:codeRepository: https://github.com/eoap/stac-eoap
s:license: https://spdx.org/licenses/MIT.html
s:author:
- class: s:Person
  s:name: Fabrice Brito
  s:email: fabrice.brito@terradue.com
label: Stage in
doc: Stage in for the STAC EOAP training module.
