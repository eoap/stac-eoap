cwlVersion: v1.0
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.0
schemas:
  - http://schema.org/version/9.0/schemaorg-current-http.rdf
$graph:
  - class: Workflow
    id: main
    label: Water bodies detection based on NDWI and the otsu threshold
    doc: Water bodies detection based on NDWI and otsu threshold applied to a single Sentinel-2 COG STAC item
    requirements: []
    inputs:
      aoi:
        label: area of interest
        doc: area of interest as a bounding box
        type: string
      epsg:
        label: EPSG code
        doc: EPSG code
        type: string
        default: "EPSG:4326"
      bands:
        label: bands used for the NDWI
        doc: bands used for the NDWI
        type: string[]
        default: ["green", "nir"]
      item:
        doc: Staged EO acquisition as a STAC Catalog
        label: Staged EO acquisition 
        type: Directory
    outputs:
      - id: stac_catalog
        outputSource:
          - node_detect/stac-catalog
        type: Directory
    steps:
      node_detect:
        run: "#detect-water-body"
        in:
          item: item
          aoi: aoi
          epsg: epsg
          band: bands
        out:
          - stac-catalog
  - class: CommandLineTool
    id: detect-water-body
    requirements:
        InlineJavascriptRequirement: {}
        EnvVarRequirement:
          envDef:
            PYTHONPATH: /app
        ResourceRequirement:
          coresMax: 1
          ramMax: 512
    hints:
      DockerRequirement:
        dockerPull: localhost/detect-water-body:latest
    baseCommand: ["python", "-m", "app"]
    arguments: []
    inputs:
      item:
        type: Directory
        inputBinding:
            prefix: --input-item
      aoi:
        type: string
        inputBinding:
            prefix: --aoi
      epsg:
        type: string
        inputBinding:
            prefix: --epsg
      band:
        type:
          - type: array
            items: string
            inputBinding:
              prefix: '--band'

    outputs:
      stac-catalog:
        outputBinding:
            glob: .
        type: Directory


