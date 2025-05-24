set -e

if [[ -z "${SSLC}" ]]; then
  echo "FAIL: No compiler env variable"
  exit 1
fi

SSLC=$(realpath "$SSLC")
# echo "Debug: fullpath=$SSLC"

mkdir -p tmp
cd tmp

# rm -rf *

if [ ! -d 'Fallout2_Restoration_Project' ]; then
  ### Checkout fallout2-rpu
  if true ; then
    echo "== Downloading Fallout2_Restoration_Project scripts =="
    git clone --depth=1 -n --filter=tree:0 https://github.com/BGforgeNet/Fallout2_Restoration_Project.git
    cd Fallout2_Restoration_Project
    git sparse-checkout init --cone
    git sparse-checkout set scripts_src
    git checkout

    cd ..
    echo "Done"
  else
    mkdir -p Fallout2_Restoration_Project/scripts_src/democity
    echo '
    #include <sfall.h>
    procedure start begin
    
    end ' > Fallout2_Restoration_Project/scripts_src/democity/script1.ssl
  fi
fi


MODDERPACK_DIR=$(pwd)/modderspack

## Download modderspack
if [ ! -d 'modderspack' ]; then
  echo "== modderpack =="
  curl -L https://cyfuture.dl.sourceforge.net/project/sfall/Modders%20pack/modderspack_4.4.6.7z?viasf=1 > modderspack_4.4.6.7z
  7z x modderspack_4.4.6.7z -omodderspack
  echo "Done"
fi

cd Fallout2_Restoration_Project/scripts_src
  if [ ! -L 'sfall' ] && [ ! -d 'sfall' ]; then
    ln -s "$MODDERPACK_DIR/scripting_docs/headers" sfall
  fi
cd ../..

TEST_FAILED_FILES=""

COMPILATION_FAILED_FILES=""

SSLC_FLAGS="-q -p -l -O2 -d -s -n"

cd Fallout2_Restoration_Project/scripts_src

# Remove all \r from files to make diff more predicable and to suppress sslc warnings
find . -type f -iname '*.ssl' -exec sed -i 's/\r$//' {} \;
find . -type f -iname '*.h' -exec sed -i 's/\r$//' {} \;
find "$MODDERPACK_DIR" -type f -iname '*.h' -exec sed -i 's/\r$//' {} \;

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

    set +e
    $WINE $MODDERPACK_DIR/ScriptEditor/resources/compile.exe $SSLC_FLAGS \
      "-I$MODDERPACK_DIR/scripting_docs/headers" \
      "$FNAME" -o "$FBASE.int.expected" > "$FBASE.stdout.expected"
    RETURN_CODE_EXPECTED=$?
    set -e
    sed -i 's/\r//g' $FBASE.stdout.expected
    sed -i 's#[a-zA-Z0-9\/\:]*/test/tmp/Fallout2_Restoration_Project/scripts_src/#/scripts_src/#g' "$FBASE.stdout.expected" # On wine absolute paths can be different

    set +e
    $SSLC $SSLC_FLAGS \
      "-I$MODDERPACK_DIR/scripting_docs/headers" \
      "$FNAME" -o "$FBASE.int.observed" > "$FBASE.stdout.observed"
    RETURN_CODE_OBSERVED=$?
    set -e
    sed -i 's/\r//g' "$FBASE.stdout.observed"
    sed -i 's#[a-zA-Z0-9\/\:]*/test/tmp/Fallout2_Restoration_Project/scripts_src/#/scripts_src/#g' "$FBASE.stdout.observed"
    

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
  echo "Please check the compilation process and ensure all dependencies are correctly set up."
fi

if [ -n "$TEST_FAILED_FILES" ]; then
  echo "=== Errors found in the following files: ==="
  echo "$TEST_FAILED_FILES"
  exit 1
else
  echo "=== All tests passed successfully! ==="
fi