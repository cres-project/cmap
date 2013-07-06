cmd_perl	?= $(shell which perl)
cmd_rm		?= $(shell which rm)
cmd_find	?= $(shell which find)
cmd_grep	?= $(shell which grep)
cmd_sort	?= $(shell which sort)
cmd_uniq	?= $(shell which uniq)
cmd_tar		?= $(shell which tar)

file_modules	= /tmp/qthlog2tsv_modules.pl

#
all:
	@echo "== MAKEFILE FOR QT-HONEY LOG CONVERTER SETUP =="
	@echo "- target:"
	@echo " check     : check perl modules"

check:
	@echo "* checking perl modules ..."
	$(cmd_find) . -type f -name "*.p[m|l]" -exec $(cmd_grep) -e "^use [A-Z]" \{\} \; | $(cmd_sort) | $(cmd_uniq) > $(file_modules)
	$(cmd_perl) $(file_modules)

	@echo "* done"

clean:
	$(cmd_find) . -name "*~" -exec $(cmd_rm) \{\} \;

dist: clean
	$(cmd_tar) cf `date +qthlog2tsv.%y%m%d.tar` .
