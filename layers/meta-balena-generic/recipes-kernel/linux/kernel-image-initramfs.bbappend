do_install_append_generic-amd64-fde () {
    if [ "x${SIGN_API}" = "x" ]; then
        return 0
    fi

    for type in ${KERNEL_IMAGETYPE}; do
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${type}.sig ${D}/boot/${type}.sig
    done
}
