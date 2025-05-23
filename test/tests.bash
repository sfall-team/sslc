# set -e

#
# This file runs sslc on test files in this folder
# and returns error code if git detects some changes
#
#


if [[ -z "${SSLC}" ]]; then
  echo "FAIL: No compiler env variable"
  exit 1
fi

sed -i 's/\r$//' "include/*.h" # To suppess sslc warnings

ERRORS=""

# echo "Debug: arg=$SSLC"
SSLC=$(realpath "$SSLC")
# echo "Debug: fullpath=$SSLC"

function run_tests() {
  DIR=$1
  OPTIMIZER_OPTS=$2
  cd $DIR
  for f in *.ssl; do
    BNAME=$(basename -s .ssl $f)
    echo "======================= $DIR/$f ========================"
    sed -i 's/\r$//' "$f" # To suppess sslc warnings
    $SSLC $OPTIMIZER_OPTS -I../include $f -o $BNAME.int.testrun > $BNAME.stdout.testrun
    RETURN_CODE=$?

    sed -i 's/\r$//' $BNAME.stdout
    sed -i 's/\r$//' $BNAME.stdout.testrun
    if diff $BNAME.stdout $BNAME.stdout.testrun ; then
      true; # Stdout is equal
    else
      echo "===expected stdout==="
      cat $BNAME.stdout
      echo "===received stdout==="
      cat $BNAME.stdout.testrun
      ERRORS="$ERRORS $DIR/$f=STDOUT"
    fi

    if diff $BNAME.int.testrun $BNAME.int ; then
      true; # Binary files are equal
    else
      echo "===.INT FILES DIFFERENT==="
      ERRORS="$ERRORS $DIR/$f=INT"
    fi

    if [ $RETURN_CODE -eq 0 ]; then
      true # all ok
      # Debugging
      #echo '===stdout=='
      #cat $(basename -s .ssl $f).stdout
      #echo '==========='
    else
      ERRORS="$ERRORS $DIR/$f=$RETURN_CODE"
      echo "Return code is $RETURN_CODE for $DIR/$f"
      cat $(basename -s .ssl $f).stdout
    fi
  done
  cd ..
}

echo "=== Running tests using $SSLC ==="

run_tests with_optimizer "-q -p -l -O2 -d -s -n"


if [[ -z "${ERRORS}" ]]; then
  echo "No errors"
else
  exit 1
fi

# This checks if sslc left some temp files
TMPFILES=$(find . -type f -iname '*.tmp')
if [[ -z "${TMPFILES}" ]]; then
  true; # Ok, no temp files
else
  echo "Found some unexpected temp files:"
  echo $TMPFILES
  exit 1
fi


echo "=== All tests passed ==="