LIBS="batteries,calendar,camlzip"
EXECUTABLE_NAME="arkheia"
EXECUTABLE_TYPE="native"


build:
	@ocamlbuild -tag thread -use-ocamlfind -package $(LIBS) -I src/lib \
        src/app/$(EXECUTABLE_NAME)_main.$(EXECUTABLE_TYPE)
	@mkdir -p bin
	@mv $(EXECUTABLE_NAME)_main.$(EXECUTABLE_TYPE) bin/$(EXECUTABLE_NAME)


clean:
	@rm -rf bin/
	@ocamlbuild -clean


purge:
	@rm -rf bin/
	@find . \
            -iname '*.o' \
        -or -iname '*.cmi' \
        -or -iname "*.cmx" \
        | xargs rm -f
