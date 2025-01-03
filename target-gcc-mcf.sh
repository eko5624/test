#!/bin/bash
set -e

TOP_DIR=$(pwd)
source $TOP_DIR/ver.sh
export BRANCH_GCC=releases/gcc-${VER_GCC%%.*}

# Speed up the process
# Env Var NUMJOBS overrides automatic detection
MJOBS=$(grep -c processor /proc/cpuinfo)

M_ROOT=$(pwd)
M_SOURCE=$M_ROOT/source
M_BUILD=$M_ROOT/build
M_CROSS=$M_ROOT/cross
M_TARGET=$M_ROOT/target
MINGW_TRIPLE="x86_64-w64-mingw32"
PATH="$M_CROSS/bin:$PATH"

mkdir -p $M_SOURCE
mkdir -p $M_BUILD

echo "gettiong source"
echo "======================="
cd $M_SOURCE

#binutils
wget -c -O binutils-$VER_BINUTILS.tar.bz2 http://ftp.gnu.org/gnu/binutils/binutils-$VER_BINUTILS.tar.bz2 2>/dev/null >/dev/null
tar xjf binutils-$VER_BINUTILS.tar.bz2 2>/dev/null >/dev/null
#mkdir binutils
#git clone https://sourceware.org/git/binutils-gdb.git --branch binutils-${VER_BINUTILS//./_}-branch binutils

#gmp
wget -c -O gmp-$VER_GMP.tar.bz2 https://ftp.gnu.org/gnu/gmp/gmp-$VER_GMP.tar.bz2 2>/dev/null >/dev/null
tar xjf gmp-$VER_GMP.tar.bz2 2>/dev/null >/dev/null

#mpfr
wget -c -O mpfr-$VER_MPFR.tar.bz2 https://ftp.gnu.org/gnu/mpfr/mpfr-$VER_MPFR.tar.bz2 2>/dev/null >/dev/null
tar xjf mpfr-$VER_MPFR.tar.bz2 2>/dev/null >/dev/null

#MPC
wget -c -O mpc-$VER_MPC.tar.gz https://ftp.gnu.org/gnu/mpc/mpc-$VER_MPC.tar.gz 2>/dev/null >/dev/null
tar xzf mpc-$VER_MPC.tar.gz 2>/dev/null >/dev/null

#isl
wget -c -O isl-$VER_ISL.tar.bz2 https://gcc.gnu.org/pub/gcc/infrastructure/isl-$VER_ISL.tar.bz2 2>/dev/null >/dev/null
tar xjf isl-$VER_ISL.tar.bz2 2>/dev/null >/dev/null

#mingw-w64
git clone https://github.com/mingw-w64/mingw-w64.git --branch master

#mcfgthread
git clone https://github.com/lhmouse/mcfgthread.git --branch master

wget -c -O mcfgthread-1.9-ga.2 https://github.com/lhmouse/mcfgthread/archive/refs/tags/v1.9-ga.2.tar.gz 2>/dev/null >/dev/null
tar xzf mcfgthread-1.9-ga.2 2>/dev/null >/dev/null

echo "building mcfgthread"
echo "======================="
cd $M_SOURCE/mcfgthread-1.9-ga.2
meson setup build \
  --prefix=$M_TARGET \
  --cross-file=$TOP_DIR/cross.meson \
  -Doptimization=1
meson compile -C build
meson install -C build
rm -rf $M_TARGET/lib/pkgconfig

echo "building gmp"
echo "======================="
cd $M_BUILD
mkdir gmp-build && cd gmp-build
$M_SOURCE/gmp-$VER_GMP/configure \
  --host=$MINGW_TRIPLE \
  --target=$MINGW_TRIPLE \
  --prefix=$M_BUILD/for_target \
  --enable-static \
  --disable-shared
make -j$MJOBS
make install

echo "building mpfr"
echo "======================="
cd $M_BUILD
mkdir mpfr-build && cd mpfr-build
$M_SOURCE/mpfr-$VER_MPFR/configure \
  --host=$MINGW_TRIPLE \
  --target=$MINGW_TRIPLE \
  --prefix=$M_BUILD/for_target \
  --with-gmp=$M_BUILD/for_target \
  --enable-static \
  --disable-shared
make -j$MJOBS
make install

echo "building MPC"
echo "======================="
cd $M_BUILD
mkdir mpc-build && cd mpc-build
$M_SOURCE/mpc-$VER_MPC/configure \
  --host=$MINGW_TRIPLE \
  --target=$MINGW_TRIPLE \
  --prefix=$M_BUILD/for_target \
  --with-{gmp,mpfr}=$M_BUILD/for_target \
  --enable-static \
  --disable-shared
make -j$MJOBS
make install

echo "building isl"
echo "======================="
cd $M_BUILD
mkdir isl-build && cd isl-build
$M_SOURCE/isl-$VER_ISL/configure \
  --host=$MINGW_TRIPLE \
  --target=$MINGW_TRIPLE \
  --prefix=$M_BUILD/for_target \
  --with-gmp-prefix=$M_BUILD/for_target \
  --enable-static \
  --disable-shared
make -j$MJOBS
make install

echo "building binutils"
echo "======================="
cd $M_BUILD
mkdir binutils-build && cd binutils-build
curl -OL https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-binutils/0002-check-for-unusual-file-harder.patch
curl -OL https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-binutils/0010-bfd-Increase-_bfd_coff_max_nscns-to-65279.patch
curl -OL https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-binutils/0110-binutils-mingw-gnu-print.patch
curl -OL https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-binutils/0410-windres-handle-spaces.patch
curl -OL https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-binutils/0500-fix-weak-undef-symbols-after-image-base-change.patch
curl -OL https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-binutils/2001-ld-option-to-move-default-bases-under-4GB.patch
curl -OL https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-binutils/2003-Restore-old-behaviour-of-windres-so-that-options-con.patch
curl -OL https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-binutils/3001-hack-libiberty-link-order.patch
curl -OL https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-binutils/libiberty-unlink-handle-windows-nul.patch
curl -OL https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-binutils/reproducible-import-libraries.patch

apply_patch_for_binutils() {
  for patch in "$@"; do
    echo "Applying $patch"
    patch -p1 -i "$M_BUILD/binutils-build/$patch"
  done
}

cd $M_SOURCE/binutils-$VER_BINUTILS
apply_patch_for_binutils \
  0002-check-for-unusual-file-harder.patch \
  0010-bfd-Increase-_bfd_coff_max_nscns-to-65279.patch \
  0110-binutils-mingw-gnu-print.patch

# Add an option to change default bases back below 4GB to ease transition
# https://github.com/msys2/MINGW-packages/issues/7027
# https://github.com/msys2/MINGW-packages/issues/7023
apply_patch_for_binutils 2001-ld-option-to-move-default-bases-under-4GB.patch

# https://github.com/msys2/MINGW-packages/pull/9233#issuecomment-889439433
patch -R -p1 -i $M_BUILD/binutils-build/2003-Restore-old-behaviour-of-windres-so-that-options-con.patch

# patches for reproducibility from Debian:
# https://salsa.debian.org/mingw-w64-team/binutils-mingw-w64/-/tree/master/debian/patches
patch -p2 -i $M_BUILD/binutils-build/reproducible-import-libraries.patch

# Handle Windows nul device
# https://github.com/msys2/MINGW-packages/issues/1840
# https://github.com/msys2/MINGW-packages/issues/10520
# https://github.com/msys2/MINGW-packages/issues/14725

# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=108276
# https://gcc.gnu.org/pipermail/gcc-patches/2023-January/609487.html
patch -p1 -i $M_BUILD/binutils-build/libiberty-unlink-handle-windows-nul.patch

# XXX: make sure we link against the just built libiberty, not the system one
# to avoid a linker error. All the ld deps contain system deps and system
# search paths, so imho if things link against the system lib or the just
# built one is just luck, and I don't know how that is supposed to work.
patch -p1 -i $M_BUILD/binutils-build/3001-hack-libiberty-link-order.patch

cd $M_BUILD/binutils-build
$M_SOURCE/binutils-$VER_BINUTILS/configure \
  --host=$MINGW_TRIPLE \
  --target=$MINGW_TRIPLE \
  --prefix=$M_TARGET \
  --with-sysroot=$M_TARGET \
  --disable-multilib \
  --disable-nls \
  --disable-werror \
  --disable-shared \
  --enable-lto \
  --enable-64-bit-bfd
make -j$MJOBS
make install

echo "building mingw-w64-headers"
echo "======================="
cd $M_BUILD
mkdir headers-build && cd headers-build
$M_SOURCE/mingw-w64/mingw-w64-headers/configure \
  --host=$MINGW_TRIPLE \
  --prefix=$M_TARGET \
  --enable-sdk=all \
  --with-default-msvcrt=ucrt \
  --enable-idl \
  --without-widl
make -j$MJOBS
make install
cd $M_TARGET
ln -s $MINGW_TRIPLE mingw
rm $M_TARGET/include/pthread_signal.h
rm $M_TARGET/include/pthread_time.h
rm $M_TARGET/include/pthread_unistd.h

echo "building winpthreads"
echo "======================="
cd $M_BUILD
mkdir winpthreads-build && cd winpthreads-build
#curl -OL https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-winpthreads-git/0001-Define-__-de-register_frame_info-in-fake-libgcc_s.patch

#cd $M_SOURCE/mingw-w64
#git apply $M_BUILD/winpthreads-build/0001-Define-__-de-register_frame_info-in-fake-libgcc_s.patch

cd $M_SOURCE/mingw-w64/mingw-w64-libraries/winpthreads

sed -i "s|fakelib_libgcc_s_a_SOURCES =|fakelib_libgcc_s_a_SOURCES = src/libgcc/dll_frame_info.c|" Makefile.am
cat <<EOF >src/libgcc/dll_frame_info.c
/* Because of:
   https://github.com/Alexpux/MINGW-packages/blob/master/mingw-w64-gcc/955-4.9.2-apply-hack-so-gcc_s-isnt-stripped.patch
   .. we need to define these functions.
*/

void __register_frame_info (__attribute__((unused)) const void *vp, __attribute__((unused)) void *op)
{
}

void *__deregister_frame_info (__attribute__((unused)) const void *vp)
{
    return (void *)0;
}
EOF

autoreconf -vfi

cd $M_BUILD/winpthreads-build
$M_SOURCE/mingw-w64/mingw-w64-libraries/winpthreads/configure \
  --host=$MINGW_TRIPLE \
  --prefix=$M_TARGET \
  --enable-static \
  --enable-shared
make -j$MJOBS
make install

echo "building mingw-w64-crt"
echo "======================="
cd $M_BUILD
mkdir crt-build && cd crt-build
$M_SOURCE/mingw-w64/mingw-w64-crt/configure \
  --host=$MINGW_TRIPLE \
  --prefix=$M_TARGET \
  --with-sysroot=$M_TARGET \
  --with-default-msvcrt=ucrt \
  --enable-wildcard \
  --disable-dependency-tracking \
  --enable-lib64 \
  --disable-lib32
make -j$MJOBS install-strip
make install
# Create empty dummy archives, to avoid failing when the compiler driver
# adds -lssp -lssh_nonshared when linking.
ar rcs $M_TARGET/lib/libssp.a
ar rcs $M_TARGET/lib/libssp_nonshared.a

echo "building gendef"
echo "======================="
cd $M_BUILD
mkdir gendef-build && cd gendef-build
$M_SOURCE/mingw-w64/mingw-w64-tools/gendef/configure \
  --host=$MINGW_TRIPLE \
  --target=$MINGW_TRIPLE \
  --prefix=$M_TARGET
make -j$MJOBS
make install
rm -rf $M_SOURCE/mingw-w64


