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

## TODO: They should be the same as in snapshot build
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

    OLD_PWD=$(pwd)
    echo "======================= $DIR/$FNAME ========================"
    cd "$DIR"

    # Expected build
    if [ ! -f "$FBASE.returncode.expected" ]; then
      echo "ERROR: NO EXPECTED RETURN CODE FILE $FBASE.returncode.expected"
      echo "Please run test/test_on_fallout2_rpu_setup.bash first"
      echo ""
      echo "If this error appears on CI then try to bump cache version in all actions/cache@v4"
      exit 1
    fi
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
    
    

   
    # if [ ! -f "$FBASE.int.expected" ]; then
    #   COMPILATION_FAILED_FILES="$COMPILATION_FAILED_FILES $DIR/$FNAME"
    # fi

    if [ "$RETURN_CODE_OBSERVED" -ne "$RETURN_CODE_EXPECTED" ]; then
        echo "  > FAIL: Return code mismatch, want $RETURN_CODE_EXPECTED got $RETURN_CODE_OBSERVED ==="
        TEST_FAILED_FILES="$TEST_FAILED_FILES $DIR/$FNAME=RETURNCODE"        
    else

      if ! diff -q $FBASE.stdout.expected $FBASE.stdout.observed ; then
        echo "  > FAIL: STDOUT mismatch"
        set +e
        diff "$FBASE.stdout.expected" "$FBASE.stdout.observed"
        set -e
        TEST_FAILED_FILES="$TEST_FAILED_FILES $DIR/$FNAME=STDOUT"
      fi

      if [ "$RETURN_CODE_EXPECTED" -eq 0 ] && ! diff "$FBASE.int.expected" "$FBASE.int.observed" ; then
        echo "  > FAIL: .INT files mismatch"
        TEST_FAILED_FILES="$TEST_FAILED_FILES $DIR/$FNAME=INT"
      fi
    fi

    cd "$OLD_PWD"
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