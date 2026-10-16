PREFIX ?= $(HOME)/.local
IMAGE ?= pi-sandbox

.PHONY: install build uninstall

build:
	docker build --no-cache -t $(IMAGE) .

uninstall:
	rm -f $(PREFIX)/bin/pi-sbx

install:
	mkdir -p $(PREFIX)/bin
	ln -sf $(CURDIR)/pi-sbx.sh $(PREFIX)/bin/pi-sbx
