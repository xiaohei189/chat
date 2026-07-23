FROM golang:alpine AS builder

ARG RELEASE=false
ARG COMPRESS=false
WORKDIR /openim-chat

ENV GOPROXY=https://goproxy.cn,direct

RUN apk add --no-cache upx
RUN --mount=type=cache,target=/go/pkg/mod \
    go install github.com/magefile/mage@latest

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    RELEASE=${RELEASE} COMPRESS=${COMPRESS} mage build
RUN --mount=type=cache,target=/root/.cache/go-build \
    mage -compile ./mage -ldflags "-s -w"

FROM alpine:latest

WORKDIR /openim-chat

RUN apk add --no-cache bash

COPY --from=builder /openim-chat/_output ./_output
COPY --from=builder /openim-chat/config ./config
COPY --from=builder /openim-chat/start-config.yml ./start-config.yml
COPY --from=builder /openim-chat/mage ./mage

ENTRYPOINT ["sh", "-c", "./mage start && sleep infinity"]
