FROM alpine:latest
RUN apk add --no-cache tini
ARG TARGETARCH
COPY ices0-linux-${TARGETARCH} /usr/local/bin/ices0
COPY docker/rootfs/ /
RUN chmod +x /usr/local/bin/ices0 /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
