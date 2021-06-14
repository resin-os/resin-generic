FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = " \
    file://cryptsetup \
    "

do_install_append() {
    install -m 0755 ${WORKDIR}/cryptsetup ${D}/init.d/72-cryptsetup
}

PACKAGES_append = " \
    initramfs-module-cryptsetup \
    "

SUMMARY_initramfs-module-cryptsetup = "Unlock encrypted partitions"
RDEPENDS_initramfs-module-cryptsetup = " \
    ${PN}-base \
    cryptsetup \
    libtss2-tcti-device \
    lvm2-udevrules \
    os-helpers-logging \
    tpm2-tools \
"
FILES_initramfs-module-cryptsetup = "/init.d/72-cryptsetup"
