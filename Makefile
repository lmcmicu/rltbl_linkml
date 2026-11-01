MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.DEFAULT_GOAL := example_target
.DELETE_ON_ERROR:
.SUFFIXES:

.PHONY: clean example_target rltbl_load linkml2valve test_linkml_conversion \
	test_linkml_json_validation

example_target:
	python3 -m valve_linkml.linkml2valve "test/linkml_input/personinfo/personinfo.yaml" \
		-o test/valve_output

test/valve_output/personinfo/data/Person_no_id.tsv: test/valve_output/personinfo/data/Person.tsv
	cut --complement -f 1 $< > $@

rltbl_load: test/valve_output/personinfo/data/Person_no_id.tsv
	cp -f $< /tmp/$(subst _no_id,,$$(basename $<))
	RLTBL_CONNECTION=test/valve_output/personinfo/personinfo.db ./rltbl --verbose \
		init --force
	RLTBL_CONNECTION=test/valve_output/personinfo/personinfo.db ./rltbl --verbose \
		load table /tmp/$(subst _no_id,,$$(basename $<)) --force
	rm -f /tmp/$(subst _no_id,,$$(basename $<))

test_linkml2valve:
	python3 -m test.test_linkml2valve

test_linkml_conversion: test/valve_output/personinfo/data/Person.tsv
	linkml-convert --schema test/linkml_input/personinfo/personinfo.yaml \
		--target-class Person \
		--index-slot id \
		-o test/valve_output/personinfo/data/Person.json \
		$<

test_linkml_json_validation: test/valve_output/personinfo/data/Person.json
	linkml-validate --schema test/linkml_input/personinfo/personinfo.yaml --target-class Person $<

######################################
# TODO: Not working - Likely you need to fix linkml2valve so that it ignores the id
# field when generating Person.json.
test_linkml_validation: test/valve_output/personinfo/data/Person_no_id.tsv
	linkml-validate --schema test/linkml_input/personinfo/personinfo_no_id.yaml \
		--target-class Person \
		$<

######################################

clean:
	git checkout test
	rm -f test/valve_output/*.tsv
	rm -f test/valve_output/personinfo/data/Person.json
	rm -f test/valve_output/personinfo/data/Person_no_id.tsv
	rm -Rf test/valve_output/data
