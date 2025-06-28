FROM mcr.microsoft.com/mssql/server:2022-latest
ENV ACCEPT_EULA=Y
ENV MSSQL_SA_PASSWORD=SuperP@ssw0rd

# build the image with the following command, cwd is where the ContainerFile is located:
# podman build -t mssql-eula:2022 .

# run the container with the following command:
# change the port mapping if necessary, i.e. running sql server locally  
# podman run -d -it -p 1433:1433 mssql-eula:2022 

# connect to the container from ssms using the following connection string:
# 127.0.0.1,1433 with the username sa and password SuperP@ssw0rd

# deploy dacpac file to the container using the following command:
# this uses the dotnet tool sqlpackage,
# restore with: 
# dotnet tool restore 
# or install it with:
# dotnet tool install --global dotnet-sqlpackage

# dotnet SqlPackage /a:Publish /tsn:"127.0.0.1,1433" /tdn:"direct_test" \
#    /ttsc:True /tu:"sa" /tp:SuperP@ssw0rd \
#    /sf:"Direct_Framework/bin/Debug/Direct_Framework.dacpac" 