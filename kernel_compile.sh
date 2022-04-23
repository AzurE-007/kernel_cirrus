#!/bin/bash

#Kernel building script

# Bail out if script fails
set -e

# Function to show an informational message
msg() {
	echo
	echo -e "\e[1;32m$*\e[0m"
	echo
}

err() {
	echo -e "\e[1;41m$*\e[0m"
	exit 1
}

cdir() {
	cd "$1" 2>/dev/null || \
		err "The directory $1 doesn't exists !"
}

export COMPILER=PROTON-CLANG

git clone --depth=1 $KERNEL -b ruby raphael && cd raphael

export BUILD_START=$(date +"%s")
export ARCH=arm64
make O=out raphael_defconfig

eva_gcc() {
  # docker has gcc repos cloned to gcc directory.
  export GCC_DIR="/tmp/gcc"
  export PATH=$GCC_DIR/gcc64/bin/:$GCC_DIR/gcc32/bin/:/usr/bin:$PATH
  build_commands() {
          make -j"$(nproc --all)" \
          O=out \
          CROSS_COMPILE=aarch64-elf- \
          CROSS_COMPILE_ARM32=arm-eabi-
  }
  build_commands
}

proton_clang() {
  export CLANG_DIR="/tmp/proton-clang"
  git clone --depth=1 https://github.com/kdrag0n/proton-clang $CLANG_DIR
  export PATH=$CLANG_DIR/bin/:/usr/bin:$PATH
  build_commands() {
          make -j"$(nproc --all)" \
          O=out \
          CC=ccache clang \
          CXX=ccache clang++ \
          CROSS_COMPILE=aarch64-linux-gnu- \
          CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
          LD=ld.lld
  }
  build_commands
}

aosp_clang() {
  # clang-12.0.1
  export CLANG_DIR="/tmp/clang"
  git clone --depth=1 https://github.com/geopd/prebuilts_clang_host_linux-x86 -b clang-r407598 $CLANG_DIR/clang64
  git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b master $CLANG_DIR/clang32
  export PATH=$CLANG_DIR/clang32/bin/:$CLANG_DIR/clang64/bin/:/usr/bin:$PATH
  build_commands() {
          make -j"$(nproc --all)" \
          O=out \
          CLANG_TRIPLE=aarch64-linux-gnu- \
          CC=clang
  }
  build_commands
}

sd_clang() {
  export CLANG_DIR="/tmp/sdclang"
  export GCC_DIR="/tmp/gcc/linux-x86"
  git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b master $GCC_DIR
  git clone --depth=1 https://github.com/ThankYouMario/proprietary_vendor_qcom_sdclang -b ruby-12 $CLANG_DIR
  sudo link /lib/libtinfo.so.6 /lib/libtinfo.so.5
  export PATH=$CLANG_DIR/bin/:$GCC_DIR/bin/:/usr/bin:$PATH
  build_commands() {
          make -j"$(nproc --all)" \
          O=out \
          CLANG_TRIPLE=aarch64-linux-gnu- \
          CROSS_COMPILE=aarch64-linux-android- \
          CC=clang
  }
  build_commands
}

case "${COMPILER}" in
 "EVA-GCC") eva_gcc
    ;;
 "PROTON-CLANG") proton_clang
    ;;
 "AOSP-CLANG") aosp_clang
    ;;
 "SDCLANG") sd_clang
    ;;
 *) echo "Invalid option!"
    exit 1
    ;;
esac

export BUILD_END=$(date +"%s")
export DIFF=$((BUILD_END - BUILD_START))

msg "|| Cloning Anykernel ||"
git clone $ANYKERNEL
msg "|| Zipping into a flashable zip ||"
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
cdir AnyKernel3

export ZIPNAME=Test-Kernel-$(TZ=Asia/Kolkata date +%Y%m%d-%H%M).zip
zip -r9 $ZIPNAME ./*

curl -F document=@"$ZIPNAME" "https://api.telegram.org/bot$BOTTOKEN/sendDocument" -F chat_id="$CHATID" -F "parse_mode=Markdown" -F caption="*✅ Build finished after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds*"
