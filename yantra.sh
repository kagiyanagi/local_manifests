#!/bin/bash
set -e

ROM="cipher"
MANIFEST_URL="https://github.com/CipherOS/android_manifest.git"
BRANCH="sixteen"

export BUILD_USERNAME="ren"
export BUILD_HOSTNAME="kagiyanagi"

# -- Stuff to build on local machine -- #
# export USE_CCACHE=1
# export CCACHE_EXEC=/usr/bin/ccache
# export CCACHE_DIR=$PWD/out/.ccache
# ccache -M 50G
# ccache -o compression=true
# mkdir -p ~/Code/$ROM
# cd ~/Code/$ROM

rm -rf .repo/local_manifests
rm -rf device/xiaomi/gale
rm -rf vendor/xiaomi/gale
rm -rf kernel/xiaomi/gale
rm -rf device/mediatek/sepolicy_vndr
rm -rf hardware/xiaomi
rm -rf hardware/mediatek
rm -rf vendor/mediatek/ims/
rm -rf vendor/lineage-priv/keys
rm -rf device/cipher/sepolicy

repo init -u "$MANIFEST_URL" -b "$BRANCH" --git-lfs --depth=1
mkdir -p .repo/local_manifests/
wget -O .repo/local_manifests/roomservice_gale.xml https://raw.githubusercontent.com/kagiyanagi/local_manifests/refs/heads/bliss/roomservice_gale.xml
/opt/crave/resync.sh
# repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags --optimized-fetch --retry-fetches=25 --prune

# fix android_device_mediatek_sepolicy_vndr
git clone https://github.com/CipherOS/android_device_cipher_sepolicy -b sixteen device/cipher/sepolicy
sed -i "4s|include device/lineage/sepolicy/libperfmgr/sepolicy.mk|include device/${ROM}/sepolicy/libperfmgr/sepolicy.mk|" device/mediatek/sepolicy_vndr/SEPolicy.mk
if [ ! -d "device/${ROM}/sepolicy/libperfmgr" ]; then
    echo "libperfmgr not found. Cloning and copying..."

    TMP_DIR="$(pwd)/tmp_sepolicy_clone"
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    git clone https://github.com/LineageOS/android_device_lineage_sepolicy -b lineage-23.0 "$TMP_DIR"
    mv "$TMP_DIR/libperfmgr" "device/${ROM}/sepolicy/"
    rm -rf "$TMP_DIR"
    echo "libperfmgr moved successfully."
    sed -i "2s|^[[:space:]]*device/lineage/sepolicy/libperfmgr/vendor$|    device/${ROM}/sepolicy/libperfmgr/vendor|" "device/${ROM}/sepolicy/libperfmgr/sepolicy.mk"
else
    echo "device/${ROM}/sepolicy/libperfmgr already exists. Skipping."
fi


cd device/xiaomi/gale

mv "yaap.dependencies" "${ROM}.dependencies"
mv "yaap_gale.mk" "${ROM}_gale.mk"

sed -i "s/yaap_gale.mk/${ROM}_gale.mk/g" AndroidProducts.mk
sed -i "s|vendor/yaap|vendor/${ROM}|g" BoardConfig.mk
sed -i "s|vendor/yaap|vendor/${ROM}|g" "${ROM}_gale.mk"
sed -i "s/yaap_gale/${ROM}_gale/g" "${ROM}_gale.mk"

cd ../../../

sed -i '/"libbase_shim"/d' vendor/xiaomi/gale/Android.bp
sed -i 's/system_ext_specific: true/vendor: true/g' hardware/mediatek/PowerOffAlarm/Android.bp
sed -i 's/name: "libudfps_extension.xiaomi",/name: "libudfps_extension.xiaomi",\n    vendor: true,/g' hardware/xiaomi/fingerprint/Android.bp

source build/envsetup.sh
# $(find "$(gettop)/build/release/aconfig" -maxdepth 1 -mindepth 1 -type d -name "[a-z][a-z][0-9][a-z]" -printf '%f\n' | tail -n1)
lunch ${ROM}_gale-bp2a-userdebug
make installclean
m bacon -j$(nproc --all)
