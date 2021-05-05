deviceTypesCommon = require '@resin.io/device-types/common'
{ networkOptions, commonImg, instructions } = deviceTypesCommon

GENERIC_FLASH = '''
    Please make sure you do not have any other USB keys inserted.
    Power up the hardware. Make sure you have a keyboard connected.
    Press the F10 key (may differ on some platforms) while BIOS is loading in order to enter the boot menu.
    Next, select the name of your USB key.
'''

GENERIC_POWERON = 'Power on your device.'

postProvisioningInstructions = [
    instructions.BOARD_SHUTDOWN
    instructions.REMOVE_INSTALL_MEDIA
    GENERIC_POWERON
]

module.exports =
	version: 1
	slug: 'generic-amd64-fde'
	name: 'Generic AMD64 (x86-64) with FDE'
	arch: 'amd64'
	state: 'experimental'

	instructions: [
		instructions.ETCHER_USB
		instructions.EJECT_USB
		instructions.FLASHER_WARNING
		GENERIC_FLASH
	].concat(postProvisioningInstructions)

	gettingStartedLink:
		windows: 'https://www.balena.io/docs/learn/getting-started/generic-amd64-fde/nodejs/#add-your-first-device'
		osx: 'https://www.balena.io/docs/learn/getting-started/generic-amd64-fde/nodejs/#add-your-first-device'
		linux: 'https://www.balena.io/docs/learn/getting-started/generic-amd64-fde/nodejs/#add-your-first-device'

	supportsBlink: false

	yocto:
		machine: 'generic-amd64-fde'
		image: 'balena-image-flasher'
		fstype: 'balenaos-img'
		version: 'yocto-dunfell'
		deployArtifact: 'balena-image-flasher-generic-amd64-fde.balenaos-img'

	configuration:
		config:
			partition:
				primary: 1
			path: '/config.json'

	initialization: commonImg.initialization
