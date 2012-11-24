EXECUTABLE="mldb"

COMPILER="ocamlopt"
OBJ_EXT="cmx"
LIBS="batteries,zip"


all: clean compile link


compile: compile_lib compile_app


compile_lib:
	@          $(COMPILER)                  -I src/lib -c src/lib/mldb_regexp.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/mldb_regexp.ml
	@          $(COMPILER)                  -I src/lib -c src/lib/mldb_utils.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/mldb_utils.ml
	@          $(COMPILER)                  -I src/lib -c src/lib/mldb_gz.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/mldb_gz.ml
	@          $(COMPILER)                  -I src/lib -c src/lib/mldb_msg.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/mldb_msg.ml
	@          $(COMPILER)                  -I src/lib -c src/lib/mldb_mbox.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/mldb_mbox.ml
	@          $(COMPILER)                  -I src/lib -c src/lib/mldb_index.mli
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/lib/mldb_index.ml
	@          $(COMPILER)                  -I src/lib -c src/lib/mldb.ml


compile_app:
	@ocamlfind $(COMPILER) -package $(LIBS) -I src/lib -c src/app/$(EXECUTABLE)_main.ml


link:
	@mkdir -p bin
	@ocamlfind $(COMPILER) -thread -linkpkg -package $(LIBS) \
		-o bin/$(EXECUTABLE) \
		src/lib/mldb_regexp.$(OBJ_EXT) \
		src/lib/mldb_utils.$(OBJ_EXT) \
		src/lib/mldb_gz.$(OBJ_EXT) \
		src/lib/mldb_msg.$(OBJ_EXT) \
		src/lib/mldb_mbox.$(OBJ_EXT) \
		src/lib/mldb_index.$(OBJ_EXT) \
		src/lib/mldb.$(OBJ_EXT) \
		src/app/$(EXECUTABLE)_main.$(OBJ_EXT)


clean:
	@rm -rf bin/$(EXECUTABLE)
	@find src \
		    -iname '*.o' \
		-or -iname '*.cmi' \
		-or -iname "*.$(OBJ_EXT)" \
		| xargs rm
