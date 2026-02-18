#!/bin/bash
set -e

ROM=voltage
OLD_VENDOR="yaap"
MANIFEST_URL=https://github.com/LineageOS/android_manifest.git
BRANCH=16.2

mkdir -p ~/Code/$ROM
cd ~/Code/$ROM

repo init -u $MANIFEST_URL -b $BRANCH --git-lfs
git clone https://github.com/kagiyanagi/local_manifests.git .repo/local_manifests
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

cd device/xiaomi/gale

mv "${OLD_VENDOR}.dependencies" "${ROM}.dependencies"
mv "${OLD_VENDOR}_gale.mk" "${ROM}_gale.mk"

sed -i "s/${OLD_VENDOR}_gale.mk/${ROM}_gale.mk/g" AndroidProducts.mk
sed -i "s/vendor\/${OLD_VENDOR}/vendor\/${ROM}/g" BoardConfig.mk
sed -i "s/vendor\/${OLD_VENDOR}/vendor\/${ROM}/g" "${ROM}_gale.mk"
sed -i "s/${OLD_VENDOR}_gale/${ROM}_gale/g" "${ROM}_gale.mk"

cd ../../../

source build/envsetup.sh
lunch ${ROM}_gale-bp2a-userdebug

mka bacon  -j$(nproc --all
# mka clean
# mka cleaninstall
# rm -rf out
