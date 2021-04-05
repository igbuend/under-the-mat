# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.166.0/containers/ubuntu/.devcontainer/base.Dockerfile

# [Choice] Ubuntu version: bionic, focal
ARG VARIANT="focal"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
   && apt-get -y install --no-install-recommends \
      apt-transport-https \
      bats \
      curl \
      python3 \
      python3-magic \
      python3-pip \
      python3-wheel \
      python3-setuptools \
      shellcheck &&\
   pip3 install --upgrade pip && \
   pip3 install pre-commit
