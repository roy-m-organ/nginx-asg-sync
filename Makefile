GO_DOCKER_RUN = docker run --rm -v $(shell pwd):/go/src/github.com/nginxinc/nginx-asg-sync -v $(shell pwd)/build_output:/build_output -w /go/src/github.com/nginxinc/nginx-asg-sync/cmd/sync
GOFLAGS ?= -mod=vendor
TARGET ?= local

export DOCKER_BUILDKIT = 1

all: amazon amazon2 centos7 centos8 debian

.PHONY: test
test:
	GO111MODULE=on GOFLAGS='$(GOFLAGS)' go test ./...

lint:
	golangci-lint run

.PHONY: build
build:
ifeq (${TARGET},local)
	CGO_ENABLED=0 GO111MODULE=on GOFLAGS='$(GOFLAGS)' GOOS=linux go build -installsuffix cgo -o nginx-asg-sync github.com/nginxinc/nginx-asg-sync/cmd/sync
endif

amazon: build
	docker build -t amazon-builder --target ${TARGET} --build-arg CONTAINER_VERSION=amazonlinux:1 --build-arg OS_TYPE=rpm_based -f build/Dockerfile .
	docker run --rm -v $(shell pwd)/build/package/rpm:/rpm -v $(shell pwd)/build_output:/build_output amazon-builder

amazon2: build
	docker build -t amazon2-builder --target ${TARGET} --build-arg CONTAINER_VERSION=amazonlinux:2 --build-arg OS_TYPE=rpm_based -f build/Dockerfile .
	docker run --rm -v $(shell pwd)/build/package/rpm:/rpm -v $(shell pwd)/build_output:/build_output amazon2-builder

centos7: build
	docker build -t centos7-builder --target ${TARGET} --build-arg CONTAINER_VERSION=centos:7 --build-arg OS_TYPE=rpm_based -f build/Dockerfile .
	docker run --rm -v $(shell pwd)/build/package/rpm:/rpm -v $(shell pwd)/build_output:/build_output centos7-builder

centos8: build
	docker build -t centos8-builder --target ${TARGET} --build-arg CONTAINER_VERSION=centos:8 --build-arg OS_TYPE=rpm_based -f build/Dockerfile .
	docker run --rm -v $(shell pwd)/build/package/rpm:/rpm -v $(shell pwd)/build_output:/build_output centos8-builder

debian: build
	docker build -t debian-builder --target ${TARGET} --build-arg OS_TYPE=deb_based -f build/Dockerfile .
	docker run --rm -v $(shell pwd)/build/package/debian:/debian -v $(shell pwd)/build_output:/build_output debian-builder

.PHONY: clean
clean:
	-rm -r build_output

.PHONY: deps
deps:
	@go mod tidy && go mod verify && go mod vendor

.PHONY: clean-cache
clean-cache:
	@go clean -modcache
