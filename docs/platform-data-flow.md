# Platform data flow management

For the **data stage-in**, the Platform creates a local STAC Catalog with a STAC Item whose Assets have an accessible href (either local or remote e.g. COG) as the input files manifest for the application.

``` mermaid
graph TB
style AA stroke:#f66,stroke-width:3px
subgraph stage-in
A[STAC Item] -- STAC Item URL --> AA[Stage-in]
AA[Stage-in] -- catalog.json/item.json/assets blue, red,  nir ... --> AB[(local storage)]
end
subgraph EO Application
AB[(storage)] -- Staged STAC Catalog --> APP[read STAC Catalog]
end
```

For the **data stage-out**, the Application creates a local STAC Catalog as the output files manifest describing the results metadata and assets’ location thus enabling the Platform to provide the processing results in the OGC API — Processes response.

``` mermaid
graph TB
style BB stroke:#f66,stroke-width:3px
subgraph EO Application
APP[EO application]
APP -.-> F[Create STAC Catalog]
F -.-> G[(storage)]
end
subgraph stage-out
G -- "catalog.json/item.json" --> BB[Stage-out] 
BB --> H[("Remote 
 storage")]
end
```

## Example

The data flow management concepts mapped to the a Water Body Detection application are depicted below.

``` mermaid
graph TB
style AA stroke:#f66,stroke-width:3px
style BB stroke:#f66,stroke-width:3px
subgraph stage-in
A[STAC Item] -- STAC Item URL --> AA[Stage-in]
AA[Stage-in] -- catalog.json/item.json/assets blue, red,  nir ... --> AB[(local storage)]
end
subgraph Process STAC item
AB[(storage)] -- Staged STAC Catalog --> B
AB[(storage)] -- Staged STAC Catalog --> C
AB[(storage)] -- Staged STAC Catalog --> F
subgraph scatter on bands
B["crop(green)"];
C["crop(nir)"];
end
B["crop(green)"] -.-> D[Normalized difference];
C["crop(nir)"] -.-> D[Normalized difference];
D -.-> E[Otsu threshold]
end
E -.-> F[Create STAC Catalog]
F -.-> G[(storage)]

subgraph stage-out

G -- "catalog.json/item.json/asset otsu.tif" --> BB[Stage-out] 
BB --> H[("Remote 
 storage")]
end
```
