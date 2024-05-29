FROM golang:1.20.7-bookworm AS builder
COPY . /src
WORKDIR /src/cmd/monitor
RUN APPVERSION=$(git describe --tags --long --always | tail -c 11) && echo "package main\n\nfunc init() {\n\tappVersion = \"${APPVERSION}\"\n}" > local.go
RUN go build

FROM debian:bookworm-slim AS usermanager
ARG UID=10000
ARG GID=10000
ARG USERNAME="mx"
ARG PACKAGES="ca-certificates"
RUN apt-get update && apt-get upgrade && apt-get install -y ${PACKAGES}
RUN groupadd -g ${GID} ${USERNAME} && useradd -u ${UID} -g ${GID} -m ${USERNAME}
RUN rm -rf /home/${USERNAME}/.bashrc /home/${USERNAME}/.profile /home/${USERNAME}/.bash_logout

FROM scratch AS runner
ARG UID=10000
ARG GID=10000
ARG USERNAME="mx"
COPY --from=builder /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=builder /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=usermanager /etc/ssl/certs /etc/ssl/certs
COPY --from=usermanager /etc/passwd /etc/passwd
COPY --from=usermanager /etc/group /etc/group
COPY --chown=${UID}:${GID} --from=usermanager /home/${USERNAME} /home/${USERNAME}
COPY --chown=${UID}:${GID} --from=builder /src/cmd/monitor/monitor /home/mx/monitor
USER ${USERNAME}
ENTRYPOINT [ "/home/mx/monitor" ]

