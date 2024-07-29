ARG OSTYPE=linux-gnu
ARG ARCHITECTURE=x86_64
ARG DOCKER_REGISTRY=ghcr.io
ARG DOCKER_IMAGE_NAME


# List out all image permutations to trick dependabot
FROM --platform=linux/amd64 ghcr.io/gh-org-template/kong-build-images:apk-1.1.1 as x86_64-linux-musl
RUN echo 'noop'

FROM --platform=linux/amd64 ghcr.io/gh-org-template/kong-build-images:rpm-1.1.1 as x86_64-linux-gnu
RUN echo 'noop'

FROM --platform=linux/arm64 ghcr.io/gh-org-template/kong-build-images:apk-1.1.1 as aarch64-linux-musl
RUN echo 'noop'

FROM --platform=linux/arm64 ghcr.io/gh-org-template/kong-build-images:rpm-1.1.1 as aarch64-linux-gnu
RUN echo 'noop'

# Run the build script
FROM $ARCHITECTURE-$OSTYPE as build

COPY . /src
RUN /src/build.sh && /src/test.sh

# Test scripts left where downstream images can run them
COPY test.sh /test/kong-openssl/test.sh
COPY .env /test/kong-openssl/.env


# Copy the build result to scratch so we can export the result
FROM scratch as package

COPY --from=build /tmp/build /
