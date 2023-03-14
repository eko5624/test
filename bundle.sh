#set -x

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PACKAGES=$DIR

#copy all *.dylib to mpv.app
sudo cp -r $PACKAGES/mpv/TOOLS/osxbundle/mpv.app $PACKAGES/mpv/build
sudo cp $PACKAGES/mpv/build/mpv $PACKAGES/mpv/build/mpv.app/Contents/MacOS
pushd $PACKAGES/mpv/build/mpv.app/Contents/MacOS
sudo ln -s mpv mpv-bundle
popd

mpv_otool=($(otool -L $PACKAGES/mpv/build/mpv.app/Contents/MacOS/mpv | grep -e '\t' | grep -Ev "\/usr\/lib|\/System|@rpath" | awk '{ print $1 }'))
echo "${mpv_otool[@]}" > $PACKAGES/mpv/build/mpv_otool

mpv_dylibs_otool=()
for dylib in "${mpv_otool[@]}"; do
  mpv_dylib_otool=($(otool -L $dylib | grep -e '\t' | grep -Ev "\/usr\/lib|\/System|@rpath" | awk '{ print $1 }'))
  mpv_dylibs_otool+=("${mpv_dylib_otool[@]}")
done
mpv_dylibs_otool=($(echo "${mpv_dylibs_otool[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
echo "${mpv_dylibs_otool[@]}" > $PACKAGES/mpv/build/mpv_dylibs_otool

dylibs_otool=()
for dylib in "${mpv_dylibs_otool[@]}"; do
  dylib_otool=($(otool -L $dylib | grep -e '\t' | grep -Ev "\/usr\/lib|\/System|@rpath" | awk '{ print $1 }'))
  dylibs_otool+=("${dylib_otool[@]}")
done	
dylibs_otool=($(echo "${dylibs_otool[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
echo "${dylibs_otool[@]}" > $PACKAGES/mpv/build/dylibs_otool

all_dylibs=(${mpv_otool[@]} ${mpv_dylibs_otool[@]} ${dylibs_otool[@]})
all_dylibs=($(echo "${all_dylibs[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
echo "${all_dylibs[@]}" > $PACKAGES/mpv/build/all_dylibs

for f in "${all_dylibs[@]}"; do
  sudo cp $f $PACKAGES/mpv/build/mpv.app/Contents/MacOS/lib
done

#removing swift rpath definitions towards dev tools
rpaths_swift=($(otool -l $PACKAGES/mpv/build/mpv.app/Contents/MacOS/mpv | grep -A2 LC_RPATH | grep path | grep -E "Xcode|CommandLineTools|swift" | awk '{ print $2 }'))
for f in "${rpaths_swift[@]}"; do
  install_name_tool -delete_rpath $f $PACKAGES/mpv/build/mpv.app/Contents/MacOS/mpv
done

#setting additional rpath for swift libraries
install_name_tool -add_rpath @executable_path/lib $PACKAGES/mpv/build/mpv.app/Contents/MacOS/mpv

for dylib in "${mpv_otool[@]}"; do
  install_name_tool -change $dylib @executable_path/lib/$(basename $dylib) $PACKAGES/mpv/build/mpv.app/Contents/MacOS/mpv
done

for f in $PACKAGES/mpv/build/mpv.app/Contents/MacOS/lib/*.dylib; do
  install_name_tool -id "@executable_path/lib/$(basename $f)" "$PACKAGES/mpv/build/mpv.app/Contents/MacOS/lib/$(basename $f)"
  dylib_tool=($(otool -L $PACKAGES/mpv/build/mpv.app/Contents/MacOS/lib/$(basename $f) | grep -Ev "\/usr\/lib|\/System|@rpath" | awk '{ print $1 }'))
  for dylib in "${dylib_tool[@]}"; do
    install_name_tool -change $dylib @executable_path/lib/$(basename $dylib) $PACKAGES/mpv/build/mpv.app/Contents/MacOS/lib/$(basename $f)
  done 
done
