deviceTypesCommon = require '@resin.io/device-types/common'
{ networkOptions, commonImg, instructions } = deviceTypesCommon

module.exports =
	version: 1
	slug: 'generic-amd64'
	name: 'Generic AMD64 (x86-64)'
	arch: 'amd64'
	state: 'new'

	instructions: commonImg.instructions
	gettingStartedLink:
		windows: 'https://www.balena.io/docs/learn/getting-started/generic-amd64/nodejs/'
		osx: 'https://www.balena.io/docs/learn/getting-started/generic-amd64/nodejs/'
		linux: 'https://www.balena.io/docs/learn/getting-started/generic-amd64/nodejs/'
	supportsBlink: false

	yocto:
		machine: 'generic-amd64'
		image: 'balena-image'
		fstype: 'balenaos-img'
		version: 'yocto-dunfell'
		deployArtifact: 'balena-image-generic-amd64.balenaos-img'
		compressed: true

	configuration:
		config:
			partition:
				primary: 1
			path: '/config.json'

	initialization: commonImg.initialization
