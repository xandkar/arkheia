EXT_LIBS="calendar,zip,cryptokit"

DIR_BIN="bin"
DIR_BUILD="_build"
DIR_SRC_LIB="src/lib"
DIR_SRC_APP="src/app"

EXECUTABLE_NAME="arkheia"
EXECUTABLE_TYPE="native"
EXECUTABLE_LINK="$(EXECUTABLE_NAME)_main.$(EXECUTABLE_TYPE)"
EXECUTABLE_TARGET="$(DIR_SRC_APP)/$(EXECUTABLE_LINK)"
EXECUTABLE_FILE="$(DIR_BUILD)/$(EXECUTABLE_TARGET)"


build:
	@ocamlbuild -tag thread -use-ocamlfind -package $(EXT_LIBS) \
	    -I $(DIR_SRC_LIB) $(EXECUTABLE_TARGET)
	@mkdir -p $(DIR_BIN)
	@cp -f $(EXECUTABLE_FILE) $(DIR_BIN)/$(EXECUTABLE_NAME)
	@rm -f $(EXECUTABLE_LINK)


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
