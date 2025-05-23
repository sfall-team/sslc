# set -e

#
# This file runs sslc on test files in this folder
# and returns error code if git detects some changes
#
# To reset snapshots just remove all *.stdout and *.int files


if [[ -z "${SSLC}" ]]; then
  echo "FAIL: No compiler env variable"
  exit 1
fi

sed -i 's/\r$//' include/*.h # To suppess sslc warnings

ERRORS=""

# echo "Debug: arg=$SSLC"
SSLC=$(realpath "$SSLC")
# echo "Debug: fullpath=$SSLC"

function run_tests() {
  DIR=$1
  COMPILER_OPTS=$2
  cd $DIR
  for f in *.ssl; do
    BNAME=$(basename -s .ssl $f)
    echo "======================= $DIR/$f ========================"
    sed -i 's/\r$//' "$f" # To suppess sslc warnings
    $SSLC $COMPILER_OPTS -I../include $f -o $BNAME.int.testrun > $BNAME.stdout.testrun
    RETURN_CODE=$?

    sed -i 's/\r$//' $BNAME.stdout
    sed -i 's/\r$//' $BNAME.stdout.testrun

    if [ ! -e "$BNAME.stdout" ]; then
      echo "== UPDATING STDOUT SNAPSHOT =="
      cp $BNAME.stdout.testrun $BNAME.stdout
    fi

    if ! diff $BNAME.stdout $BNAME.stdout.testrun ; then
      echo "===expected stdout==="
      cat $BNAME.stdout
      echo "===received stdout==="
      cat $BNAME.stdout.testrun
      ERRORS="$ERRORS $DIR/$f=STDOUT"
    fi

    if [ ! -e "$BNAME.int" ]; then
      echo "== UPDATING .int SNAPSHOT =="
      cp $BNAME.int.testrun $BNAME.int
    fi

    if ! diff $BNAME.int.testrun $BNAME.int ; then
      echo "===.INT FILES DIFFERENT==="
      ERRORS="$ERRORS $DIR/$f=INT"
    fi

    if [ "$RETURN_CODE" -ne 0 ]; then
      ERRORS="$ERRORS $DIR/$f=$RETURN_CODE"
      echo "Return code is $RETURN_CODE for $DIR/$f"
      cat $BNAME.stdout
    fi
  done
  cd ..
}

echo "=== Running tests using $SSLC ==="

run_tests with_optimizer "-q -p -l -O2 -d -s -n"


if [[ -n "${ERRORS}" ]]; then
  exit 1
else
  echo "No errors"
fi

# This checks if sslc left some temp files
TMPFILES=$(find . -type f -iname '*.tmp')
if [[ -n "${TMPFILES}" ]]; then
  echo "Found some unexpected temp files:"
  echo $TMPFILES
  exit 1
fi


echo "=== All tests passed ==="