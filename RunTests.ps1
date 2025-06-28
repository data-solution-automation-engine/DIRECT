# build all and run all tests
dotnet restore

dotnet build .\Direct_Framework\Direct_Framework.sqlproj

# 1. make sure Docker Desktop / podman is running
# 2. build the test DACPAC
dotnet build Direct_Framework.tsqlt.Tests/Direct_Framework.tsqlt.Tests.sqlproj

# # 3. launch tests in a *throw-away* SQL Server 2022 container
dotnet sqltest runall `
     --project Direct_Framework.tsqlt.Tests/Direct_Framework.tsqlt.Tests.sqlproj `
     --image localhost/mssql-eula:2022 `
     --result .coverage/tsqlt.junit.xml `
     --cc-cobertura .coverage/tsqlt.cobertura.xml


# dotnet build .\Direct_Framework.tsqlt.Tests\Direct_Framework.tsqlt.Tests.sqlproj

# dotnet test tests

# dotnet sqltest runall --project Direct_Framework.tsqlt.Tests/Direct_Framework.tsqlt.Tests.sqlproj --image mcr.microsoft.com/mssql/server:2022-latest