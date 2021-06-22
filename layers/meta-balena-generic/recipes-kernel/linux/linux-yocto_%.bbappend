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

#
# EHCI drivers
#
BALENA_CONFIGS_append = " ehci"
BALENA_CONFIGS[ehci] = " \
    CONFIG_USB_EHCI_HCD_PLATFORM=y \
    "

#
# Support for DLM module
#
BALENA_CONFIGS_append = " dlm"
BALENA_CONFIGS[dlm] = " \
    CONFIG_DLM=m \
    "

#
# Support for serial console and more than 4 serial ports
#
BALENA_CONFIGS_append = " serial_8250"
BALENA_CONFIGS[serial_8250] = " \
    CONFIG_SERIAL_8250=y \
    CONFIG_SERIAL_8250_CONSOLE=y \
    CONFIG_SERIAL_8250_NR_UARTS=32 \
    CONFIG_SERIAL_8250_RUNTIME_UARTS=32 \
    "

#
# Support Intel(R) 82575/82576 PCI-Express Gigabit Ethernet
#
BALENA_CONFIGS_append = " igb"
BALENA_CONFIGS_DEPS[igb] = " \
    CONFIG_PCI=m \
    "
BALENA_CONFIGS[igb] = " \
    CONFIG_IGB=m \
    "

# Support for RTL8723BE and RTL8821AE based WiFi/BT cards
BALENA_CONFIGS_append = " rtl8723be_rtl8821ae"
BALENA_CONFIGS_DEPS[rtl8723be_rtl8821ae] = " \
        CONFIG_RTL_CARDS=m \
"
BALENA_CONFIGS[rtl8723be_rtl8821ae] = " \
    CONFIG_RTL8723BE=m \
    CONFIG_RTL8821AE=m \
"

# Enable vxlan support (requested by customer)
BALENA_CONFIGS_append = " vxlan"
BALENA_CONFIGS[vxlan] = " \
    CONFIG_VXLAN=m \
"

# enable audio over HDMI (requested by customer for the Intel Compute Stick)
BALENA_CONFIGS_append = " hdmi_lpe_audio"
BALENA_CONFIGS[hdmi_lpe_audio] = " \
    CONFIG_HDMI_LPE_AUDIO=m \
"

BALENA_CONFIGS_append = " quectel_ec20"
BALENA_CONFIGS_DEPS[quectel_ec20] = "\
    CONFIG_USB_SERIAL_OPTION=m \
    CONFIG_USB_SERIAL_WWAN=m \
"
BALENA_CONFIGS[quectel_ec20] ="\
    CONFIG_USB_SERIAL_QUALCOMM=m \
"

BALENA_CONFIGS_append = " batman"
BALENA_CONFIGS[batman] = "\
    CONFIG_BATMAN_ADV=m \
    CONFIG_BATMAN_ADV_DAT=y \
    CONFIG_BATMAN_ADV_MCAST=y \
    CONFIG_BATMAN_ADV_DEBUGFS=y \
    CONFIG_BATMAN_ADV_DEBUG=y \
"

# Enable USB audio support
BALENA_CONFIGS_append = " usb_audio"
BALENA_CONFIGS[usb_audio]=" \
    CONFIG_SND_USB_AUDIO=m \
"

# Enable WiFi adapters that use Realtek chipset (like Edimax EW-7811Un)
BALENA_CONFIGS_append = " rtl_wifi"
BALENA_CONFIGS[rtl_wifi]=" \
    CONFIG_RTL8192CU=m \
"

# Add CAN support (requested by customer)
BALENA_CONFIGS_append = " enable_can"
BALENA_CONFIGS[enable_can] = " \
    CONFIG_CAN=m \
    CONFIG_CAN_DEV=m \
    CONFIG_CAN_RAW=m \
    CONFIG_CAN_SLCAN=m \
"

BALENA_CONFIGS_append = " huawei_modems"
BALENA_CONFIGS_DEPS[huawei_modems] = " \
    CONFIG_USB_SERIAL_OPTION=m \
    CONFIG_USB_USBNET=m \
"
BALENA_CONFIGS[huawei_modems] ="\
    CONFIG_USB_NET_HUAWEI_CDC_NCM=m \
"

BALENA_CONFIGS_append = " rndis"
BALENA_CONFIGS_DEPS[rndis] = " \
    CONFIG_USB_SERIAL_OPTION=m \
    CONFIG_USB_USBNET=m \
"
BALENA_CONFIGS[rndis] ="\
    CONFIG_USB_NET_RNDIS_HOST=m \
"

# requested by customer
BALENA_CONFIGS_append = " netfilter_time"
BALENA_CONFIGS[netfilter_time] = " \
    CONFIG_NETFILTER_XT_MATCH_TIME=m \
"

# requested by customer (support for Kontron PLD devices)
BALENA_CONFIGS_append = " gpio_i2c_kempld"
BALENA_CONFIGS_DEPS[gpio_i2c_kempld] = " \
    CONFIG_GPIOLIB=y \
    CONFIG_I2C=y \
    CONFIG_HAS_IOMEM=y \
    CONFIG_MFD_KEMPLD=m \
"
BALENA_CONFIGS[gpio_i2c_kempld] = " \
    CONFIG_GPIO_KEMPLD=m \
    CONFIG_I2C_KEMPLD=m \
"

# requested by customer
BALENA_CONFIGS_append = " snd_dyn_minors"
BALENA_CONFIGS[snd_dyn_minors] = " \
    CONFIG_SND_DYNAMIC_MINORS=y \
"

# requested by customer
BALENA_CONFIGS_append = " tulip"
BALENA_CONFIGS[tulip] = " \
    CONFIG_NET_TULIP=y \
    CONFIG_TULIP=m \
"

# requested by customer
BALENA_CONFIGS_append = " hyperv_net"
BALENA_CONFIGS_DEPS[hyperv_net] = " \
    CONFIG_HYPERV=y \
    CONFIG_HYPERVISOR_GUEST=y \
"
BALENA_CONFIGS[hyperv_net] = " \
    CONFIG_HYPERV_NET=m \
"

# requested by user
BALENA_CONFIGS_append = " temp_sensors"
BALENA_CONFIGS[temp_sensors] = " \
    CONFIG_SENSORS_CORETEMP=m \
    CONFIG_SENSORS_NCT6775=m \
"

# requested by user
BALENA_CONFIGS_append = " acpi_wmi"
BALENA_CONFIGS[acpi_wmi] = " \
    CONFIG_ACPI_WMI=m \
"

BALENA_CONFIGS_append = " mwifiex_pcie"
BALENA_CONFIGS[mwifiex_pcie] = " \
    CONFIG_MWIFIEX=m \
    CONFIG_MWIFIEX_PCIE=m \
"

BALENA_CONFIGS_append = " uinput"
BALENA_CONFIGS_DEPS[uinput] = " \
    CONFIG_INPUT_MISC=y \
"
BALENA_CONFIGS[uinput] = " \
    CONFIG_INPUT_UINPUT=m \
"

BALENA_CONFIGS_append = " ath10k_pci"
BALENA_CONFIGS_DEPS[ath10k_pci] = " \
    CONFIG_ATH10K=m \
"
BALENA_CONFIGS[ath10k_pci] = " \
    CONFIG_ATH10K_PCI=m \
"

BALENA_CONFIGS_append = " mmc_realtek_pci"
BALENA_CONFIGS_DEPS[mmc_realtek_pci] = " \
    CONFIG_MISC_RTSX_PCI=m \
"
BALENA_CONFIGS[mmc_realtek_pci] = " \
    CONFIG_MMC_REALTEK_PCI=m \
"

BALENA_CONFIGS_append = " tpm"
BALENA_CONFIGS_DEPS[tpm] = " \
    CONFIG_HW_RANDOM_TPM=y \
    CONFIG_SECURITYFS=y \
"
BALENA_CONFIGS[tpm] = " \
    CONFIG_TCG_TPM=m \
    CONFIG_TCG_TIS_CORE=m \
    CONFIG_TCG_TIS=m \
    CONFIG_TCG_CRB=m \
"

# enable the Intel TCO Watchdog
BALENA_CONFIGS_append = " watchdog"
BALENA_CONFIGS[watchdog] = " \
    CONFIG_ITCO_WDT=m \
"


#
# Do not include debugging info in kernel and modules
#
BALENA_CONFIGS_append = " no-debug-info"
BALENA_CONFIGS[no-debug-info] ?= " \
    CONFIG_DEBUG_INFO=n \
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

#
# Support Intel wrieless LAN adapter
#
BALENA_CONFIGS_append_generic-amd64 = " iwlwifi"
BALENA_CONFIGS_DEPS[iwlwifi] = " \
    CONFIG_PCI=m \
    CONFIG_MAC80211=m \
    CONFIG_HAS_IOMEM=m \
    "
BALENA_CONFIGS[iwlwifi] = " \
    CONFIG_IWLMVM=m \
    CONFIG_IWLDVM=m \
    CONFIG_IWLWIFI=m \
    "

#
# Support Intel NUC Bluetooth
#
BALENA_CONFIGS_append_generic-amd64 = " nuc_bluetooth"
BALENA_CONFIGS[nuc_bluetooth] = " \
    CONFIG_BT_HCIUART=m \
    CONFIG_BT_HCIUART_INTEL=y \
    CONFIG_BT_HCIBTUSB=m \
    "

# Enable Intel Low Power Subsystem Support
# (for detecting the eMMC on some Atom based Intel SoCs)
BALENA_CONFIGS_append_generic-amd64 = " lpss"
BALENA_CONFIGS[lpss] = " \
    CONFIG_X86_INTEL_LPSS=y \
"

# requested by user
BALENA_CONFIGS_append_generic-amd64 = " ad5593r"
BALENA_CONFIGS[ad5593r] = " \
    CONFIG_AD5593R=m \
"
BALENA_CONFIGS_DEPS[ad5593r] = " \
    CONFIG_IIO=m \
"

# set ATA_PIIX as built-in so we can boot legacy IDE mode without adding the ata_piix driver in the initramfs
# (some boards do not support AHCI mode)
BALENA_CONFIGS_append_generic-amd64 = " ata_piix"
BALENA_CONFIGS[ata_piix] = " \
    CONFIG_ATA_PIIX=y \
"

# requested by customer
BALENA_CONFIGS_append_generic-amd64 = " pinctrl_baytrail"
BALENA_CONFIGS[pinctrl_baytrail] = " \
    CONFIG_PINCTRL_BAYTRAIL=y \
"

# requested by user (this module was previously available but apparently got removed when we updated to warrior and a new kernel)
BALENA_CONFIGS_append_generic-amd64 = " ch341"
BALENA_CONFIGS[ch341] = " \
    CONFIG_USB_SERIAL_CH341=m \
"

BALENA_CONFIGS_append_generic-amd64 = " i2c_designware"
BALENA_CONFIGS[i2c_designware] = " \
    CONFIG_I2C_DESIGNWARE_PLATFORM=y \
    CONFIG_I2C_DESIGNWARE_PCI=y \
"

# requested by user for mounting HFS drives
BALENA_CONFIGS_append_generic-amd64 = " apple_hfs"
BALENA_CONFIGS[apple_hfs] = " \
    CONFIG_HFS_FS=m \
    CONFIG_HFSPLUS_FS=m \
"

# requested by customer
BALENA_CONFIGS_append_generic-amd64 = " ixgbe"
BALENA_CONFIGS[ixgbe] = " \
    CONFIG_IXGBE=m \
"

# requested by customer
BALENA_CONFIGS_append_generic-amd64 = " xillybus"
BALENA_CONFIGS[xillybus] = " \
    CONFIG_XILLYBUS=m \
    CONFIG_XILLYBUS_PCIE=m \
"

# requested by customer
BALENA_CONFIGS_append_generic-amd64 = " i40e"
BALENA_CONFIGS[i40e] = " \
    CONFIG_I40E=m \
"
