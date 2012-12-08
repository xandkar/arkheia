#! /usr/bin/env zsh

LIST_NAME='erlang-questions'

DATA_DIR='data'
ARCHIVE_DIR="$DATA_DIR/lists/$LIST_NAME/archive"


main() {
    for file in `ls -1 $ARCHIVE_DIR/*`;
    do
        echo $file
        time ./bin/arkheia \
            -data-dir $DATA_DIR \
            -list-name $LIST_NAME \
            -mbox-file $file \
            -operation build_index
        echo
    done
}


main
