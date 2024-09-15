# Reference Databases and Dacpacs

Reference databases are maintained through a SQL SDK database project.

## Information on .sqlproj as Microsoft.Build.Sql Sdk project

More information

* [https://github.com/microsoft/DacFx](https://github.com/microsoft/DacFx)
* [https://learn.microsoft.com/en-us/dotnet/core/project-sdk/overview](https://learn.microsoft.com/en-us/dotnet/core/project-sdk/overview)  
    The SDK documentation has not been updated with the SQL SDK information, and might never be. This project is solely used to gain access to the dacpacs in a convenient way to make it easier to manage the project locally without manually configuring references.
* ADS/VS Code Extension: `ms-mssql.sql-database-projects-vscode` allows opening the project in Code. It currently isn't supported by Visual Studio.
* More information on SQL Database Projects: [https://learn.microsoft.com/en-us/azure-data-studio/extensions/sql-database-project-extension](https://learn.microsoft.com/en-us/azure-data-studio/extensions/sql-database-project-extension)
* Launch announcement: [https://techcommunity.microsoft.com/t5/azure-sql-blog/microsoft-build-sql-the-next-frontier-of-sql-projects/ba-p/3290628](https://techcommunity.microsoft.com/t5/azure-sql-blog/microsoft-build-sql-the-next-frontier-of-sql-projects/ba-p/3290628)
* Nuget for Master Dacpac [https://www.nuget.org/packages/Microsoft.SqlServer.Dacpacs.Master](https://www.nuget.org/packages/Microsoft.SqlServer.Dacpacs.Master)
* Nuget for Msdb Dacpac [https://www.nuget.org/packages/Microsoft.SqlServer.Dacpacs.Msdb](https://www.nuget.org/packages/Microsoft.SqlServer.Dacpacs.Msdb)

This allows it to pull the required reference Dacpac files from nuget without having to have SQL Server installed, or having a local reference to the system databases that will be in a different location and a different version for different developers.

This project format also allows building the project using dotnet, removing a dependency on other, less readily available toolings, which can be helpful when building in containers, or through pipelines with limited tool support.

Version and references are kept at SQL Server 2019/150

## Creating a project

sequence of events for creating this:

1. `dotnet tool update -g microsoft.sqlpackage`
1. `dotnet new install Microsoft.Build.Sql.Templates`
1. `dotnet new sqlproj -n "Reference_Databases"`
1. `dotnet add package Microsoft.SqlServer.Dacpacs.Master --version 150.1.1`
1. `dotnet add package Microsoft.SqlServer.Dacpacs.Msdb --version 150.0.0`

## Restoring nugets

* `dotnet restore`

a manual restore can be done if needed. Building should perform the restore if needed.

## building target

* `dotnet build`

building will add the `master.dacpac` and `msdb.dacpac` files to the `bin/Debug` folder, ready for referencing from the main database project.

To stop the need for restoring before opening the main database project, the reference Dacpac files are checked in as part of the repository.
