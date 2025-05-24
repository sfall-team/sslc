if [[ -z "${SSLC}" ]]; then
  echo "FAIL: No compiler env variable"
  exit 1
fi

cd tmp

### Checkout fallout2-rpu
# git clone git@github.com:BGforgeNet/Fallout2_Restoration_Project.git
mkdir Fallout2_Restoration_Project
mkdir Fallout2_Restoration_Project/demo
echo "
procedure start begin

end " > Fallout2_Restoration_Project/demo/script1.ssl
#


## Download modderspack
# https://cyfuture.dl.sourceforge.net/project/sfall/Modders%20pack/modderspack_4.4.6.7z?viasf=1