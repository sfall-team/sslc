set -e

if [[ -z "${SSLC}" ]]; then
  echo "FAIL: No compiler env variable"
  exit 1
fi



SSLC=$(realpath "$SSLC")
# echo "Debug: fullpath=$SSLC"

cd gamescripts

MODDERPACK_DIR=$(pwd)/modderspack

TEST_FAILED_FILES=""

COMPILATION_FAILED_FILES=""

## TODO: Them same as in build snapshot
SSLC_FLAGS="-q -p -l -O2 -d -s -n"

cd Fallout2_Restoration_Project/scripts_src

for f in $(find . -type f -iname '*.ssl') ; do
    if [ "$f" != "./epa/epac8.ssl" ]; then
      # continue # Debugging
      true
    fi

    DIR=$(dirname $f)
    FBASE=$(basename -s .ssl $f)
    FNAME=$(basename $f)

    echo "======================= $DIR/$FNAME ========================"
    cd "$DIR"

    # Expected build
    RETURN_CODE_EXPECTED=$(cat "$FBASE.returncode.expected")

    # Obvserved build
    set +e
    $SSLC $SSLC_FLAGS \
      "-I$MODDERPACK_DIR/scripting_docs/headers" \
      "$FNAME" -o "$FBASE.int.observed" > "$FBASE.stdout.observed"
    RETURN_CODE_OBSERVED=$?
    set -e
    sed -i 's/\r//g' "$FBASE.stdout.observed"
    sed -i 's#[a-zA-Z0-9\/\:]*/test/gamescripts/#/#g' "$FBASE.stdout.observed" # On wine absolute paths can be different
    
    

    echo " > expected return code $RETURN_CODE_EXPECTED, observed $RETURN_CODE_OBSERVED"

    # if [ ! -f "$FBASE.int.expected" ]; then
    #   COMPILATION_FAILED_FILES="$COMPILATION_FAILED_FILES $DIR/$FNAME"
    # fi

    if [ "$RETURN_CODE_EXPECTED" -ne 0 ]; then
      COMPILATION_FAILED_FILES="$COMPILATION_FAILED_FILES $DIR/$FNAME"
      if [ "$RETURN_CODE_EXPECTED" -ne "$RETURN_CODE_OBSERVED" ]; then
        echo "=== Return code mismatch, want $RETURN_CODE_EXPECTED got $RETURN_CODE_OBSERVED ==="
        TEST_FAILED_FILES="$TEST_FAILED_FILES $DIR/$FNAME=RETURNCODE"        
      fi
    elif [ "$RETURN_CODE_OBSERVED" -ne 0 ]; then
        echo "=== Return code mismatch, want $RETURN_CODE_EXPECTED got $RETURN_CODE_OBSERVED ==="
        TEST_FAILED_FILES="$TEST_FAILED_FILES $DIR/$FNAME=RETURNCODE"        
    else # Both returned 0
      if ! diff -q $FBASE.stdout.expected $FBASE.stdout.observed ; then
        echo "=== STDOUT mismatch ==="
        set +e
        diff "$FBASE.stdout.expected" "$FBASE.stdout.observed"
        set -e
        TEST_FAILED_FILES="$TEST_FAILED_FILES $DIR/$FNAME=STDOUT"
      fi

      if ! diff "$FBASE.int.expected" "$FBASE.int.observed" ; then
        echo "=== .INT FILES DIFFERENT ==="
        TEST_FAILED_FILES="$TEST_FAILED_FILES $DIR/$FNAME=INT"
      fi
    fi

    cd - >/dev/null 
done

echo "=== Test results: ==="

if [ -n "$COMPILATION_FAILED_FILES" ]; then
  echo "=== Compilation errors found in the following files: ==="
  echo "$COMPILATION_FAILED_FILES"
fi

if [ -n "$TEST_FAILED_FILES" ]; then
  echo "=== Errors found in the following files: ==="
  echo "$TEST_FAILED_FILES"
  exit 1
else
  echo "=== All tests passed successfully! ==="
fi