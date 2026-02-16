FROM scratch
ARG TARGETARCH
COPY ices0-linux-${TARGETARCH} /usr/local/bin/ices0
ENTRYPOINT ["/usr/local/bin/ices0"]
CMD ["-V"]
