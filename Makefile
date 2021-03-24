# The list of AWS hostname targets.

# The list of web websites we can build
prefix := tech
website := $(prefix).vertalo.com

# Subdirectories of content/
subdirs := $(sort $(notdir $(shell find content -mindepth 1 -maxdepth 1 -type d)))

####

help:
	@echo ""
	@echo "Targets:"
	@echo ""
	@echo "help: print this message"
	@echo "  Use the AWS_PROFILE env var to set profile for any target"
	@echo ""
	@echo "setup: install hugo"
	@echo ""
	@echo "local: serve content on localhost:1313"
	@echo ""
	@echo "weblocal: serve content on localhost:1313, a la production (no drafts)"
	@echo ""
	@echo "website: build content for the deployed site"
	@echo ""
	@echo "deploy: deploy content for the site to AWS"
	@echo ""
	@echo "new.SUBDIR.%: create a new SUBDIR entry draft with name \$$*.md"
	@echo "  SUBDIR is in {$(subdirs)}"
	@echo ""
	@echo ""
	@echo ""

# Assume dpkg for linux-64
setup:
	wget https://github.com/gohugoio/hugo/releases/download/v0.81.0/hugo_0.81.0_Linux-64bit.deb
	sudo dpkg --install hugo_0.81.0_Linux-64bit.deb
	rm hugo_0.81.0_Linux-64bit.deb

local:
	hugo server -D --cleanDestinationDir --ignoreCache --noHTTPCache

weblocal:
	hugo server --cleanDestinationDir --ignoreCache --noHTTPCache

website:
	hugo
	rm -fr public/partials
	touch public

deploy: clean website
	aws s3 sync --delete --exclude '.DS_Store' --exclude '*/.DS_Store' --cache-control 60 './public' 's3://website.vertalo.com/$(prefix)/'

define HUGO_NEW = 
new.$(1).%:
	hugo new '$(1)/$$*.md'
endef

$(foreach s,$(subdirs),$(eval $(call HUGO_NEW,$(s))))

clean:
	rm -fr ./public

.PHONY: help setup local website deploy clean


