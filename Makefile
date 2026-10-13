PREFIX ?= $(HOME)/.local
IMAGE ?= pi-sandbox

.PHONY: install build

build:
	docker build --no-cache -t $(IMAGE) .

install:
	mkdir -p $(PREFIX)/bin
	ln -sf $(CURDIR)/pi-sbx.sh $(PREFIX)/bin/pi-sbx
