# Embedded schema definitions derived from eoap/schemas (Copyright 2025 Terradue, Apache-2.0).
cwlVersion: v1.2
class: CommandLineTool
id: my-asthonishing-stage-in-file
inputs:
  reference:
    type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
    doc: An URL to stage
    label: Reference URL
  another_input:
    type: string
    doc: An additional input for demonstration purposes
    label: Another Input
outputs:
  staged:
    type: File
    outputBinding:
      glob: staged
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
    dockerPull: ghcr.io/eoap/application-package-patterns/vegetation-indexes:0.1.1
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
    - entryname: stage.py
      entry: |-
        import sys
        import requests
        import planetary_computer

        href = sys.argv[1]

        signed_url = planetary_computer.sign(href)
        output_path = "staged"

        response = requests.get(signed_url, stream=True, timeout=60)
        response.raise_for_status()  # Raise an error for bad status codes

        with open(output_path, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

        print(f"Downloaded to {output_path}")

        empty_arg = sys.argv[2]
$namespaces:
  s: https://schema.org/
s:softwareVersion: 0.0.1
s:codeRepository: https://github.com/eoap/stac-eoap
s:license: https://spdx.org/licenses/MIT.html
s:author:
- class: s:Person
  s:name: Fabrice Brito
  s:email: fabrice.brito@terradue.com
label: Stage in file
doc: Stage in file for the STAC EOAP training module.
