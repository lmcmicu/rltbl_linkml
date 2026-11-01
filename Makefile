MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.DEFAULT_GOAL := example_target
.DELETE_ON_ERROR:
.SUFFIXES:

.PHONY: clean example_target rltbl_load test_linkml2valve test_linkml_validation \
	test_linkml_json_validation

example_target:
	python3 -m valve_linkml.linkml2valve "test/linkml_input/personinfo/personinfo.yaml" \
		-o test/valve_output

rltbl_load: test/valve_output/personinfo/data/Person.tsv
	cp -f $< /tmp/$$(basename $<)
	RLTBL_CONNECTION=test/valve_output/personinfo/personinfo.db ./rltbl --verbose \
		init --force
	RLTBL_CONNECTION=test/valve_output/personinfo/personinfo.db ./rltbl --verbose \
		load table /tmp/$$(basename $<) --force
	rm -f /tmp/$$(basename $<)

test_linkml_validation: test/valve_output/personinfo/data/Person.tsv
	linkml-validate --schema test/linkml_input/personinfo/personinfo.yaml \
		--target-class Person $<

test_linkml_json_validation: test/valve_output/personinfo/data/Person.json
	linkml-validate --schema test/linkml_input/personinfo/personinfo.yaml --target-class Person $<

test/valve_output/personinfo/data/Person.json: test/valve_output/personinfo/data/Person.tsv
	linkml-convert --schema test/linkml_input/personinfo/personinfo.yaml \
		--target-class Person --index-slot id -o $@ \
		$<

test_linkml2valve:
	python3 -m test.test_linkml2valve

clean:
	git checkout test
	rm -f test/valve_output/*.tsv
	rm -f test/valve_output/personinfo/data/Person.json
	rm -f test/valve_output/personinfo/data/Person_no_id.tsv
	rm -Rf test/valve_output/data
