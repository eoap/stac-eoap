cwlVersion: v1.2
class: CommandLineTool
id: main
inputs:
  reference:
    type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
outputs:
  staged:
    type: Directory
    outputBinding:
      glob: .
baseCommand:
- python
- stage.py
arguments:
- $( inputs.reference.value )
requirements:
  NetworkAccess:
    networkAccess: true
  DockerRequirement:
    dockerPull: ghcr.io/eoap/mastering-app-package/stage:1.0.0
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
    - entryname: stage.py
      entry: "import pystac\nimport stac_asset\nimport asyncio\nimport os\nimport sys\n\nconfig = stac_asset.Config(warn=False,\
        \ http_client_timeout=60, http_max_attempts=3, fail_fast=True)\n\nasync def main(href: str):\n    \n   \
        \ item = pystac.read_file(href)\n    \n    os.makedirs(item.id, exist_ok=True)\n    cwd = os.getcwd()\n\
        \    \n    os.chdir(item.id)\n    item = await stac_asset.download_item(item=item, directory=\".\", config=config,\
        \ max_concurrent_downloads=1)\n    os.chdir(cwd)\n    \n    cat = pystac.Catalog(\n        id=\"catalog\"\
        ,\n        description=f\"catalog with staged {item.id}\",\n        title=f\"catalog with staged {item.id}\"\
        ,\n    )\n    cat.add_item(item)\n    \n    cat.normalize_hrefs(\"./\")\n    cat.save(catalog_type=pystac.CatalogType.SELF_CONTAINED)\n\
        \n    return cat\n\nhref = sys.argv[1]\n\ncat = asyncio.run(main(href))"
  SchemaDefRequirement:
    types:
    - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
