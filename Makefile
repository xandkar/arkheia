EXECUTABLE_NAME="mldb"

COMPILER="ocamlopt"
OBJ_EXT="cmx"
LIBS="batteries,zip"


all: compile link


compile:
	@          $(COMPILER)                  -I src -c src/RegExp.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src -c src/RegExp.ml
	@          $(COMPILER)                  -I src -c src/Utils.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src -c src/Utils.ml
	@          $(COMPILER)                  -I src -c src/GZ.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src -c src/GZ.ml
	@          $(COMPILER)                  -I src -c src/Msg.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src -c src/Msg.ml
	@          $(COMPILER)                  -I src -c src/Mbox.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src -c src/Mbox.ml
	@          $(COMPILER)                  -I src -c src/Index.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src -c src/Index.ml
	@          $(COMPILER)                  -I src -c src/Main.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src -c src/Main.ml


link:
	@mkdir -p bin
	@ocamlfind $(COMPILER) -thread -linkpkg -package $(LIBS) \
		-o bin/$(EXECUTABLE_NAME) \
		src/RegExp.$(OBJ_EXT) \
		src/Utils.$(OBJ_EXT) \
		src/GZ.$(OBJ_EXT) \
		src/Msg.$(OBJ_EXT) \
		src/Mbox.$(OBJ_EXT) \
		src/Index.$(OBJ_EXT) \
		src/Main.$(OBJ_EXT)


clean:
	@rm -rf bin/$(EXECUTABLE_NAME)
	@find src \
		    -iname '*.o' \
		-or -iname '*.cmi' \
		-or -iname "*.$(OBJ_EXT)" \
		| xargs rm
