# Troubleshooting and recovery

| Symptom | Check and recovery |
| --- | --- |
| Imports fail or the wrong Python runs | Select the STAC EOAP kernel; check `sys.executable`. Recreate the Hatch environment after dependency changes. |
| Relative files or templates are missing | Check `os.getcwd()` is `notebooks/`. Resolve job file paths against the job file's directory. |
| Podman cannot start a CWL container | Run `podman info`, check image pull access and available disk space. The examples explicitly select Podman; using Docker requires changing that runtime setting. |
| Graphviz plots fail | Install the system `dot` executable; the Python `graphviz` package alone is insufficient. Static SVG documentation does not need Graphviz. |
| STAC read/download gets HTTP 403 or times out | Check the Item URL, provider access/signing requirements, and network connectivity from the execution environment. Stage-in uses 60-second HTTP timeouts and up to three download attempts; this is not an overall job deadline. |
| Missing band or an asset-related `AttributeError` | Inspect asset roles and EO `common_name` metadata. Use `green,nir08` for the Landsat scene. The current example can dereference a missing asset before reporting its intended missing-band error. |
| Crop does not overlap or Otsu has no finite pixels | Check AOI west/south/east/north order, CRS84 coordinates, scene footprint, and valid raster pixels. Use the provided scene and AOI together first. |
| S3 connection fails | Use the API port, not the console port. Check endpoint reachability from the host for notebook 03 and from the CWL container for notebook 04 and wrapping. Container `localhost` does not reach the host. |
| S3 reports missing bucket or access denied | Create the bucket first; check credentials, region and upload/read permissions. These examples require explicit key/secret inputs and do not support session tokens. |
| Results exist but the catalog cannot be opened | Inspect the root catalog's Item links and each asset `href`; use an S3-aware client with the same endpoint and credentials. A custom endpoint is not encoded in an `s3://` URI. |

## Logs and safe reruns

Capture a CLI run's output and errors separately:

```bash
hatch run cwltool --podman --outdir wrapped-run .main.cwl wrapped-params.yaml > result.json 2> run.log
```

Run from `notebooks/`. Add `--debug` when investigating a failure, and inspect the failed step's command and traceback in `run.log`. Review logs and notebook outputs for credentials before sharing them.

After an interrupted notebook, restart the kernel, confirm its working directory, and rerun prerequisite cells. Move an incomplete generated output directory aside before rerunning; notebooks 01–02 write into the working directory, and notebook 03 reuses `staged/`. Keep previous successful results separate. If a stage-out rerun reports `/tmp/catalog` already exists, a previous failure left the tool's temporary copy behind; in notebook 03's host process, move that temporary directory aside after checking it belongs to this run. A fresh CWL container has its own temporary directory.

Use a new CWL `--outdir` and S3 `sub_path` for each retry. Stage-out uploads assets and Items before the root catalog, so an interrupted upload can leave objects without a complete manifest. Inspect the old prefix, then remove only that failed run's objects if desired. Verify metadata and referenced assets using [validation](validation.md) before treating a returned URI as a complete result.
