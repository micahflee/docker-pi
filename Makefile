PREFIX ?= $(HOME)/.local

.PHONY: install

install:
	mkdir -p $(PREFIX)/bin
	ln -sf $(CURDIR)/pi-sbx.sh $(PREFIX)/bin/pi-sbx
