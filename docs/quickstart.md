# Quickstart

## Prerequisites

Use a Linux workstation with Python 3.11 or 3.12, Git, Hatch, Podman, and Graphviz (`dot`). The notebooks use Python syntax requiring at least 3.9; use the versions above for this training environment. Install Hatch with `python3 -m pip install --user hatch`, and install Podman and Graphviz through your operating system package manager.

Podman must be able to run containers as your user. Check `podman info` and `dot -V`. Internet access is required for Python packages, container images, the shared OGC schema, and public STAC assets. Stage-in downloads all assets for the selected scene, so allow several GB of free disk space; download time depends on the scene and connection.

## Create the notebook environment

From the repository root:

```bash
hatch env create
hatch run python -m ipykernel install --user --name stac-eoap --display-name "STAC EOAP"
hatch run jupyter lab notebooks
```

Select the **STAC EOAP** kernel. Run notebooks 01–05 in order, with their working directory set to `notebooks/`. Check `os.getcwd()` in the kernel before executing. Notebooks 01 and 02 create catalogs in that directory; notebook 03 creates `staged/`; notebook 04 writes CWL job files and `runs/`; notebook 05 generates `.main.cwl`.

If your environment restricts writes to your home directory, set `HATCH_ENV_TYPE_VIRTUAL_PATH` to a writable directory before creating the environment. Use a Jupyter installation whose kernels are writable as well.

The Hatch environment installs training dependencies without installing this repository as a Python package; it contains documentation and notebooks rather than an importable `stac_eoap` module.

## Provide S3 storage

Notebooks 03–04 and the wrapped workflow require a pre-existing writable bucket. Their original SeaweedFS endpoint is a deployment-specific example, not a service included in this repository. You can use an existing S3 service or the local MinIO setup below.

Start a local training instance with persistent storage:

```bash
podman volume create stac-eoap-s3
podman run -d --name stac-eoap-s3 \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=training \
  -e MINIO_ROOT_PASSWORD=training-secret \
  -v stac-eoap-s3:/data \
  quay.io/minio/minio:RELEASE.2025-04-22T22-12-26Z \
  server /data --console-address ":9001"
```

Open `http://localhost:9001`, sign in with the training credentials above, and create the `results` bucket. The S3 API listens on port 9000, while port 9001 serves the console. See the [MinIO container documentation](https://min.io/docs/minio/container/index.html).

Use these values in the S3 configuration cells in notebooks 03 and 04, and in a private copy of `wrapped-inputs.yaml`:

| Parameter | Value |
| --- | --- |
| `s3_bucket` | `results` |
| `sub_path` | A new prefix per run, such as `run-005-001` |
| `aws_access_key_id` | `training` |
| `aws_secret_access_key` | `training-secret` |
| `region_name` | `us-east-1` |
| `endpoint_url.value`, notebook 03 on the host | `http://localhost:9000` |
| `endpoint_url.value`, notebook 04 and wrapped CWL containers | `http://host.containers.internal:9000` |

Podman normally supplies `host.containers.internal` to reach the host. Verify this from a container before running stage-out; for remote Podman or another container engine, provide an address reachable from the actual execution host. `localhost` inside a processing container refers to that container.

These credentials are for local training. For another service, replace the endpoint, region and credentials and ensure permission to upload objects and read results. Keep real credentials out of committed input files and saved notebook outputs. This tool passes explicit credentials and does not expose a session-token input.

## Run and inspect

Follow the [hands-on sequence](hands-on.md), or use the [CWL commands](cwl-reference.md#run-the-tools). A successful application run produces a local catalog and `otsu.tif`; stage-out returns a record such as `{"value": "s3://results/run-005-001/catalog.json"}`.

Use the S3 console to inspect that prefix: it should contain `catalog.json`, an Item JSON, and the referenced GeoTIFF. An `s3://` URI is an authenticated object-storage reference, not a browser download URL. See [validation](validation.md) for metadata and asset checks and [troubleshooting](troubleshooting.md) for recovery.

To stop local storage, run `podman stop stac-eoap-s3`; resume it with `podman start stac-eoap-s3`. The named volume retains uploaded data.
