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