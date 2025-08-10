# Use Podman or Docker

Option 1: Environment Variable

Set an Environment variable and allow the test setup to detect that

Force Podman usage

`set USE_PODMAN=true`

Force Docker usage

`set USE_PODMAN=false`

Option 2: Manual Configuration

Set DOCKER_HOST to point to Podman socket

`set DOCKER_HOST=npipe://./pipe/podman-machine-default`

Option 3: Podman Docker Compatibility

Start Podman with Docker compatibility

`podman system service --time=0 tcp://localhost:2375`

Then set DOCKER_HOST

`set DOCKER_HOST=tcp://localhost:2375`

Verification Commands:
To verify which runtime is being used:

Check running containers

`podman ps    # If using Podman`

`docker ps    # If using Docker`

Check container logs

`podman logs <container-id>   # If using Podman`

`docker logs <container-id>   # If using Docker`
