# Understanding STAC for input/output data modelling in Earth Observation Applications

This repository contains documentation and notebooks for understanding the role of the [SpatioTemporal Asset Catalogs (STAC)](https://stacspec.org/en) Standard as input/output data manifests in Earth Observation (EO) applications and a hands-on with real-life scenarios.

The STAC specification standardizes the way geospatial assets are exposed online and queried. A ‘spatiotemporal asset’ is any file that represents information about the earth captured in a certain space and time (e.g. satellites, planes, drones, balloons).

The STAC specification defines several objects:

* **STAC Catalog**: a collection of STAC Items or other STAC Catalogs (sub-catalogs).
* **STAC Collection**: extends the STAC Catalog with additional fields to describe a whole set of STAC Items that share properties and metadata. STAC Collections are meant to be compatible with OGC API — Features Collections (OGC 17-069r3).
* **STAC Item**: a GeoJSON Feature with additional fields (e.g. time, geo), links to related entities and STAC Assets.
* **STAC Asset**: is an object that contains a link to data associated with the STAC Item that can be downloaded or streamed (e.g. data, metadata, thumbnails) and can contain additional metadata.

The Best Practice for EO Application Package selected a STAC Catalog with STAC Item files as the data manifests format, for application that require staging input data and/or output results.

The [documentation website](https://eoap.github.io/stac-eoap/) covers the concepts and hands-on examples.

[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC_BY--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
## Getting started

Follow the [quickstart](docs/quickstart.md) to create the notebook environment, configure Podman and S3 storage, and select the Python kernel. Run notebooks 01–05 in order from `notebooks/`.

- [Hands-on sequence](docs/hands-on.md)
- [Application STAC manifest contract](docs/application-data-flow.md)
- [Typed CWL interfaces and execution](docs/cwl-reference.md)
- [Troubleshooting and recovery](docs/troubleshooting.md)
- [Validation, diagram regeneration and licensing](docs/validation.md)

## Documentation checks

```bash
hatch run mkdocs build --strict
hatch run cwl-docs --validate --output /tmp/stac-cwl-docs
```

The second command validates metadata and CWL and renders reference Markdown for the six tracked CWL documents. Runtime acceptance additionally requires executing the configured notebooks and wrapped workflow and verifying the uploaded STAC assets; see [validation](docs/validation.md). No historical run logs or external workspace paths are required.

Diagrams are maintained as PlantUML sources and checked-in SVGs in `docs/assets/diagrams/`.

## Release acceptance

Python 3.12 notebook dependencies are locked with hashes in
`requirements-notebooks.txt`. Install with `uv pip sync --require-hashes`, then
register `stac_env` and the Bash kernel. `scripts/run-notebooks.py` executes all
five notebooks and preserves executed copies separately. Start from a clean
checkout of the intended release commit.

Acceptance CI runs those notebooks with real EO inputs, Podman and an isolated
SeaweedFS instance, validates all standalone CWL/Markdown, and builds MkDocs
strictly. `STAC_S3_ENDPOINT` selects the storage endpoint; `CWL_CUSTOM_NET` can
select a Podman network for the CWL execution. The PDE defaults remain the
in-cluster SeaweedFS endpoint. Processing runtime images are pinned by digest.

## Course packaging and development checks

This repository distributes course metadata and notebooks; it has no
module-owned Python processing container. Its wheel uses Hatchling with Python
3.12, and `requirements/development.txt` locks the notebook and validation tools
with hashes. Run `hatch run dev:check` for formatting, lint, strict typing and
security checks. Run `hatch run test:test` to validate isolated CWL and its
Markdown documentation contract. Full acceptance additionally runs all five
notebooks with real EO data and checks the composed workflow's S3 output.

The locked bootstrap is explicit because Hatch skips installation hooks for
`skip-install = true`. Notebook environments install the project only after the
lock is installed. The SDK fetcher used during isolated CWL validation retains
the published OGC-schema restriction; shared schema imports remain remote, and
module-owned schema definitions stay inline.
