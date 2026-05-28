PROJECTNAME := $(shell git remote get-url origin 2>/dev/null | \
    sed -E 's|.*/([^/]+)(\.git)?$$|\1|' || basename "$$(pwd)")
PROJECTORG  := $(shell git remote get-url origin 2>/dev/null | \
    sed -E 's|.*/([^/]+)/[^/]+(\.git)?$$|\1|' || \
    basename "$$(dirname "$$(pwd)")")

VERSION     ?= $(shell cat release.txt 2>/dev/null || echo "0.1.0")
COMMIT_ID   := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

REGISTRY    := ghcr.io/$(PROJECTORG)/$(PROJECTNAME)
BUILD_IMAGE ?= $(REGISTRY):build
HOST_ARCH   := $(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')

.PHONY: help build docker test clean

help: ## Show this help message
	@printf '\n\033[1;37m  %s v%s\033[0m\n\n' "$(PROJECTNAME)" "$(VERSION)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@printf '\n'

test: build ## Alias for build

build: ## Build the build environment image then compile ices0 for the host architecture (output: binaries/)
	docker build -f docker/Dockerfile.build -t $(BUILD_IMAGE) .
	@mkdir -p binaries
	docker run --rm -it \
		--name $(PROJECTNAME)-$$(tr -dc 'a-z0-9' </dev/urandom | head -c8) \
		-v "$(PWD)/binaries:/output" \
		$(BUILD_IMAGE) \
		build-ices0 $(HOST_ARCH)
	@echo ""
	@ls -lh binaries/ices0-linux-$(HOST_ARCH)

docker: ## Build the runtime image locally for testing (single-arch, --load)
	@cp binaries/ices0-linux-$(HOST_ARCH) ices0-linux-$(HOST_ARCH)
	docker buildx build \
		--platform linux/$(HOST_ARCH) \
		--build-arg TARGETARCH=$(HOST_ARCH) \
		-t $(REGISTRY):dev \
		--load \
		.
	@rm -f ices0-linux-$(HOST_ARCH)

clean: ## Remove build artifacts (binaries/)
	@rm -rf binaries/
