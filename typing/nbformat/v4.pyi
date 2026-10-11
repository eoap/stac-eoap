from nbformat.notebooknode import NotebookNode

# Public notebook cell factory used by the acceptance runner.
def new_code_cell(source: str = "") -> NotebookNode: ...
