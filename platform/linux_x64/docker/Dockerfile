FROM debian:latest
ENV DEBIAN_FRONTEND noninteractive

RUN groupadd \
  --gid 114 \
  engflow && \
  useradd \
  --home-dir /home/engflow \
  --create-home \
  --uid 108 \
  --gid 114 \
  engflow
ENV HOME=/home/engflow

RUN apt-get update --quiet --quiet --yes && \
  apt-get install --quiet --quiet --fix-broken --yes \
  clang \
  curl \
  python3 \
  python-is-python3 \
  zip && \
  rm -rf /var/lib/apt/lists/*
