FROM jenkins/jenkins:lts

ARG DOCKER_GID=999
ARG BASE_DIGEST=""
ARG BASE_NAME=docker.io/jenkins/jenkins:lts
ARG SOURCE_URL=""

LABEL org.opencontainers.image.base.name="${BASE_NAME}" \
      org.opencontainers.image.base.digest="${BASE_DIGEST}" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.description="Jenkins LTS with official Docker CLI, Buildx, and Compose plugin"

USER root

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl; \
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc; \
    chmod a+r /etc/apt/keyrings/docker.asc; \
    . /etc/os-release; \
    printf '%s\n' \
      "Types: deb" \
      "URIs: https://download.docker.com/linux/debian" \
      "Suites: ${VERSION_CODENAME}" \
      "Components: stable" \
      "Architectures: $(dpkg --print-architecture)" \
      "Signed-By: /etc/apt/keyrings/docker.asc" \
      > /etc/apt/sources.list.d/docker.sources; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      docker-ce-cli \
      docker-buildx-plugin \
      docker-compose-plugin; \
    rm -rf /var/lib/apt/lists/*; \
    if getent group docker >/dev/null; then \
      groupmod -g "${DOCKER_GID}" docker || true; \
    else \
      groupadd -g "${DOCKER_GID}" docker; \
    fi; \
    usermod -aG docker jenkins

USER jenkins
