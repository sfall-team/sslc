set -e

SSLC_FLAGS="-q -p -l -O2 -d -s -n"


mkdir -p gamescripts
cd gamescripts

# rm -rf *

if [ ! -d 'Fallout2_Restoration_Project' ]; then
  echo "== Fallout2_Restoration_Project scripts =="
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

  echo "== Fallout2_Restoration_Project scripts removing \r =="
  find . -type f -iname '*.ssl' -exec sed -i 's/\r$//' {} \;
  find . -type f -iname '*.h' -exec sed -i 's/\r$//' {} \;

  echo "Done"
else 
  echo "== Fallout2_Restoration_Project scripts already downloaded =="
fi


MODDERPACK_DIR=$(pwd)/modderspack

## Download modderspack
if [ ! -d 'modderspack' ]; then
  echo "== modderpack =="

  if ! which 7z >/dev/null; then
    sudo apt update
    sudo apt install -y p7zip-full
  fi


  curl -L https://cyfuture.dl.sourceforge.net/project/sfall/Modders%20pack/modderspack_4.4.6.7z?viasf=1 > modderspack_4.4.6.7z
  7z x modderspack_4.4.6.7z -omodderspack
  
  echo "Done, removing \r"

  find modderspack -type f -iname '*.h' -exec sed -i 's/\r$//' {} \;
  echo "Done"
else 
  echo "== modderpack already downloaded =="
fi

cd Fallout2_Restoration_Project/scripts_src
  if [ ! -L 'sfall' ] && [ ! -d 'sfall' ]; then
    # ln -s "$MODDERPACK_DIR/scripting_docs/headers" sfall
    echo "== Creating symlink to modderspack headers =="
    ln -s ../../modderspack/scripting_docs/headers sfall
  else
    echo "== Symlink to modderspack headers already exists =="
  fi
cd ../..



cd Fallout2_Restoration_Project/scripts_src

if false; then # Some debugging
  echo "== Fallout2_Restoration_Project removing snapshots =="
  find . -type f -iname '*.expected' -delete -print
  echo "Done"
fi


echo "== Fallout2_Restoration_Project building snapshot =="
COMPILATION_FAILED_FILES=""

for f in $(find . -type f -iname '*.ssl') ; do
    OLD_PWD=$(pwd)

    DIR=$(dirname $f)
    FBASE=$(basename -s .ssl $f)
    FNAME=$(basename $f)


    cd "$DIR"

    if [[ -f "$FBASE.stdout.expected" && -f "$FBASE.returncode.expected" ]]; then
      echo "$DIR/$FNAME: already built, skipping"
    else
      echo "$DIR/$FNAME: building reference snapshot"
      set +e

      if [[ ! -n "$WINE_IS_INSTALLED" && -n "$WINE" ]]; then
        echo "Installing wine"
        sudo dpkg --add-architecture i386
        sudo apt update
        sudo apt install -y wine32
        WINE_IS_INSTALLED="yes"
      fi

      $WINE $MODDERPACK_DIR/ScriptEditor/resources/compile.exe $SSLC_FLAGS \
        "-I$MODDERPACK_DIR/scripting_docs/headers" \
        "$FNAME" -o "$FBASE.int.expected" > "$FBASE.stdout.expected"
      RETURN_CODE_EXPECTED=$?
      echo -n "$RETURN_CODE_EXPECTED" > "$FBASE.returncode.expected"
      set -e
      sed -i 's/\r//g' $FBASE.stdout.expected
      # sed -i 's#[a-zA-Z0-9\/\:]*/test/gamescripts/Fallout2_Restoration_Project/scripts_src/#/scripts_src/#g' "$FBASE.stdout.expected" # On wine absolute paths can be different
      sed -i 's#[a-zA-Z0-9\/\:]*/test/gamescripts/#/#g' "$FBASE.stdout.expected" # On wine absolute paths can be different
      echo "  Done, return code $RETURN_CODE_EXPECTED"

      if [ "$RETURN_CODE_EXPECTED" -ne 0 ]; then
        COMPILATION_FAILED_FILES="$COMPILATION_FAILED_FILES $DIR/$FNAME"
      fi

    fi      




    cd "$OLD_PWD"
done

if [ -n "$COMPILATION_FAILED_FILES" ]; then
  echo "=== Compilation errors found in the following files: ==="
  echo "$COMPILATION_FAILED_FILES"
fi