# Commodore

commodore project

## Installation

This package is published to the [Paketzentrum](https://gitlabe.imms.de/mygl/groups/paketzentrum/-/packages).

Please refer to this [README](https://gitlabe.imms.de/mygl/paketzentrum/readme) on how to setup the private package registry.
For example, configure pip like this:

```bash
pip config set install.extra-index-url "https://gitlabe.imms.de/mygl/api/v4/groups/paketzentrum/-/packages/pypi/simple"
```

Then, install the package via:

```bash
pip install commodore
```

The package requires at least Python 3.12.

Alternatively, you can clone this repository and install the package in editable mode. Refer to the development instructions.

## Development

### Getting Started

This package uses the Python project manager [uv](https://docs.astral.sh/uv/). To start development, please follow these steps:

1. Please refer to the [installation instructions](https://docs.astral.sh/uv/installation/) for uv. Please use version 0.9.10 or higher.

2. Clone this repository.
    ```bash
    git clone https://gitlabe.imms.de/mygl/paketzentrum/commodore.git
    cd commodore
    ```

3. (Optional) If your package depends on any packages from a private package registry, please set it up.
    Refer to the [README](https://gitlabe.imms.de/mygl/paketzentrum/readme) in the Paketzentrum for exhaustive details and follow the steps for [uv](https://docs.astral.sh/uv/).

4. Use `uv sync` to generate a virtual environment in `.venv`. This virtual environment can be sourced as usual:

    ```bash
    uv sync
    source .venv/bin/activate
    ```

The virtual environment will contain the package in editable mode, as well as all development dependencies.
VS Code can use it too!

Please note that you should never install any packages to the `.venv` manually! If you need additional dependencies or development dependencies, please edit them in `pyproject.toml` and re-run `uv sync`.

### Running Tests

This project uses [tox](https://tox.wiki/en/4.16.0/) for test orchestration.

By running it, you will run [pytest](https://docs.pytest.org/en/stable/), [mypy](https://mypy.readthedocs.io/en/stable/) and [ruff](https://docs.astral.sh/ruff/) all in one command:

```bash
uv run tox
```

uv will automatically download Python versions for tox.

Of course, you can run the tools independently too (as usual).
After activating the `.venv`, you can call them as usual, for example:

```bash
source .venv/bin/activate
ruff check src/commodore
mypy -p commodore
pytest commodore
```

### Committing changes

Before committing any changes, please remember the following steps:

1. Run all tests and static code checks via `tox`:

    ```bash
    uv run tox
    ```

2. (Optional) If you changed any dependencies (or just to be sure!), please run `uv sync` to re-create the lock file for your project. It must be committed to version control. The lock file allows restoring the exact environment you used yourself during development!

4. (Optional) Increment the package version in `pyproject.toml`.

### Publishing to the package registry

This project is configured to build and publish new versions of this package in Gitlab's CI.
They will be published to the private package registry on our Gitlab server.

To trigger this, please [create a tag](https://gitlabe.imms.de/mygl/paketzentrum/commodore/-/tags/new) for this project. It is recommended to name the tag same as the package version, with a minor `v` in front, e.g. `v1.0.0`.

Note that the version in `pyproject.toml` must not include the `v`.

The CI job will fail, if the same version already exists in the package registry. Please refer to best practice rules for semantic versioning when incrementing the version.


