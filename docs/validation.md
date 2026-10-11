# Validation and documentation maintenance

Run commands from the repository root unless stated otherwise. These commands let you generate evidence for your own checkout; historical run paths from another machine are not an acceptance test.

## Documentation and CWL

```bash
hatch run mkdocs build --strict
hatch run cwl-docs --validate --output /tmp/stac-cwl-docs
```

The module-local generator checks metadata, descriptions, embedded module types and the approved shared OGC import, validates each tracked CWL document, and renders port/type reference Markdown. It does not prove that an application run or storage upload succeeds. It is not a claim of compatibility with transpiler-mate's cwl2markdown. Its rendered files are review artifacts outside the site; [CWL interfaces](cwl-reference.md) provides the site reference.

## Notebook execution

Configure S3 in notebooks 03–04 first. From `notebooks/`, execute each notebook in order and keep executed copies outside the source directory:

```bash
mkdir -p ../artifacts/notebooks
hatch run jupyter nbconvert --to notebook --execute \
  --ExecutePreprocessor.kernel_name=stac-eoap \
  --ExecutePreprocessor.timeout=3600 \
  --output-dir=../artifacts/notebooks \
  '01 EO Products as Input Data.ipynb'
```

Repeat for notebooks 02, 03, 04 and 05. Review each exit status and the executed outputs. These runs fetch remote data, use disk space, and upload results for notebooks 03–04. Notebook 05 generates the composed workflow; then use the [wrapped execution command](cwl-reference.md#run-the-tools) with a fresh S3 prefix. Store its `result.json` and `run.log` alongside the executed notebooks, after reviewing them for credentials.

For application acceptance, validate the local catalog with the [STAC validation snippet](application-data-flow.md#validate-before-staging), inspect the raster, and verify that uploaded Catalog/Item links and assets are readable with your configured endpoint. CWL schema validation alone does not verify these properties.

## Diagrams

The checked-in SVGs are generated from the adjacent `.puml` sources in `docs/assets/diagrams/`. Pages embed SVGs directly; readers and MkDocs do not need PlantUML or a Mermaid plugin.

Install Java and obtain a [PlantUML jar](https://plantuml.com/download). From the repository root:

```bash
java -jar /path/to/plantuml.jar -tsvg docs/assets/diagrams/*.puml
```

These sequence diagrams render without Graphviz. Commit both source and generated SVG after an edit, inspect the rendered diagrams, and run the strict site build. See [PlantUML command-line usage](https://plantuml.com/command-line).

## Licensing

The repository's [LICENSE.md](https://github.com/eoap/stac-eoap/blob/main/LICENSE.md) and README specify CC BY-SA 4.0 for the training material. Individual CWL documents declare MIT in their `s:license` metadata; embedded EOAP schema definitions carry Apache-2.0 attribution. Preserve those file-level notices. The package metadata reflects the repository license; this documentation update does not change individual CWL license declarations.
