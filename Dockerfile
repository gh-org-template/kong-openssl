ARG OSTYPE=linux-gnu
ARG ARCHITECTURE=x86_64
ARG DOCKER_REGISTRY=ghcr.io
ARG DOCKER_IMAGE_NAME
ARG DOCKER_ARCHITECTURE
ARG OPERATING_SYSTEM

FROM --platform=linux/${DOCKER_ARCHITECTURE} ghcr.io/gh-org-template/kong-build-images:${OPERATING_SYSTEM}-1.1.1 as build

COPY . /src
RUN /src/build.sh && /src/test.sh

# Test scripts left where downstream images can run them
COPY test.sh /test/kong-openssl/test.sh
COPY .env /test/kong-openssl/.env


# Copy the build result to scratch so we can export the result
FROM scratch as package

COPY --from=build /tmp/build /
