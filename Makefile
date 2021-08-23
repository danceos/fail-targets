FAIL_DOWNLOAD_BASE="https://collaborating.tuhh.de/e-exk4/projects/fail/-/jobs/artifacts/feature/sail/download"

ARCH ?= bochs

all: help

BUILD_DIR    := build-${ARCH}
FAIL_BIN     ?= ${BUILD_DIR}/bin
FAIL_SERVER  ?= ${FAIL_BIN}/generic-experiment-server
FAIL_TRACE   ?= ${FAIL_BIN}/fail-generic-tracing
FAIL_INJECT  ?= ${FAIL_BIN}/fail-generic-experiment
FAIL_IMPORT  ?= ${FAIL_BIN}/import-trace --enable-sanitychecks 
FAIL_PRUNE   ?= ${FAIL_BIN}/prune-trace
BOCHS_RUNNER ?= ${FAIL_BIN}/bochs-experiment-runner

EXPERIMENTS  := $(patsubst %.c,%,$(shell echo *.c))

CFLAGS += -I. -include arch/${ARCH}/lib.c -O2 -std=c11

include arch/${ARCH}.mk

$(foreach element,$(EXPERIMENTS),$(eval $(call arch-make-targets,$(element))))

help:
	@echo "Small Playground for FAIL* Injections"
	@echo "-------------------------------------"
	@echo "Architecture Unspecific Targets:"
	@echo "	\e[3mdocker\e[0m        Start a Docker container with all dependencies"
	@echo "	\e[3mdownload\e[0m      Download Precompiled FAIL* client"
	@echo ""
	@echo "Current Configuartion"
	@echo "	ARCH=${ARCH}"

docker:
	@echo Starting Docker
	docker-compose up -d
	@make shell

shell:
	docker-compose exec -e debian_chroot=${ARCH} -e ARCH=${ARCH} shell bash

################################################################
# Download
download: ${BUILD_DIR}/bin/fail-client

${BUILD_DIR}/bin/fail-client:
	mkdir -p ${BUILD_DIR}/bin
	wget ${FAIL_DOWNLOAD_URL} -O ${BUILD_DIR}/bin/fail.zip
	cd ${BUILD_DIR}/bin/ && unzip fail.zip && mv build/bin/* . && rm -rf build


clean:
	rm -rf ${BUILD_DIR}

clean-%:
	rm -rf ${BUILD_DIR}/$(patsubst clean-%,%,$@)
	contrib/clean-db '${ARCH}/$(patsubst clean-%,%,$@)'


build-%:
	@echo "****************************************************************\n\
* The next step is to trace a golden run. The golden run executes the\n\
* system-under-test (SUT) within the emulator. A trace file is \n\
* produced and saved as: ${BUILD_DIR}/main/trace.pb\n\
*\n\
*    $ make trace-$(patsubst build-%,%,$@)\n\
****************************************************************"


trace-%:
	@echo "****************************************************************\n\
* The trace is now generated. It can be viewed with\n\
*\n\
*   $ make dump-$(patsubst trace-%,%,$@)\n\
*\n\
* Next, we have to import the trace into the database\n\
*\n\
*    $ make import-$(patsubst trace-%,%,$@)\n\
****************************************************************"

dump-%: ${BUILD_DIR}/%/trace.pb
	${BUILD_DIR}/bin/dump-trace $(shell dirname $<)/trace.pb

${HOME}/.my.cnf:
	@echo "[client]" > $@
	@echo "user=fail" >> $@
	@echo "database=fail" >> $@
	@echo "password=fail" >> $@
	@echo "host=db" >> $@
	@echo "port=3306" >> $@

import-%: import-arch-%
	@echo "****************************************************************\n\
* The golden run sits now within the MySQL database. If you are interested,\n\
* use the 'mysql' command to inspect the curent state of the DB. The tables\n\
* trace, fsppilot, and fspgroup are of special interest.\n\
*\n\
* Next, we have to run the campaign sever and the injection client\n\
*\n\
*   $ make server-$(patsubst import-%,%,$@) &\n\
*   $ make client-$(patsubst import-%,%,$@) \n\n\
* Afterwards, the results can be viewd with\n\
*   $ make result-$(subst import-,,$@)\n\
****************************************************************"

server-%:
	${FAIL_SERVER} -v ${ARCH}/$(subst server-,,$@) -b %

result-%:
	@echo "select variant, benchmark, resulttype, sum(t.time2 - t.time1 + 1) as faults\
			FROM variant v \
			JOIN trace t ON v.id = t.variant_id \
			JOIN fspgroup g ON g.variant_id = t.variant_id AND g.instr2 = t.instr2 AND g.data_address = t.data_address\
			JOIN result_GenericExperimentMessage r ON r.pilot_id = g.pilot_id  \
			JOIN fsppilot p ON r.pilot_id = p.id \
			WHERE v.variant = \"${ARCH}/$(patsubst result-%,%,$@)\"\
			GROUP BY v.id, resulttype \
			ORDER BY variant, benchmark, resulttype;"  |mysql -t


# Do never remove implicitly generated stuff
.SECONDARY:
