FILESEXTRAPATHS_prepend := "${THISDIR}/grub-efi:"

SRC_URI += " \
    file://pass-secure-boot.patch \
    "

DEPENDS_append = " ca-certificates-native coreutils-native curl-native jq-native"

GRUB_BUILDIN += " gcry_sha256 gcry_sha512 gcry_rijndael gcry_rsa luks"

do_configure_append_class-target() {
    if [ "x${SIGN_API}" = "x" ]; then
        return 0
    fi

    export CURL_CA_BUNDLE="${STAGING_DIR_NATIVE}/etc/ssl/certs/ca-certificates.crt"

    # Get public key for mkimage
    RESPONSE_FILE=$(mktemp)
    PUBKEY_FILE="${B}/pubkey.gpg"
    curl --fail "${SIGN_API}/gpg/key/${SIGN_GRUB_KEY_ID}" > "${RESPONSE_FILE}"
    jq -r ".key" < "${RESPONSE_FILE}" | gpg --dearmor > "${PUBKEY_FILE}"
    rm -f "${RESPONSE_FILE}"
}

do_mkimage() {
    cd ${B}

    if [ "x${SIGN_API}" != "x" ]; then
        GRUB_PUBKEY_ARG="--pubkey "${B}/pubkey.gpg""
    fi

    # Search for the grub.cfg on the local boot media by using the
    # built in cfg file provided via this recipe
    grub-mkimage -c ../cfg -p ${EFIDIR} -d ./grub-core/ \
           -O ${GRUB_TARGET}-efi -o ./${GRUB_IMAGE_PREFIX}${GRUB_IMAGE} \
           ${GRUB_BUILDIN} ${GRUB_PUBKEY_ARG}
}

do_sign_efi() {
    if [ "x${SIGN_API}" = "x" ]; then
        return 0
    fi

    export CURL_CA_BUNDLE="${STAGING_DIR_NATIVE}/etc/ssl/certs/ca-certificates.crt"

    EFI_APP="${B}/${GRUB_IMAGE_PREFIX}${GRUB_IMAGE}"
    REQUEST_FILE=$(mktemp)
    RESPONSE_FILE=$(mktemp)
    echo "{\"key_id\": \"${SIGN_EFI_KEY_ID}\", \"payload\": \"$(base64 -w 0 ${EFI_APP})\"}" > "${REQUEST_FILE}"
    curl --fail "${SIGN_API}/secureboot/efi" -X POST -H "Content-Type: application/json" -H "X-API-Key: ${SIGN_API_KEY}" -d "@${REQUEST_FILE}" > "${RESPONSE_FILE}"
    jq -r .signed < "${RESPONSE_FILE}" | base64 -d > "${EFI_APP}.signed"
    rm -f "${REQUEST_FILE}" "${RESPONSE_FILE}"

    mv "${EFI_APP}.signed" "${EFI_APP}"
}

do_sign_efi_class-native() {
    :
}

addtask sign_efi after do_mkimage before do_install
