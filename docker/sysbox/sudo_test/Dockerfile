FROM ubuntu:22.04

RUN apt-get update -yq
RUN apt-get install -yq ca-certificates curl gnupg
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl --insecure -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

ENV ENGFLOW_RBE_USER_ID=108
ENV ENGFLOW_RBE_USER_NAME=engflow
ENV ENGFLOW_RBE_GROUP_ID=114
ENV ENGFLOW_RBE_GROUP_NAME=engflow

RUN groupadd --non-unique -g "${ENGFLOW_RBE_GROUP_ID}" docker
RUN groupadd --non-unique -g "${ENGFLOW_RBE_GROUP_ID}" "${ENGFLOW_RBE_GROUP_NAME}"

RUN useradd \
    -rm \
    -s /bin/bash \
    -g docker \
    -u "${ENGFLOW_RBE_USER_ID}" \
    "${ENGFLOW_RBE_USER_NAME}"

RUN apt-get update -yq

RUN apt-get install -yq sudo
RUN echo "${ENGFLOW_RBE_USER_NAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${ENGFLOW_RBE_USER_NAME}"
RUN chmod 0440 "/etc/sudoers.d/${ENGFLOW_RBE_USER_NAME}"

RUN apt-get install -yq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

COPY --chmod=0755 entrypoint.sh /entrypoint.sh

USER root
WORKDIR "/home/${ENGFLOW_RBE_USER_NAME}"

ENTRYPOINT [ "/entrypoint.sh" ]
