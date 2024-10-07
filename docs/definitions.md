# Definitions

The _Best Practice for Earth Observation Application Package_ addresses data flow management of the input and output EO Products files by defining rules for the data stage-in and data stage-out for Applications that require staged files and/or generate files that need to be staged-out.

## Data stage-in definition

Data stage-in is the process to retrieve the inputs and make these available for the processing. Processing inputs are provided as catalogue references and the Platform is responsible for translating those references into inputs available as files for the local processing.

## Data stage-out definition

Data stage-out is the process to upload the output files generated by the processing onto external system(s), and make them available for later usage. The Platform retrieves the processing outputs and automatically stores them onto an external persistent storage. Additionally, the Platform should publish the metadata of the outputs onto a Catalogue and provide their references as an output.

## Application Data Flow Management

The Application data flow management relies on the rules:

* The computational workflow data interfaces use the Spatio Temporal Asset Catalog (STAC) to describe the **EO data inputs** and **generated results**

* Stage-in
    * All input parameters of the CWL `ComandLineTool` that require the staging of EO products shall be of type `Directory`. 
    * All input parameters of the CWL `Workflow` that require the staging of EO products shall be of type `Directory`.
    * Applications find a STAC `catalog.json` file

* Stage-out
    * Applications produce a STAC `catalog.json` in all outputs of type Directory
    * The outputs field of the `Workflow` that requires the stage-out of the generated products shall be of type `Directory`.

## Platform Data Flow Management

A Platform is responsible for the data flow management by using a local catalogue encoded using the SpatioTemporal Asset Catalog (STAC) specification as a data manifest for application inputs and outputs.

The local catalogue provides knowledge about the input and output files data contents like spatial footprint, sub-items (e.g. masks, bands) and additional metadata.

### Wrapping the Application Package

Wrap an Application Package:
* plug a stage-in step for all workflow inputs of type Directory
* plug a stage-out step for all workflow outputs of type Directory

The outcome is a wrapped CWL workflow that takes:
* the application package parameters
* any stage-in/stage-out parameters the platform may need to perform these operations
