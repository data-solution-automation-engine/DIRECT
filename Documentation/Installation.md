# Installing DIRECT

The DIRECT framework can be deployed to a target database from the dotnet solution/project, using Visual Studio, Visual studio Code, dotnet, sqlpackage using their publish/deploy functionality. Alternatively, the project can be built/compiled to a DACPAC and deployed via scripts, pipelines, command-line tools such as sqlcmd.

As part of the installation, post deployment scripts are run to provide the standard framework contents. Pre- and post DACPAC deployment placeholders are also available.

## SDK-type project

Microsoft had a fairly static approach to SQL projects over a long period. The new SDK approach has a rough start, but with the SQL Server 2025 launch the whole eco-system has had an injection of effort which allows this project to modernise and use the latest SDK approach. This means all surrounding tools and approaches should match and be compatible with the SDK format. This is now broadly supported in both command line tools, development environments like Visual Studio and Visual Stuidio Code, apps like Management Studio, as well as in ci/cd environments.

Please make sure to update any tools used to a version that is comfortable with the SDK approach.

## Defining the target database type

The project format supports targeting a range of SQL server versions and variations. The repository has a single default defined, which might not suit all scenarios.

Update the database specifications, configurations, and references to match the current environment so that it can be built and deployed as needed.

More information, and references to current targets and versions and monikers can be found here:

* The SQL server Master database reference. This helps with items such as `INFORMATION_SCHEMA` references. An other option might be to explore the system database reference approach, if nuget isn't convenient.  
  [Nuget - Microsoft.SqlServer.Dacpacs.Master](https://www.nuget.org/packages/Microsoft.SqlServer.Dacpacs.Master#versions-body-tab)

* The SQL database, framework, or platform target definition. This is editable through some UI's, and can also be updated through the project file with a valid value from the linked list.  
  [database target platform monikers](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/concepts/target-platform?view=sql-server-ver17&pivots=sq1-visual-studio)

## Code analysis

* Static code analysis tools.  
  The project uses static code analysis by enabling `<RunSqlCodeAnalysis>True</RunSqlCodeAnalysis>` in the project file. It is also possible to run tbe build and specifically ask for code analysis.  
  More information can be found here: [learn.microsoft.com SQL code analysis](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/concepts/sql-code-analysis/sql-code-analysis?view=sql-server-ver17&pivots=sq1-visual-studio-sdk)
  The project uses 2 additional Nuget packages from the repo below to support and extend the analysis capability.  
  [ErikEJ - SqlServer.Rules](https://github.com/ErikEJ/SqlServer.Rules)

## Database testing

* Database Testing  
  Testing approach and details tba
