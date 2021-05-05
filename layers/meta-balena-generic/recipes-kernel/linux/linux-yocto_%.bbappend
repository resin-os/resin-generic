inherit kernel-resin

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

DEPENDS_append = " ca-certificates-native coreutils-native curl-native jq-native"

SRC_URI += " \
    file://efi-secureboot.patch \
"

KCONFIG_MODE="--alldefconfig"
COMPATIBLE_MACHINE_generic-aarch64 = "generic-aarch64"
COMPATIBLE_MACHINE_generic-amd64 ?= "generic-amd64"
KBUILD_DEFCONFIG_generic-aarch64 ?= "defconfig"
KBUILD_DEFCONFIG_generic-amd64 ?= "x86_64_defconfig"

do_configure_append () {
    mkdir -p certs
    if [ "x${SIGN_API}" = "x" ]; then
        return 0
    fi

    export CURL_CA_BUNDLE="${STAGING_DIR_NATIVE}/etc/ssl/certs/ca-certificates.crt"

    RESPONSE_FILE=$(mktemp)
    curl --fail "${SIGN_API}/kmod/cert/${SIGN_KMOD_KEY_ID}" > "${RESPONSE_FILE}"
    jq -r .cert "${RESPONSE_FILE}" > certs/balenaos.crt
    rm -f "${RESPONSE_FILE}"
}

do_sign () {
    if [ "x${SIGN_API}" = "x" ]; then
        return 0
    fi

    export CURL_CA_BUNDLE="${STAGING_DIR_NATIVE}/etc/ssl/certs/ca-certificates.crt"

    TO_SIGN=$(mktemp)

    # Sign kernel for grub
    echo "${B}/${KERNEL_OUTPUT_DIR}/${KERNEL_IMAGETYPE}.initramfs" > "${TO_SIGN}"

    for FILE_TO_SIGN in $(cat "${TO_SIGN}")
    do
        REQUEST_FILE=$(mktemp)
        RESPONSE_FILE=$(mktemp)
        echo "{\"key_id\": \"${SIGN_GRUB_KEY_ID}\", \"payload\": \"$(base64 -w 0 ${FILE_TO_SIGN})\"}" > "${REQUEST_FILE}"
        curl --fail "${SIGN_API}/gpg/sign" -X POST -H "Content-Type: application/json" -H "X-API-Key: ${SIGN_API_KEY}" -d "@${REQUEST_FILE}" > "${RESPONSE_FILE}"
        jq -r .signature < "${RESPONSE_FILE}" | base64 -d > "${FILE_TO_SIGN}.sig"
        rm -f "${REQUEST_FILE}" "${RESPONSE_FILE}"
    done

    rm -f "${TO_SIGN}"
}

addtask sign before do_deploy after do_bundle_initramfs

do_deploy_append() {
    if [ "x${SIGN_API}" != "x" ]; then
        install -m 0644 ${B}/${KERNEL_OUTPUT_DIR}/${KERNEL_IMAGETYPE}.initramfs.sig ${DEPLOYDIR}/${KERNEL_IMAGETYPE}.sig
    fi
}

BALENA_CONFIGS_append = " efi"

BALENA_CONFIGS[efi] = " \
    CONFIG_EFI=y \
    CONFIG_EFIVAR_FS=y \
    CONFIG_ACPI=y \
    "

BALENA_CONFIGS_append = " serial"

BALENA_CONFIGS[serial] = " \
    CONFIG_SERIAL_8250=y \
    CONFIG_SERIAL_8250_CONSOLE=y \
    "

BALENA_CONFIGS_append = " virtio"

BALENA_CONFIGS[virtio] = " \
    CONFIG_VIRTIO=y \
    CONFIG_VIRTIO_PCI=y \
    CONFIG_SCSI_VIRTIO=y \
    CONFIG_VIRTIO_NET=y \
    CONFIG_VIRTIO_BLK=y \
    CONFIG_VIRTIO_BLK_SCSI=y \
    CONFIG_VIRTIO_CONSOLE=y \
    CONFIG_I6300ESB_WDT=m \
    "

BALENA_CONFIGS_append = " nvme"

BALENA_CONFIGS[nvme] = " \
    CONFIG_BLK_DEV_NVME=y \
    "

BALENA_CONFIGS_append = " aws"

BALENA_CONFIGS[aws] = " \
    CONFIG_ENA_ETHERNET=m \
    "

BALENA_CONFIGS_append = " secureboot"

BALENA_CONFIGS[secureboot] = " \
    CONFIG_LOCK_DOWN_IN_EFI_SECURE_BOOT=y \
    CONFIG_MODULE_SIG=y \
    CONFIG_MODULE_SIG_ALL=y \
    CONFIG_MODULE_SIG_FORCE=y \
    CONFIG_MODULE_SIG_SHA512=y \
    CONFIG_SECURITY_LOCKDOWN_LSM=y \
    CONFIG_SECURITY_LOCKDOWN_LSM_EARLY=y \
    CONFIG_SYSTEM_TRUSTED_KEYS="certs/balenaos.crt" \
"
