SHELL = /bin/bash

INSTALL_DIRECTORY = .venv
PIP_CMD = ${INSTALL_DIRECTORY}/bin/pip
PYTHON_CMD = ${INSTALL_DIRECTORY}/bin/python
FLASK_CMD := ${INSTALL_DIRECTORY}/bin/flask
MAKO_CMD := ${INSTALL_DIRECTORY}/bin/mako-render
SERVER_PORT ?= 9000
FLASK_APP = vib/main.py
FLASK_DEBUG ?= 1

# Deploy variables
USER_NAME ?= $(shell id -un)
CLONEDIR = /home/$(USER_NAME)/tmp/branches/${BRANCH_NAME}
BRANCH_NAME ?=
DEEP_CLEAN ?= "false"

.PHONY: help
help:
	@echo "Usage make <target>"
	@echo
	@echo "Possible targets:"
	@echo "- all           Install .venv and py deps in main project"
	@echo "- serve         Serve local examples using localhost"
	@echo "- deploybranch  Deploys a branch to S3"
	@echo "- clean         Remove all generated templates"
	@echo "- cleanall      Remove all untracked content"


.PHONY: all
all: ${INSTALL_DIRECTORY}/devlibs zappa_settings.json

requirements.txt:
${INSTALL_DIRECTORY}/devlibs: requirements.txt
	@if [ ! -d $(INSTALL_DIRECTORY) ]; then virtualenv $(INSTALL_DIRECTORY); fi
	$(PIP_CMD) install --upgrade pip setuptools;
	$(PIP_CMD) install -r requirements.txt;
	touch $@;

.PHONY: serve
serve:
	export FLASK_APP=$(FLASK_APP) && export FLASK_DEBUG=$(FLASK_DEBUG) && ${FLASK_CMD} run --port=$(SERVER_PORT);

clonebuild:
	$(eval BRANCH_NAME=$(shell git rev-parse --symbolic-full-name --abbrev-ref HEAD))
	./scripts/clonebuild.sh ${CLONEDIR} ${BRANCH_NAME} ${DEEP_CLEAN};

upload:
	$(eval BRANCH_NAME=$(shell git rev-parse --symbolic-full-name --abbrev-ref HEAD))
	${PYTHON_CMD} scripts/upload.py ${CLONEDIR} ${BRANCH_NAME};

zappa_settings.json: zappa_settings.json.in
	envsubst < zappa_settings.json.in > zappa_settings.json

.PHONY: deploybranch
deploybranch: clonebuild upload

.PHONY: clean
clean:
	rm -f  ${INSTALL_DIRECTORY}/devlibs
	rm -f zappa_settings.json

.PHONY: cleanall
cleanall: clean
	rm -rf .venv
