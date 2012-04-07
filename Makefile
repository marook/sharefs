PREFIX=/usr/local

all:

$(PREFIX)/bin/sharefs: sharefs.sh
	install "$^" "$@"

install: $(PREFIX)/bin/sharefs
