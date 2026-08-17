#===============================================================================
# Makefile — AXI VIP simulation with Cadence Xcelium
#===============================================================================

TEST      ?= axi_fixed_rw_test
SEED      ?= 1
VERBOSITY ?= UVM_MEDIUM
COV       ?= 0

XRUN_OPTS = -uvm \
            -sv \
            -timescale 1ns/1ps \
            -access +rwc \
            -f xrun.f \
            +UVM_TESTNAME=$(TEST) \
            +UVM_VERBOSITY=$(VERBOSITY) \
            -svseed $(SEED) \
            -assertion_summary \
            +assertCover \
            +assertStatus \
            -assert_report 

ifeq ($(COV), 1)
    XRUN_OPTS += -coverage all \
                 -covfile ccf/axi_coverage.ccf \
                 -covoverwrite \
                 -covtest $(TEST)_seed$(SEED)
endif

all: compile run

compile:
	xrun $(XRUN_OPTS) -elaborate

run:
	xrun $(XRUN_OPTS)

cov_report:
	imc -exec ../scripts/cov_report.tcl -nostdout

clean:
	rm -rf xcelium.d INCA_libs cov_work *.log *.history waves.shm

# Regression 一次跑多個 test
REG_TESTS = axi_sanity_test axi_random_test axi_reg_test axi_concurrent_rw_test

regress:
	@for t in $(REG_TESTS); do \
	    echo "=== Running $$t ==="; \
	    $(MAKE) run TEST=$$t SEED=$$RANDOM COV=1 || exit 1; \
	done

.PHONY: all compile run cov_report clean regress
