RELEASE_VERSION=$(shell cat version)
ifeq ($(SNAPSHOT),1)
  $(info **************************** Building with SNAPSHOT MODE *********************************)
  RELEASE_VERSION=`cat version`"-SNAPSHOT"
endif

RELEASE_FILE_NAME=pi-deploy-tools
RELEASE_MODULE_NAME=pi-deploy-tools

RELEASE_FILENAME=$(RELEASE_FILE_NAME)-$(RELEASE_VERSION).tar.gz
package: clean
	@echo "**** packaging $(RELEASE_FILE_NAME) version : [$(RELEASE_VERSION)] ****"
	mkdir dist
	cp -r bin dist
	cp version dist
	cp install.sh dist
	cp  README.md dist
	( cd dist && find . -type f | xargs tar cvfz $(RELEASE_FILENAME) )

publish: package
	if [ -f version ]; then pi-build-tools publish $(RELEASE_MODULE_NAME) $(RELEASE_VERSION) $(RELEASE_FILENAME) dist; else echo "version file is required"; exit 1; fi

clean:
	if [ -d dist ]; then rm -rf dist ; fi

