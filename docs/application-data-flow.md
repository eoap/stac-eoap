# Application data flow management

The application consumes and produces STAC manifests in CWL `Directory` ports representing EO products. See [OGC Best Practice 20-089r1, sections 7.3.1, 7.4 and 8.3](https://docs.ogc.org/bp/20-089r1.html) for the requirements and [the platform flow](platform-data-flow.md) for staging responsibilities.

## Stage-in

The application receives a directory containing `catalog.json`, linked STAC Items, and accessible asset files. It opens that catalog and resolves each asset `href` relative to its Item JSON, rather than the current working directory:

```python
from pathlib import Path
import pystac
catalog = pystac.read_file(str(Path(staged_directory) / "catalog.json"))
item = next(catalog.get_items())  # This example processes one direct Item.
asset_path = item.assets["green"].get_absolute_href()
```

The application workflow's `item` input is a `Directory`. The wrapper exposes that input as a URI record, stages the referenced Item, and passes the resulting directory to the application. Internal workflow steps receive the staged directory through ordinary CWL connections; they do not each need an additional stage-in step. A directory used for scratch files is not automatically an EO product manifest.

## Stage-out

For each EO product output requiring staging, the application returns a directory with `catalog.json`, linked Items, and referenced result assets. Include geometry, `bbox`, and temporal metadata (`datetime`, or an interval with `start_datetime` and `end_datetime`) in each Item. The wrapper uploads the manifest and referenced assets and returns a URI record pointing to the uploaded catalog.

The training application returns `stac_catalog: Directory`; the staging tool returns `s3_catalog_output: URI`. Ordinary temporary directories are outside this product contract. Unreferenced files are not uploaded by the example stage-out implementation.

## Minimal output manifest

The following layout describes one result. The GeoTIFF must actually exist; JSON alone does not create it.

```text
results/
├── catalog.json
└── scene/
    ├── scene.json
    └── otsu.tif
```

`results/catalog.json`:

```json
{
  "stac_version": "1.0.0",
  "type": "Catalog",
  "id": "water-bodies",
  "description": "Water body detection results",
  "links": [
    {"rel": "root", "href": "./catalog.json", "type": "application/json"},
    {"rel": "item", "href": "./scene/scene.json", "type": "application/geo+json"}
  ]
}
```

`results/scene/scene.json`:

```json
{
  "stac_version": "1.0.0",
  "type": "Feature",
  "id": "scene",
  "geometry": {"type": "Polygon", "coordinates": [[[-119,38],[-118,38],[-118,39],[-119,39],[-119,38]]]},
  "bbox": [-119,38,-118,39],
  "properties": {"datetime": "2023-10-15T00:00:00Z"},
  "links": [
    {"rel": "root", "href": "../catalog.json", "type": "application/json"},
    {"rel": "parent", "href": "../catalog.json", "type": "application/json"}
  ],
  "assets": {
    "data": {
      "href": "./otsu.tif",
      "type": "image/tiff; application=geotiff; profile=cloud-optimized",
      "roles": ["data", "visual"]
    }
  }
}
```

Here `./otsu.tif` resolves to `results/scene/otsu.tif`. Replace the illustrative footprint and acquisition time with metadata for your actual output. Only declare the COG media type for a cloud optimized GeoTIFF.

## Validate before staging

From the repository root, set `catalog_path` to the generated catalog:

```bash
hatch run python - <<'PYCODE'
from pathlib import Path
import pystac
catalog_path = "notebooks/staged/catalog.json"
catalog = pystac.read_file(catalog_path)
catalog.validate_all()
for item in catalog.get_items(recursive=True):
    for asset in item.assets.values():
        href = asset.get_absolute_href()
        assert href is not None
        if href.startswith("file://"):
            from urllib.parse import unquote, urlparse
            href = unquote(urlparse(href).path)
        if "://" not in href:
            assert Path(href).is_file(), href
print("STAC metadata and local asset paths validated")
PYCODE
```

Schema validation may fetch schemas over the network. It checks metadata, while the path checks verify local assets; neither checks pixel values or remote asset accessibility. See [example limitations](cwl-reference.md#example-limitations) and [troubleshooting](troubleshooting.md).
