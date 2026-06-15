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

build_oci_image()
{
	local image_tag images

	# Here
	if [ "$#" = 0 ]; then
		images=$(find . -name 'Containerfile' -printf '%h\n' | sed -e 's/\.\///g')
	else
		images="$1"
	fi
	for img in ${images};
	do
		image_tag=${IMAGE_PREFIX}-${img}
		buildah build -f ${img}/Containerfile ${BUDFLAGS} \
		    -t ${image_tag}:latest -t ${image_tag}:${OCI_LABEL}
		buildah push ${image_tag}:${OCI_LABEL} ${image_tag}:latest
	done
}

main()
{
	local dflag iflag tflag mflag

	dflag=false
	iflag=false
	tflag=false
	mflag=false

	while getopts "dit:m:" flag
	do
		case $flag in
		d) dflag=true ;;
		i) iflag=true ;;
		t)
			tflag=true
			OCI_LABEL="$OPTARG"
			;;
		m)
			mflag=true
			IMAGE="$OPTARG"
			;;
		\?)
			printf "Usage: %s: [-di] [-t tag] [-m image]\n" $0
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
	if [ "$mflag" = true ]; then
		build_oci_image $IMAGE
	else
		build_oci_image
	fi
}

main "$@"
