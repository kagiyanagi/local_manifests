#!/bin/bash
set -e

ROM=voltage
OLD_VENDOR="yaap"
MANIFEST_URL=https://github.com/LineageOS/android_manifest.git
BRANCH=16.2

export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
ccache -M 50G
ccache -o compression=true

mkdir -p ~/Code/$ROM
cd ~/Code/$ROM

repo init -u $MANIFEST_URL -b $BRANCH --git-lfs --depth=1
git clone https://github.com/kagiyanagi/local_manifests.git .repo/local_manifests
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags --optimized-fetch --retry-fetches=25 --prune

cd device/xiaomi/gale

mv "${OLD_VENDOR}.dependencies" "${ROM}.dependencies"
mv "${OLD_VENDOR}_gale.mk" "${ROM}_gale.mk"

sed -i "s/${OLD_VENDOR}_gale.mk/${ROM}_gale.mk/g" AndroidProducts.mk
sed -i "s/vendor\/${OLD_VENDOR}/vendor\/${ROM}/g" BoardConfig.mk
sed -i "s/vendor\/${OLD_VENDOR}/vendor\/${ROM}/g" "${ROM}_gale.mk"
sed -i "s/${OLD_VENDOR}_gale/${ROM}_gale/g" "${ROM}_gale.mk"

cd ../../../

# now setup rbe

source build/envsetup.sh
lunch ${ROM}_gale-$(find $(gettop)/build/release/aconfig/* -maxdepth 0 -type d -name "[a-z][a-z][0-9][a-z]" -printf '%f\n' | tail -n1)-userdebug

mka bacon -j$(nproc --all)
# mka clean
# mka cleaninstall
# rm -rf out
