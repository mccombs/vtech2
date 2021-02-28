# The list of AWS hostname targets.

# The list of web websites we can build
prefix := tech
website := $(prefix).vertalo.com

####

help:
	@echo ""
	@echo "Targets:"
	@echo ""
	@echo "help: print this message"
	@echo ""
	@echo "setup: install hugo"
	@echo ""
	@echo "local: serve content on localhost:1313"
	@echo ""
	@echo "website: build content for the deployed site"
	@echo ""
	@echo "deploy: deploy content for the site to AWS"
	@echo ""

# Assume dpkg for linux-64
setup:
	wget https://github.com/gohugoio/hugo/releases/download/v0.81.0/hugo_0.81.0_Linux-64bit.deb
	sudo dpkg --install hugo_0.81.0_Linux-64bit.deb
	rm hugo_0.81.0_Linux-64bit.deb

local:
	hugo server -D --cleanDestinationDir --ignoreCache --noHTTPCache

website:
	hugo
	touch public

deploy: clean website
	aws s3 sync --delete --exclude '.DS_Store' --exclude '*/.DS_Store' --cache-control 60 './public' 's3://website.vertalo.com/$(prefix)/'

clean:
	rm -fr ./public

.PHONY: help setup local website deploy clean


