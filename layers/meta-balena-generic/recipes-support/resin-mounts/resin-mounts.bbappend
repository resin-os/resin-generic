FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
	file://balena-efi.service \
	"

SYSTEMD_SERVICE_${PN} += " \
	balena-efi.service \
	"
