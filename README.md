# Understanding STAC for input/output data modelling in Earth Observation Applications

This repository contains documentation and notebooks for understanding the role of the [SpatioTemporal Asset Catalogs (STAC)](https://stacspec.org/en) Standard as input/output data manifests in Earth Observation (EO) applications and a hands-on with real-life scenarios.

The STAC specification standardizes the way geospatial assets are exposed online and queried. A ‘spatiotemporal asset’ is any file that represents information about the earth captured in a certain space and time (e.g. satellites, planes, drones, balloons).

The STAC specification defines several objects:

* **STAC Catalog**: a collection of STAC Items or other STAC Catalogs (sub-catalogs). 
* **STAC Collection**: extends the STAC Catalog with additional fields to describe a whole set of STAC Items that share properties and metadata. STAC Collections are meant to be compatible with OGC API — Features Collections (OGC 17-069r3).
* **STAC Item**: a GeoJSON Feature with additional fields (e.g. time, geo), links to related entities and STAC Assets.
* **STAC Asset**: is an object that contains a link to data associated with the STAC Item that can be downloaded or streamed (e.g. data, metadata, thumbnails) and can contain additional metadata. 

The Best Practice for EO Application Package selected a STAC Catalog with STAC Item files as the data manifests format, for application that require staging input data and/or output results.

The webpage of the documentation is eoap.github.io/stac-eoap/. 

[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC_BY--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
## Typed CWL training

The CWL examples use CWL 1.2 and EOAP schemas. Stage-in references and S3
endpoints are URI records with a `value` field; stage-out returns the same URI
type. The AOI is an OGC `BBox` record (`bbox` and `crs: CRS84`), EPSG is the
`4326` enum, and bands are enums (`green`, `nir`, `nir08`). CLI bindings convert
these values to the processing command's arguments. Staged inputs and local
results retain CWL `Directory` types.

Notebook 04 demonstrates typed parameters and executes stage-in, processing,
and stage-out. Notebook 05 composes the typed workflow and staging processes
using `eoap-cwlwrap==0.32.0`'s Python `wrap` API and packs the processes with
`cwl-loader==0.27.0`. The wrapper is maintained at
https://github.com/EOEPCA/eoap-cwlwrap. Its command-line plugin additionally
requires `transpiler-mate-runtime`; the notebooks use the Python API directly.

See `notebooks/cwl-workflow/typed-inputs.yaml` for processing inputs and
`notebooks/cwl-workflow/wrapped-inputs.yaml` for the end-to-end wrapper. Run
notebooks in order from their `notebooks` directory. Set the S3 endpoint and
credentials in notebooks 03 and 04 for your deployment. Staging CWL explicitly
requests network access and uses serial downloads with bounded timeouts.

## CWL documentation acceptance

Run `hatch run cwl-docs --validate --output /tmp/stac-cwl-docs` to validate metadata,
embedded module-defined types and the approved shared OGC schema import, and documented typed ports, and render Markdown
for all six CWL documents. This module-local generator is the equivalent
documentation path; compatibility with transpiler-mate cwl2markdown is not claimed.
The wrapping notebook additionally embeds wrapper-defined types in its generated CWL.

Validation on 11 October 2026: all six CWL documents pass the metadata/Markdown
check and isolated CWL validation allowing only the shared OGC import. Notebooks
01–03 passed in `/workspace/lab-results/20261010T215727173440Z`; the final
04–05 run passed in `/workspace/lab-results/20261010T220833487865Z`.
No `cwltool --pack` is used.
The final composed workflow also passed and returned
`s3://results/run-005/catalog.json`; its log is
`/workspace/stac-final-run.log` and result is `/workspace/stac-final-result.json`.
