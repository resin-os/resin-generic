include balena-image.inc

BALENA_BOOT_PARTITION_FILES_append = " \
    grub.cfg_external:/EFI/BOOT/grub.cfg \
    grub.cfg_external.sig:/EFI/BOOT/grub.cfg.sig \
    grub.cfg_internal: \
    grub.cfg_internal.sig: \
    "