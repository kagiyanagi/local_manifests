#!/bin/bash
set -e

ROM="cipher"
MANIFEST_URL=https://github.com/CipherOS/android_manifest.git
BRANCH=sixteen-qpr2

export BUILD_USERNAME="Ren"
export BUILD_HOSTNAME="Kagiyanagi"

# -- Stuff to build on local machine -- #
# export USE_CCACHE=1
# export CCACHE_EXEC=/usr/bin/ccache
# export CCACHE_DIR=$PWD/out/.ccache
# ccache -M 50G
# ccache -o compression=true
# mkdir -p ~/Code/$ROM
# cd ~/Code/$ROM

rm -rf .repo/local_manifests
rm -rf device/mediatek/sepolicy_vndr
rm -rf hardware/xiaomi
rm -rf hardware/mediatek
rm -rf vendor/mediatek/ims
rm -rf vendor/lineage-priv/keys

repo init -u $MANIFEST_URL -b $BRANCH --git-lfs --depth=1
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags --optimized-fetch --retry-fetches=25 --prune

git clone https://github.com/xaveroprjkt/device_xiaomi_gale.git device/xiaomi/gale -b lineage-23.2 --depth=1
sed -i 's|read -rp "Do you want to clone the signing keys? (y/N): " a|a=y|' device/xiaomi/gale/vendorsetup.sh
source build/envsetup.sh

# fix android_device_mediatek_sepolicy_vndr
sed -i "4s|include device/lineage/sepolicy/libperfmgr/sepolicy.mk|include device/${ROM}/sepolicy/libperfmgr/sepolicy.mk|" device/mediatek/sepolicy_vndr/SEPolicy.mk
if [ ! -d "device/${ROM}/sepolicy/libperfmgr" ]; then
    echo "libperfmgr not found. Cloning and copying..."

    TMP_DIR="$(pwd)/tmp_sepolicy_clone"
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    git clone https://github.com/LineageOS/android_device_lineage_sepolicy -b 23.2 "$TMP_DIR"
    mv "$TMP_DIR/libperfmgr" "device/${ROM}/sepolicy/"
    rm -rf "$TMP_DIR"
    echo "libperfmgr moved successfully."
    sed -i "2s|^[[:space:]]*device/lineage/sepolicy/libperfmgr/vendor$|    device/${ROM}/sepolicy/libperfmgr/vendor|" device/"${ROM}"/sepolicy/libperfmgr/sepolicy.mk
else
    echo "device/${ROM}/sepolicy/libperfmgr already exists. Skipping."
fi


cd device/xiaomi/gale

mv "lineage.dependencies" "${ROM}.dependencies"
mv "lineage_gale.mk" "${ROM}_gale.mk"

sed -i "s/lineage_gale.mk/${ROM}_gale.mk/g" AndroidProducts.mk
sed -i "s/vendor\/lineage/vendor\/${ROM}/g" BoardConfig.mk
sed -i "s/vendor\/lineage/vendor\/${ROM}/g" "${ROM}_gale.mk"
sed -i "s/lineage_gale/${ROM}_gale/g" "${ROM}_gale.mk"

cd ../../../

# now setup rbe

source build/envsetup.sh
lunch ${ROM}_gale-$(find $(gettop)/build/release/aconfig/* -maxdepth 0 -type d -name "[a-z][a-z][0-9][a-z]" -printf '%f\n' | tail -n1)-userdebug
make installclean
m bacon -j$(nproc --all)
