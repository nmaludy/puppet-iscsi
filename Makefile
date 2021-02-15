ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PUPPET_VERSION ?= "~> 7.0"
HAS_SUDO := $(shell command -v sudo 2> /dev/null)
ifndef HAS_SUDO
	SUDO_CMD =
else
	SUDO_CMD = sudo
endif

# common target to setup both system dependencies along with testing (gem) dependencies
.PHONY: setup
setup: setup-system setup-test

.PHONY: setup-system
setup-system: .setup-system

.PHONY: setup-test
setup-test: .setup-test

.PHONY: modules
modules: .modules

.PHONY: test
test: .test-lint .test-spec

.PHONY: test-lint
test-lint: .test-lint

.PHONY: test-spec
test-spec: .test-spec

.PHONY: clean
clean: .clean

# system-setup is separated out because that is baked into docker, avoiding expensive yum calls
.PHONY: .setup-system
.setup-system:
	@echo
	@echo "==================== setup-system ===================="
	@echo
	$(SUDO_CMD) yum -y localinstall "https://yum.puppet.com/puppet-tools-release-el-8.noarch.rpm"
	$(SUDO_CMD) yum -y localinstall "https://yum.puppet.com/puppet7-release-el-8.noarch.rpm"
	$(SUDO_CMD) yum -y install puppet-agent puppet-bolt git pdk gcc

# we want to install bundler gems every time to avoid issues upstream with gem releases
# this is done during CI
.PHONY: .setup-test
.setup-test:
	@echo
	@echo "==================== setup-test ===================="
	@echo
# install Gemfile gems needed for testing with Bundler inside of PDK
	pdk bundle install

.PHONY: .modules
.modules:
	@echo
	@echo "==================== modules ===================="
	@echo
	pdk bundle exec r10k puppetfile install --moduledir=$(ROOT_DIR)/modules

.PHONY: .test-lint
.test-lint:
	@echo
	@echo "==================== test-lint ===================="
	@echo
	pdk bundle exec rake "syntax" "lint" "metadata_lint" "check:symlinks" "check:git_ignore" "check:dot_underscore" "check:test_file" "rubocop" "check"

.PHONY: .test-spec
.test-spec:
	@echo
	@echo "==================== test-spec ===================="
	@echo
	pdk bundle exec rake parallel_spec

.PHONY: .clean
.clean:
	@echo
	@echo "==================== clean ===================="
	@echo
	rm -rf $(ROOT_DIR)/.bundle
	rm -rf $(ROOT_DIR)/.resource_types
	rm -rf $(ROOT_DIR)/modules
	rm -rf $(ROOT_DIR)/vendor
	rm -f $(ROOT_DIR)/bolt-debug.log
	rm -f $(ROOT_DIR)/Gemfile.lock
	find "$(ROOT_DIR)" -type d -name '.kitchen' | xargs -r -t -n1 rm -rf
	find "$(ROOT_DIR)" -type d -name '.librarian' -or -type d -name '.tmp' | xargs -r -t -n1 rm -rf
	rm -rf $(ROOT_DIR)/build/kitchen/.bundle
	rm -rf $(ROOT_DIR)/build/kitchen/vendor
	rm -rf $(ROOT_DIR)/spec/fixtures/modules
