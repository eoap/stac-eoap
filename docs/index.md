# Introduction 

Platforms for the exploitation of Earth Observation (EO) data have been developed by public and private companies in order to foster the usage of EO data and expand the market of Earth Observation-derived information. A fundamental principle of the platform operations concept is to move the EO data processing service’s user to the data and tools, as opposed to downloading, replicating, and exploiting data ‘at home’. In this scope, previous OGC activities initiated the development of an architecture to allow the ad-hoc deployment and execution of applications close to the physical location of the source data with the goal to minimize data transfer between data repositories and application processes.

The OGC published the _Best Practice for Earth Observation Application Package_, a document defining the Best Practice to package and deploy Earth Observation Applications in an Exploitation Platform. The document is targeting the implementation, packaging and deployment of EO Applications in support of collaborative work processes between developers and platform owners.

The Best Practice includes recommendations for the application design patterns, package encoding, container and data interfaces for data stage-in and stage-out strategies focusing on three main viewpoints: Application, Package and Platform.

The focus of documentation set in on data interfaces for data stage-in and stage-out strategies.

## Earth Observation Applications

Earth Observation Applications typically offer functions that perform data operations like processing / reprocessing, projection, visualization or analysis. The applications can be written in a variety of coding languages (e.g. Python, R, Go, Java, C++, C#, shell scripts) and make use of specific software libraries (e.g. SNAP, GDAL, Orfeo Toolbox).

In the context of the Best Practice for Earth Observation Application Package, the application is treated as a black-box that according to its application design pattern must comply with data stage-in and data stage-out mechanisms defined.

## Staging Input and Output EO Products

EO product files come in different formats (e.g. GeoTIFF, HDF5, SAFE) and might have sub-items (e.g. metadata, bands, masks) that can be encoded in the same file or follow a given folder structure.

For example, SENTINEL-2 products are made available to users in the SENTINEL-SAFE format, including image data in JPEG2000 format, quality indicators (e.g. defective pixels mask), auxiliary data and metadata. The SAFE format wraps a folder containing image data in a binary data format and product metadata in XML. A SENTINEL-2 product refers to a directory folder that contains a collection of information that can include several files.

A main concern application developers face is the different approaches through which the products are made available (i.e. stage-in) to the applications. For example, applications might find the same exact folder structure and return the folder root or the main XML manifest file or have the folder structure compressed in a single archive file.

In general, the onus of navigating the input folder directory and programmatically reacting to how the file was staged-in by the platform is on application and the application developer needs to consider all possible cases when developing their read routines.

Conversely, the outputs of the application are fully managed by the developer that places the resulting files in an output directory. The only information the platform might receive about the output files is the file media type (formerly known as “MIME-type”) and is often missing critical information like spatial footprint, sub-items (e.g. masks, bands) and additional metadata (e.g. ground sample distance, orbit direction).

A good solution to represent the data manifest for input and output products is brought by the SpatioTemporal Asset Catalog (STAC).

## SpatioTemporal Asset Catalog (STAC)

The STAC specification standardizes the way geospatial assets are exposed online and queried. A ‘spatiotemporal asset’ is any file that represents information about the earth captured in a certain space and time (e.g. satellites, planes, drones, balloons).

The STAC specification defines several objects:

*  STAC Catalog: STAC Catalog is a collection of STAC Items or other STAC Catalogs (sub-catalogs). The division of sub-catalogs is transparently managed by links to ease online browsing.
*  STAC Collection: extends the STAC Catalog with additional fields to describe a whole set of STAC Items that share properties and metadata. STAC Collections are meant to be compatible with OGC API — Features Collections (OGC 17-069r3).
*  STAC Item: a GeoJSON Feature with additional fields (e.g. time, geo), links to related entities and STAC Assets.
*  STAC Asset: is an object that contains a link to data associated with the STAC Item that can be downloaded or streamed (e.g. data, metadata, thumbnails) and can contain additional metadata. Similar to atom:link it has properties like href, title, description, type and roles; but, most significantly, it allows relative paths.

Most importantly the STAC specification can be implemented in a completely ‘static’ manner as flat local files located near the data enabling the application to access products assets (e.g. JPEG 2000 band file, auxiliary data, browse) with a relative path (something that was not possible using OpenSearch as defined by OGC 13-026r8, OGC 13-032r8).

The _Best Practice for Earth Observation Application Package_ selected a STAC Catalog with STAC Item files as the data manifests format, for application that require staging input data and/or output results.