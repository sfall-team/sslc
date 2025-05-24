if [[ -z "${SSLC}" ]]; then
  echo "FAIL: No compiler env variable"
  exit 1
fi

SSLC=$(realpath "$SSLC")
# echo "Debug: fullpath=$SSLC"

cd tmp

rm -rf *

if [ ! -d 'Fallout2_Restoration_Project' ]; then
  ### Checkout fallout2-rpu
  if true ; then
    git clone git@github.com:BGforgeNet/Fallout2_Restoration_Project.git
  else
    mkdir -p Fallout2_Restoration_Project/scripts_src/democity
    echo '
    #include <sfall.h>
    procedure start begin
    
    end ' > Fallout2_Restoration_Project/scripts_src/democity/script1.ssl
  fi
fi


## Download modderspack
if [ ! -d 'modderspack' ]; then
curl -L https://cyfuture.dl.sourceforge.net/project/sfall/Modders%20pack/modderspack_4.4.6.7z?viasf=1 > modderspack_4.4.6.7z
7z x modderspack_4.4.6.7z -omodderspack
fi

MODDERPACK_DIR=$(pwd)/modderspack

ERROR_FILES=""

SSLC_FLAGS="-q -p -l -O2 -d -s -n"

cd Fallout2_Restoration_Project/scripts_src
find . -type f -iname '*.ssl' -exec sed -i 's/\r$//' {} \;
find . -type f -iname '*.h' -exec sed -i 's/\r$//' {} \;
find "$MODDERPACK_DIR" -type f -iname '*.h' -exec sed -i 's/\r$//' {} \;

for f in $(find . -type f -iname '*.ssl') ; do
    DIR=$(dirname $f)
    FBASE=$(basename -s .ssl $f)
    FNAME=$(basename $f)

    echo "======================= $DIR/$FNAME ========================"
    cd $DIR
    $WINE $MODDERPACK_DIR/ScriptEditor/resources/compile.exe $SSLC_FLAGS \
      -I$MODDERPACK_DIR/scripting_docs/headers \
      $FNAME -o $FBASE.int.expected > $FBASE.stdout.expected
    RETURN_CODE_EXPECTED=$?
    sed -i 's/\r$//' $FBASE.stdout.expected
    # TODO: Patch file to remove absolute paths

    $SSLC $SSLC_FLAGS \
      -I$MODDERPACK_DIR/scripting_docs/headers \
      $FNAME -o $FBASE.int.observed > $FBASE.stdout.observed
    RETURN_CODE_OBSERVED=$?
    # TODO: Patch file to remove absolute paths
    sed -i 's/\r$//' $FBASE.stdout.observed

    if [ "$RETURN_CODE_EXPECTED" -ne 0 ]; then
      if [ "$RETURN_CODE_EXPECTED" -ne "$RETURN_CODE_OBSERVED" ]; then
        echo "=== Return code mismatch, want $RETURN_CODE_EXPECTED got $RETURN_CODE_OBSERVED ==="
        ERROR_FILES="$ERROR_FILES $DIR/$FNAME=RETURNCODE"        
      fi
    elif [ "$RETURN_CODE_OBSERVED" -ne 0 ]; then
       echo "=== Return code mismatch, want $RETURN_CODE_EXPECTED got $RETURN_CODE_OBSERVED ==="
      ERROR_FILES="$ERROR_FILES $DIR/$FNAME=RETURNCODE"        
    else # Both returned 0
      if ! diff $FBASE.stdout.expected $FBASE.stdout.observed ; then
        echo "=== STDOUT mismatch ==="
        diff $FBASE.stdout.expected $FBASE.stdout.observed
        ERROR_FILES="$ERROR_FILES $DIR/$FNAME=STDOUT"
      fi

      if ! diff $FBASE.int.expected $FBASE.int.observed ; then
        echo "=== .INT FILES DIFFERENT ==="
        ERROR_FILES="$ERROR_FILES $DIR/$FNAME=INT"
      fi
    fi

    cd -
done


if [ -n "$ERROR_FILES" ]; then
  echo "=== Errors found in the following files: ==="
  echo "$ERROR_FILES"
  exit 1
else
  echo "=== All tests passed successfully! ==="
fi