ARCHITECTURE ?= x86_64
OSTYPE ?= linux-gnu
DOCKER_TARGET ?= build
DOCKER_REGISTRY ?= ghcr.io
DOCKER_IMAGE_NAME ?= kong-openssl
DOCKER_IMAGE_TAG ?= $(DOCKER_TARGET)-$(ARCHITECTURE)-$(OSTYPE)
DOCKER_NAME ?= $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
DOCKER_RESULT ?= --load

ifeq ($(ARCHITECTURE),aarch64)
	DOCKER_ARCHITECTURE=arm64
else
	DOCKER_ARCHITECTURE=amd64
endif

ifeq ($(OSTYPE),linux-gnu)
	OPERATING_SYSTEM=rpm
else
	OPERATING_SYSTEM=apk
endif

clean:
	rm -rf package
	docker rmi $(DOCKER_NAME)

docker:
	docker buildx build \
		--build-arg DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
		--build-arg DOCKER_IMAGE_NAME=$(DOCKER_IMAGE_NAME) \
		--build-arg DOCKER_IMAGE_TAG=$(DOCKER_IMAGE_TAG) \
		--build-arg ARCHITECTURE=$(ARCHITECTURE) \
		--build-arg OSTYPE=$(OSTYPE) \
		--build-arg DOCKER_ARCHITECTURE=$(DOCKER_ARCHITECTURE) \
		--build-arg OPERATING_SYSTEM=$(OPERATING_SYSTEM) \
		--target=$(DOCKER_TARGET) \
		-t $(DOCKER_NAME) \
		$(DOCKER_RESULT) .

build/docker:
	docker inspect --format='{{.Config.Image}}' $(DOCKER_NAME) || \
	$(MAKE) DOCKER_TARGET=build docker

build/package: build/docker
	$(MAKE) DOCKER_TARGET=package DOCKER_RESULT="-o package" docker

.PHONY: init
init:
	pre-commit install

.PHONY: run-pre-commit
run-pre-commit:
	pre-commit run --all-files
