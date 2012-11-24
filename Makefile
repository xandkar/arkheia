EXECUTABLE="mldb"

COMPILER="ocamlopt"
OBJ_EXT="cmx"
LIBS="batteries,zip"


all: clean compile link


compile: compile_lib compile_app


compile_lib:
	@          $(COMPILER)                  -I src/lib -c src/lib/RegExp.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/RegExp.ml
	@          $(COMPILER)                  -I src/lib -c src/lib/Utils.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/Utils.ml
	@          $(COMPILER)                  -I src/lib -c src/lib/GZ.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/GZ.ml
	@          $(COMPILER)                  -I src/lib -c src/lib/Msg.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/Msg.ml
	@          $(COMPILER)                  -I src/lib -c src/lib/Mbox.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/Mbox.ml
	@          $(COMPILER)                  -I src/lib -c src/lib/Index.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/Index.ml


compile_app:
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/app/$(EXECUTABLE).ml


link:
	@mkdir -p bin
	@ocamlfind $(COMPILER) -thread -linkpkg -package $(LIBS) \
		-o bin/$(EXECUTABLE) \
		src/lib/RegExp.$(OBJ_EXT) \
		src/lib/Utils.$(OBJ_EXT) \
		src/lib/GZ.$(OBJ_EXT) \
		src/lib/Msg.$(OBJ_EXT) \
		src/lib/Mbox.$(OBJ_EXT) \
		src/lib/Index.$(OBJ_EXT) \
		src/app/$(EXECUTABLE).$(OBJ_EXT)


clean:
	@rm -rf bin/$(EXECUTABLE)
	@find src \
		    -iname '*.o' \
		-or -iname '*.cmi' \
		-or -iname "*.$(OBJ_EXT)" \
		| xargs rm
