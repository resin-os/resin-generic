do_install_append () {
    if [ "x${SIGN_API}" = "x" ]; then
        return 0
    fi

    for type in ${KERNEL_IMAGETYPE}; do
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${type}.sig ${D}/boot/${type}.sig
    done
}
