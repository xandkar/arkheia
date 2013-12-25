DIR_BIN="bin"
DIR_BUILD="_build"
DIR_SRC="src"

build_old:
	@ocamlbuild \
		-tag thread \
		-use-ocamlfind \
		-package calendar,zip \
		-I $(DIR_SRC)/old \
		arkheia_main.native
	@mkdir -p $(DIR_BIN)
	@cp -f $(DIR_BUILD)/$(DIR_SRC)/old/arkheia_main.native $(DIR_BIN)/arkheia_old
	@rm -f arkheia_main.native

clean:
	@rm -rf $(DIR_BIN)
	@ocamlbuild -clean

purge:
	@rm -rf $(DIR_BIN)
	@rm -rf $(DIR_BUILD)
	@find . \
            -iname '*.o' \
        -or -iname '*.cmi' \
        -or -iname '*.cmx' \
        | xargs rm -f
