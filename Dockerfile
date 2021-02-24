FROM golang:1.16-alpine as helper
WORKDIR /go/src/github.com/bdwyertech/docker-skopeo/helper-utility
COPY helper-utility/ .
RUN CGO_ENABLED=0 GOFLAGS=-mod=vendor go build -ldflags="-s -w" .
WORKDIR /go/src/github.com/bdwyertech/docker-skopeo/ecr-scanner
COPY ecr-scanner/ .
RUN CGO_ENABLED=0 GOFLAGS=-mod=vendor go build -ldflags="-s -w" .

FROM golang:1.16-alpine as amazon-ecr-credential-helper

RUN apk add --no-cache --virtual .build-deps git \
    && CGO_ENABLED=0 GOFLAGS=-mod=vendor go get github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login \
    && apk del .build-deps

FROM golang:1.16-alpine as skopeo
ARG SKOPEO_VERSION='v1.2.2'
WORKDIR /go/src/github.com/containers/skopeo

RUN apk add --no-cache --virtual .build-deps git build-base btrfs-progs-dev gpgme-dev linux-headers lvm2-dev \
    && git clone --single-branch --branch "$SKOPEO_VERSION" https://github.com/containers/skopeo.git . \
    && make bin/skopeo \
    && apk del .build-deps

FROM library/alpine:3.13
COPY --from=helper /go/src/github.com/bdwyertech/docker-skopeo/helper-utility/helper-utility /usr/local/bin/
COPY --from=helper /go/src/github.com/bdwyertech/docker-skopeo/ecr-scanner/ecr-scanner /usr/local/bin/
COPY --from=skopeo /go/src/github.com/containers/skopeo/bin/skopeo /usr/local/bin/
COPY --from=amazon-ecr-credential-helper /go/bin/docker-credential-ecr-login /usr/local/bin

ARG BUILD_DATE
ARG VCS_REF
ARG SKOPEO_VERSION='v1.2.2'

LABEL org.opencontainers.image.title="bdwyertech/skopeo" \
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

RUN apk update && apk upgrade \
    && apk add --no-cache bash ca-certificates device-mapper-libs gpgme \
    && adduser skopeo -S -h /home/skopeo

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
USER skopeo
WORKDIR /home/skopeo
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bash"]
