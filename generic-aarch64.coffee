deviceTypesCommon = require '@resin.io/device-types/common'
{ networkOptions, commonImg, instructions } = deviceTypesCommon

DOCKER_IMAGE = 'Download/pull the following docker image on the target machine: <code>{{ dockerImage }}</code> .'
DOWNLOAD_CONFIG = 'Download the configuration file and deploy it on target.'
RUN_CONTAINER = 'Run the resinOS container using <a href="https://github.com/resin-os/resinos-in-container">resinos-in-container</a>. This tool/script will reference the image and the configuration file (downloaded above) as command line arguments. Example: <code>./resinos-in-container.sh --config ./config.json --image {{ dockerImage }}</code>. Tweak the <code>--config</code> argument based on the filename set for the downloaded configuration file.'

module.exports =
	version: 1
	slug: 'generic-aarch64'
	name: 'Generic AARCH64 (ARMv8)'
	arch: 'aarch64'
	state: 'experimental'

	instructions: [
		DOCKER_IMAGE
		DOWNLOAD_CONFIG
		RUN_CONTAINER
	]

	gettingStartedLink:
		windows: 'https://docs.resin.io/learn/getting-started/generic-aarch64/nodejs/#add-your-first-device'
		osx: 'https://docs.resin.io/learn/getting-started/generic-aarch64/nodejs/#add-your-first-device'
		linux: 'https://docs.resin.io/learn/getting-started/generic-aarch64/nodejs/#add-your-first-device'

	supportsBlink: false

	yocto:
		machine: 'generic-aarch64'
		image: 'balena-image'
		fstype: 'balenaos-img'
		version: 'yocto-dunfell'
		deployArtifact: 'docker-image'

	configuration:
		config:
			partition:
				primary: 1
			path: '/config.json'

	initialization: commonImg.initialization
