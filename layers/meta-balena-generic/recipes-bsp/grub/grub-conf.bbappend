DEPENDS_append += " ca-certificates-native coreutils-native curl-native jq-native"

do_sign() {
    if [ "x${SIGN_API}" = "x" ]; then
        return 0
    fi

    # Sign grub configs
    TO_SIGN=$(mktemp)

    echo "${B}/grub.cfg_external" > "${TO_SIGN}"
    echo "${B}/grub.cfg_internal" >> "${TO_SIGN}"

    export CURL_CA_BUNDLE="${STAGING_DIR_NATIVE}/etc/ssl/certs/ca-certificates.crt"

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

do_deploy_append() {
    if [ "x${SIGN_API}" != "x" ]; then
        install -m 644 ${B}/grub.cfg_external.sig ${DEPLOYDIR}/grub.cfg_external.sig
        install -m 644 ${B}/grub.cfg_internal.sig ${DEPLOYDIR}/grub.cfg_internal.sig
    fi
}

addtask sign before do_install after do_compile
