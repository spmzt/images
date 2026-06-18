#!/usr/bin/env sh
set -euo pipefail

: "${BASE_TYPE:=notoolchain}"
: "${ARCH:=$(uname -p)}"
: "${OS_VER:=$(uname -r)}"
: "${OCI_LABEL:=$(date -I)}"
: "${REGISTRY:=ghcr.io}"
: "${USERNAME:=spmzt}"
: "${BUDFLAGS:="--network=host --layers"}"

OS=$(uname -o)
OCI_IMAGE="${OS}-${OS_VER}-${ARCH}-container-image-${BASE_TYPE}.txz"
OCI_IMAGE_URL="https://download.freebsd.org/snapshots/OCI-IMAGES/${OS_VER}/${ARCH}/Latest/${OCI_IMAGE}"
IMAGE_PREFIX=${REGISTRY}/${USERNAME}/freebsd


trap_exit()
{
}

trap trap_exit EXIT

fetch_base()
{
	printf "Download Latest FreeBSD OCI Image (%s)\n" ${BASE_TYPE}
	if [ ! -s "${OCI_IMAGE}" ]; then
		fetch ${OCI_IMAGE_URL}
	else
		printf "%s: exists!\n" "${OCI_IMAGE}"
	fi
}

install_depends()
{
	printf "Install System Dependencies\n"
	pkg install -y podman-suite
}

build_base_image()
{
	local base_image

	base_image=$(podman load --input ${OCI_IMAGE} | sed -e 's/Loaded image: //g')
	buildah tag ${base_image} ${IMAGE_PREFIX}-base:${OCI_LABEL}
	buildah tag ${base_image} ${IMAGE_PREFIX}-base:latest
}

pull_oci_image()
{
	local image_tag

	# Pull it first for cache
	for img in $1;
	do
		image_tag=${IMAGE_PREFIX}-${img}
		buildah pull $image_tag
	done
}


build_oci_image()
{
	local image_tag

	# Pull it first for cache
	for img in $1;
	do
		image_tag=${IMAGE_PREFIX}-${img}
		buildah build -f ${img}/Containerfile ${BUDFLAGS} \
		    -t ${image_tag}:latest -t ${image_tag}:${OCI_LABEL}
		buildah push ${image_tag}:${OCI_LABEL} ${image_tag}:latest
	done
}

main()
{
	local dflag iflag tflag mflag pflag

	dflag=false
	iflag=false
	tflag=false
	mflag=false
	pflag=false

	while getopts "dipt:m:" flag
	do
		case $flag in
		d) dflag=true ;;
		i) iflag=true ;;
		p) pflag=true ;;
		t)
			tflag=true
			OCI_LABEL="$OPTARG"
			;;
		m)
			mflag=true
			IMAGE="$OPTARG"
			;;
		\?)
			printf "Usage: %s: [-dip] [-t tag] [-m image]\n" $0
			printf "\t-d: Download base image first\n"
			printf "\t-i: Install dependencies\n"
			printf "\t-p: Pull images first\n"
			exit 2
			;;
		:)
			printf "Option -%s requires an argument.\n" $OPTARG
			exit 2
		esac
	done
	shift $(($OPTIND - 1))

	if [ "$dflag" = true ]; then
		fetch_base
	fi
	if [ "$iflag" = true ]; then
		install_depends
	fi

	build_base_image
	if [ "$mflag" = false ]; then
		IMAGE=$(find . -name 'Containerfile' -printf '%h\n' | sed -e 's/\.\///g')
	fi

	if [ "$pflag" = true ]; then
		pull_oci_image $IMAGE
	fi
	build_oci_image $IMAGE
}

main "$@"
