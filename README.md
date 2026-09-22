# Jenkins LTS + Docker CLI

This repository builds and publishes a **Jenkins LTS** container image that also includes the official **Docker CLI**, **Buildx**, and **Compose** plugin.

Images are based on [`jenkins/jenkins:lts`](https://hub.docker.com/r/jenkins/jenkins). A GitHub Actions workflow runs daily, rebuilds **only when** that upstream LTS image changes, and pushes a multi-arch image (`linux/amd64` and `linux/arm64`) to GitHub Container Registry.

Use this image when you want Jenkins to talk to a **host Docker daemon** through `/var/run/docker.sock`. The image does **not** run `dockerd` (not Docker-in-Docker).

## Install the image

Published image:

```text
ghcr.io/odoral/jenkins-docker
```

Tags:

| Tag | Meaning |
| --- | --- |
| `lts` | Rolling tag; latest successful build from Jenkins LTS |
| `lts-<version>` | Pinned to that Jenkins LTS version (for example `lts-2.541.1`) |
| `sha-<short>` | Build from a specific git commit (not created on the daily schedule) |

`docker pull` selects `linux/amd64` or `linux/arm64` to match the host.

```bash
docker pull ghcr.io/odoral/jenkins-docker:lts
```

If the package is public, no login is required. For a private package:

```bash
echo "$GITHUB_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
docker pull ghcr.io/odoral/jenkins-docker:lts
```

## Run Jenkins

Persist Jenkins home, publish the UI and agent ports, and mount the host Docker socket:

```bash
docker run -d --name jenkins \
  --restart on-failure \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/odoral/jenkins-docker:lts
```

Open `http://localhost:8080` and complete the usual Jenkins setup wizard.

### Docker socket permissions

The `jenkins` user is in the `docker` group (default GID `999`). If `docker` commands inside Jenkins fail with a permission error on the socket, match the host `docker` group:

```bash
getent group docker
```

Then either run with that group:

```bash
docker run -d --name jenkins \
  --restart on-failure \
  --group-add "$(getent group docker | cut -d: -f3)" \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/odoral/jenkins-docker:lts
```

or rebuild locally with `--build-arg DOCKER_GID=<gid>`.

### Compose example

```yaml
services:
  jenkins:
    image: ghcr.io/odoral/jenkins-docker:lts
    restart: on-failure
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  jenkins_home:
```

## How images are built

- **Dockerfile** installs Docker packages from [Docker’s Debian apt repository](https://docs.docker.com/engine/install/debian/): `docker-ce-cli`, `docker-buildx-plugin`, `docker-compose-plugin`.
- **Daily schedule** (06:00 UTC) compares the Jenkins LTS **index digest** with the digest recorded on the last GHCR `:lts` image. Unchanged upstream → no rebuild.
- **Push** to `main` (Dockerfile or workflow) and **workflow_dispatch** always rebuild.
- Native GitHub-hosted runners build `amd64` and `arm64`, then a merge job publishes one multi-arch manifest list.

## Local build

```bash
docker build -t jenkins-docker:local .
```
