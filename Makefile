# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PKG = github.com/csi-driver/goofys-csi-driver
GIT_COMMIT ?= $(shell git rev-parse HEAD)
REGISTRY ?= andyzhangx
IMAGE_NAME = goofys-csi
IMAGE_VERSION ?= v0.1.0
# Use a custom version for E2E tests if we are in Prow
ifdef AZURE_CREDENTIALS
override IMAGE_VERSION := e2e-$(GIT_COMMIT)
endif
IMAGE_TAG = $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_VERSION)
IMAGE_TAG_LATEST = $(REGISTRY_NAME)/$(IMAGE_NAME):latest
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS ?= "-X ${PKG}/pkg/goofys.driverVersion=${IMAGE_VERSION} -X ${PKG}/pkg/goofys.gitCommit=${GIT_COMMIT} -X ${PKG}/pkg/goofys.buildDate=${BUILD_DATE} -s -w -extldflags '-static'"
GINKGO_FLAGS = -ginkgo.noColor -ginkgo.v
GO111MODULE = off
export GO111MODULE

all: goofys

.PHONY: verify
verify:
	hack/verify-all.sh

.PHONY: unit-test
unit-test:
	go test -covermode=count -coverprofile=profile.cov ./pkg/... ./test/utils/credentials

.PHONY: sanity-test
sanity-test: goofys
	go test -v -timeout=30m ./test/sanity

.PHONY: integration-test
integration-test: goofys
	go test -v -timeout=30m ./test/integration

.PHONY: e2e-test
e2e-test:
	go test -v -timeout=0 ./test/e2e ${GINKGO_FLAGS}

.PHONY: e2e-bootstrap
e2e-bootstrap: install-helm
	# Only build and push the image if it does not exist in the registry
	docker pull $(IMAGE_TAG) || make goofys-container push
	helm install charts/latest/goofys-csi-driver -n goofys-csi-driver --namespace kube-system --wait \
		--set image.goofys.pullPolicy=IfNotPresent \
		--set image.goofys.repository=$(REGISTRY)/$(IMAGE_NAME) \
		--set image.goofys.tag=$(IMAGE_VERSION)

.PHONY: install-helm
install-helm:
	# Use v2.11.0 helm to match tiller's version in clusters made by aks-engine
	curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | DESIRED_VERSION=v2.11.0 bash
	# Make sure tiller is ready
	kubectl wait pod -l name=tiller --namespace kube-system --for condition=ready --timeout 5m
	helm version

.PHONY: e2e-teardown
e2e-teardown:
	helm delete --purge goofys-csi-driver

.PHONY: goofys
goofys:
	if [ ! -d ./vendor ]; then dep ensure -vendor-only; fi
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags ${LDFLAGS} -o _output/goofysplugin ./pkg/goofysplugin

.PHONY: goofys-windows
goofys-windows:
	if [ ! -d ./vendor ]; then dep ensure -vendor-only; fi
	CGO_ENABLED=0 GOOS=windows go build -a -ldflags ${LDFLAGS} -o _output/goofysplugin.exe ./pkg/goofysplugin

.PHONY: goofys-container
goofys-container: goofys
	docker build --no-cache -t $(IMAGE_TAG) -f ./pkg/goofysplugin/Dockerfile .

.PHONY: push
push: goofys-container
	docker push $(IMAGE_TAG)

.PHONY: push-latest
push-latest: goofys-container
	docker push $(IMAGE_TAG)
	docker tag $(IMAGE_TAG) $(IMAGE_TAG_LATEST)
	docker push $(IMAGE_TAG_LATEST)

.PHONY: clean
clean:
	go clean -r -x
	-rm -rf _output
