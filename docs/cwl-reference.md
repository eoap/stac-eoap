# CWL interfaces and execution

The examples use CWL 1.2. The processing interface uses local `Directory` objects; wrapping changes the EO input to a URI record and adds staging parameters. A URI record's `value` is converted to a command argument or environment variable by the CWL bindings.

## Parameters

| Port | Application | Wrapped workflow / staging | Meaning |
| --- | --- | --- | --- |
| `item` | `Directory` | URI record | Local catalog folder, or remote STAC Item URL to stage |
| `aoi` | OGC BBox record | Same | Four values in west, south, east, north order; `crs: CRS84` (longitude, latitude) |
| `epsg` | Enum, default `"4326"` | Same | CRS of AOI coordinates; only `"4326"` is accepted here |
| `bands` | Array of band enums | Same | Use exactly two ordered bands: `green`, then `nir08` for the Landsat example |
| `stac_catalog` | Output `Directory` | Input to stage-out | Folder containing the output catalog and assets |
| `reference` | — | Stage-in URI record | URL of one STAC Item, not a search response or Catalog |
| `endpoint_url` | — | URI record | S3 API endpoint reachable from the stage-out container |
| `s3_bucket`, `sub_path` | — | Strings | Existing bucket and destination prefix |
| `aws_access_key_id`, `aws_secret_access_key`, `region_name` | — | Strings | Storage credentials and region |
| `another_input` | — | String, templates only | Demonstration parameter; use `training`; not used to process data |
| `s3_catalog_output` | — | Stage-out output URI record | Uploaded root catalog location |

Application job shape:

```yaml
item:
  class: Directory
  path: /absolute/path/to/staged
aoi:
  class: https://raw.githubusercontent.com/eoap/schemas/main/ogc.yaml#BBox
  bbox: [-118.985, 38.432, -118.183, 38.938]
  crs: CRS84
epsg: "4326"
bands: [green, nir08]
```

Use the complete tracked [processing input example](https://github.com/eoap/stac-eoap/blob/main/notebooks/cwl-workflow/typed-inputs.yaml) and [wrapped input example](https://github.com/eoap/stac-eoap/blob/main/notebooks/cwl-workflow/wrapped-inputs.yaml). Their URI records have the following shape:

```yaml
reference:
  class: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
  value: https://planetarycomputer.microsoft.com/api/stac/v1/collections/landsat-c2-l2/items/LC09_L2SP_042033_20231015_02_T1
```

URI records and module-defined band/EPSG enums are embedded in the CWL. The shared OGC BBox schema is still imported from `eoap/schemas/main/ogc.yaml`, so loading the document can require network access. Pin or vendor that schema if your deployment needs an immutable offline dependency.

## Run the tools

Run these commands from `notebooks/`, after configuring the environment in [Quickstart](quickstart.md). The CLI staging files are used by notebook 04; `templates/` contains the demonstration tools used by notebook 05, including a separate single-file downloader.

Create `stage-in-params.yaml` using the `reference` record above, then run:

```bash
hatch run cwltool --podman --outdir staged-run cwl-cli/stage-in.cwl stage-in-params.yaml
```

Read the emitted CWL JSON's `staged.location`. Copy `cwl-workflow/typed-inputs.yaml` to `processing-params.yaml` and set `item.path` to that directory's absolute path. Relative CWL paths resolve against the job file; the example's `../staged` assumes notebook 03 has created that folder.

```bash
hatch run cwltool --podman --outdir processing-run \
  'cwl-workflow/app-water-bodies.cwl#water-bodies-detection' processing-params.yaml
```

Use the emitted `stac_catalog.location` for stage-out's `stac_catalog.path`. Create `stage-out-params.yaml`:

```yaml
stac_catalog:
  class: Directory
  path: /absolute/path/from/stac_catalog/location
s3_bucket: results
sub_path: run-004-001
aws_access_key_id: training
aws_secret_access_key: training-secret
region_name: us-east-1
endpoint_url:
  class: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
  value: http://host.containers.internal:9000
```

```bash
hatch run cwltool --podman --outdir stage-out-run cwl-cli/stage-out.cwl stage-out-params.yaml
```

For end-to-end execution, run notebook 05 to generate `.main.cwl`, copy `cwl-workflow/wrapped-inputs.yaml` to `wrapped-params.yaml`, and update its storage configuration using [Quickstart](quickstart.md):

```bash
hatch run cwltool --validate .main.cwl
hatch run cwltool --podman --outdir wrapped-run .main.cwl wrapped-params.yaml
```

Notebook 05 uses `eoap-cwlwrap==0.32.0`'s Python `wrap` API and `cwl-loader==0.27.0` serialization; no `cwltool --pack` is needed. Its generated input/output tables are the authority for the composed workflow's port names. The wrapper's command-line plugin separately requires `transpiler-mate-runtime`.

## Example limitations

These are training examples, not a general batch processor:

- Processing takes the first direct Item in the input Catalog. Supply exactly one Item; additional Items are not processed.
- Stage-out uses `get_items()` without recursive traversal. Use direct Items with local relative asset paths; nested catalogs and remotely hosted output assets are not handled by this uploader.
- Input assets need a `data` role and EO band metadata with the requested `common_name`. Landsat uses `nir08`; the Sentinel-2 notebook uses `nir`.
- Band order controls `(first - second) / (first + second)`. Use green followed by NIR. The enum allows `green`, `nir`, `nir08`, but the array schema does not enforce exactly two entries.
- The AOI must overlap the selected scene and contain finite pixels for Otsu thresholding. The CWL binding requires a four-coordinate BBox; this example supports CRS84/4326 AOIs.
- The output is a uint8 water mask (`1` above the Otsu threshold, `0` otherwise), with the input acquisition time and a footprint derived from the output raster. It does not implement cloud masking or a scientific accuracy assessment.
- Stage-out uploads referenced assets only. Reusing a destination prefix can overwrite matching objects; use a fresh prefix. Uploads are not transactional, and failures can leave partial results.
