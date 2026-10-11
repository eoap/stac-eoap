"""Execute the deployed training notebooks without overwriting their sources."""

import argparse
import os
import shlex
import sys
from datetime import UTC, datetime
from pathlib import Path


def execute_notebook(
    source: Path,
    root: Path,
    output: Path,
    python_kernel: str,
    timeout: int,
    index: int,
    total: int,
) -> bool:
    import nbformat
    from nbclient import NotebookClient

    relative = source.relative_to(root)
    notebook = nbformat.read(source, as_version=4)
    kernel = notebook.metadata.get("kernelspec", {}).get("name", "python3")
    language = notebook.metadata.get("kernelspec", {}).get("language", "").lower()
    if kernel == "python3" or language == "python":
        kernel = python_kernel
    # Bash startup files may activate the editor's old environment.
    # Restore the environment selected by the acceptance invocation.
    if language in ("bash", "shell") and os.environ.get("VIRTUAL_ENV"):
        activation = Path(os.environ["VIRTUAL_ENV"]) / "bin" / "activate"
        notebook.cells.insert(
            0, nbformat.v4.new_code_cell("source " + shlex.quote(str(activation)))
        )
    target = output / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    print(f"[{index}/{total}] Running {relative} (kernel: {kernel})", flush=True)
    try:
        NotebookClient(
            notebook,
            timeout=timeout,
            kernel_name=kernel,
            allow_errors=False,
            resources={"metadata": {"path": str(source.parent)}},
        ).execute()
    except Exception as error:
        print(f"FAILED {relative}: {error}", file=sys.stderr, flush=True)
        return False
    finally:
        nbformat.write(notebook, target)
        print(f"Saved {target}", flush=True)
    print(f"PASSED {relative}", flush=True)
    return True


def discover_notebooks(root: Path, pattern: str) -> list[Path]:
    discovered: set[Path] = set()
    for match in root.glob(pattern):
        if match.is_dir():
            discovered.update(match.rglob("*.ipynb"))
        elif match.suffix == ".ipynb":
            discovered.add(match)
    return sorted(p for p in discovered if ".ipynb_checkpoints" not in p.parts)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--lab", default="*", help="Chapter, notebook, or glob under the notebook directory"
    )
    parser.add_argument("--timeout", type=int, default=1800, help="Seconds per cell")
    parser.add_argument("--list", choices=("true", "false"), default="false")
    parser.add_argument(
        "--python-kernel", default="mastering_env", help="Kernel for Python notebooks"
    )
    parser.add_argument("--workspace", type=Path, default=Path("/workspace/mastering-app-package"))
    parser.add_argument(
        "--notebooks-dir",
        default="practice-labs",
        help="Notebook directory relative to the workspace",
    )
    parser.add_argument("--output", type=Path, default=Path("/workspace/lab-results"))
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if Path(args.notebooks_dir).is_absolute() or ".." in Path(args.notebooks_dir).parts:
        parser.error("--notebooks-dir must stay inside the workspace")
    root = args.workspace / args.notebooks_dir
    if not root.is_dir():
        parser.error(f"Notebook directory not found: {root}")
    if Path(args.lab).is_absolute() or ".." in Path(args.lab).parts:
        parser.error("--lab must stay inside the notebook directory")
    notebooks = discover_notebooks(root, args.lab)
    if not notebooks:
        parser.error(f"No notebooks match {args.lab!r}")
    for notebook in notebooks:
        print(notebook.relative_to(root), flush=True)
    if args.list == "true":
        return 0

    # Bash kernels recognize a fixed prompt; venv activation must preserve it.
    os.environ["VIRTUAL_ENV_DISABLE_PROMPT"] = "1"

    output = args.output / datetime.now(UTC).strftime("%Y%m%dT%H%M%S%fZ")
    print(f"Executed notebooks: {output}", flush=True)
    for index, source in enumerate(notebooks, 1):
        if not execute_notebook(
            source, root, output, args.python_kernel, args.timeout, index, len(notebooks)
        ):
            return 1
    print(f"All {len(notebooks)} notebooks passed", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
