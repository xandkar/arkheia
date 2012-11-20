EXECUTABLE_NAME="mldb"
COMPILER="ocamlopt"
OBJ_EXT="cmx"


compile:
	@ocamlfind $(COMPILER) -package batteries -linkpkg \
		-o bin/$(EXECUTABLE_NAME) \
		src/mldb.ml


clean:
	@rm -rf bin/$(EXECUTABLE_NAME)
	@find src \
		    -iname '*.o' \
		-or -iname '*.cmi' \
		-or -iname "*.$(OBJ_EXT)" \
		| xargs rm
