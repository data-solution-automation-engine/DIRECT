# DIRECT

The Data Integration Run-time Execution Control Tool (DIRECT) is a framework for defining, orchestrating, and logging of data logistics processes and workflows so that a full audit trail is created.

The framework provides mechanism to administer the individual processes or workflows, and track their runtime execution.

This repository contains the following:

* [Data Model](https://github.com/data-solution-automation-engine/DIRECT/blob/main/Documentation/Model.md)
* [Documentation](https://github.com/data-solution-automation-engine/DIRECT/blob/main/Documentation/Documentation.md)
* Tables and scripts (DDL and DML)
* Examples and support scripts
* Testing script to validate any framework changes

## Learn more

* This repository belongs to this parent GitHub: [https://github.com/data-solution-automation-engine](https://github.com/data-solution-automation-engine)

## Getting started - quick guide

> [!NOTE]
> Additional details are available in the [installation](./Documentation/Installation.md) section.

### Setting up the development environment

Run the `SetupEnvironment.ps1` PowerShell script to ensure the local development environment is ready.

The following command will build all solutions inside, and downstream of, the directory that it is run in. Running in the root of this repository will build all solutions including the DIRECT framework and the tests.

```azurepowershell
dotnet build
```

### Running Unit Tests

Podman is required for full end-to-end unit testing and regression testing.

From the terminal, run the following commands:

```azurepowershell
winget install RedHat.Podman
winget install RedHat.Podman-Desktop
```

The `RunTests.ps1` PowerShell script can be run to run the DIRECT unit and regression tests in the container.
