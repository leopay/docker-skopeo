FROM golang:1.13-alpine
WORKDIR /go/src/github.com/bdwyertech/docker-skopeo/helper-utility
COPY helper-utility/ .
RUN CGO_ENABLED=0 GOFLAGS=-mod=vendor go build .

FROM golang:1.13-alpine
WORKDIR /go/src/github.com/containers/skopeo

RUN apk add --no-cache --virtual .build-deps git build-base btrfs-progs-dev gpgme-dev linux-headers lvm2-dev \
    && git clone --single-branch --branch v0.1.39 https://github.com/containers/skopeo.git . \
    && make binary-local \
    && apk del .build-deps

FROM library/alpine:3.10
COPY --from=0 /go/src/github.com/bdwyertech/docker-skopeo/helper-utility/helper-utility /usr/local/bin/
COPY --from=1 /go/src/github.com/containers/skopeo/skopeo /usr/local/bin/
ARG BUILD_DATE
ARG VCS_REF
ARG SKOPEO_VERSION

LABEL org.opencontainers.image.title="bdwyertech/c7n" \
      org.opencontainers.image.version=$SKOPEO_VERSION \
      org.opencontainers.image.description="For running Skopeo ($SKOPEO_VERSION) within a CI Environment" \
      org.opencontainers.image.authors="Brian Dwyer <bdwyertech@github.com>" \
      org.opencontainers.image.url="https://hub.docker.com/r/bdwyertech/skopeo" \
      org.opencontainers.image.source="https://github.com/bdwyertech/docker-skopeo.git" \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.created=$BUILD_DATE \
      org.label-schema.name="bdwyertech/skopeo" \
      org.label-schema.description="For running Skopeo ($SKOPEO_VERSION) within a CI Environment" \
      org.label-schema.url="https://hub.docker.com/r/bdwyertech/skopeo" \
      org.label-schema.vcs-url="https://github.com/bdwyertech/docker-skopeo.git"\
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.build-date=$BUILD_DATE

# Skopeo Policy
ADD docker-manifest/policy.json /etc/containers/policy.json

# Add the ECR Helper Utility
RUN wget -O /usr/local/bin/docker-credential-ecr-login -q https://github.com/bdwyertech/amazon-ecr-credential-helper/releases/download/bd_update_deps/docker-credential-ecr-login \
    && (echo '220e318c305f68d8b2c025702757e0f54cbc7d3ff820cb4e38676f12e7b71747  /usr/local/bin/docker-credential-ecr-login' | sha256sum -c) \
    && chmod +x /usr/local/bin/docker-credential-ecr-login

RUN apk update && apk upgrade \
    && apk add --no-cache bash ca-certificates device-mapper-libs gpgme \
    && adduser skopeo -S -h /home/skopeo

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
USER skopeo
WORKDIR /home/skopeo
CMD ["bash"]
