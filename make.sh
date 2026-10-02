#!/usr/bin/env sh
set -euo pipefail

: "${BASE_TYPE:=notoolchain}"
: "${ARCH:=$(uname -p)}"
: "${OS_VER:=$(uname -r)}"
: "${OCI_LABEL:=$(date -I)}"
: "${REGISTRY:=ghcr.io}"
: "${USERNAME:=spmzt}"
: "${BUDFLAGS:="--network=host --layers"}"
# Directory on the build host shared as /var/cache/pkg by every build
: "${PKG_CACHE:=}"

OS=$(uname -o)
OCI_IMAGE="${OS}-${OS_VER}-${ARCH}-container-image-${BASE_TYPE}.txz"
OCI_IMAGE_URL="https://download.freebsd.org/snapshots/OCI-IMAGES/${OS_VER}/${ARCH}/Latest/${OCI_IMAGE}"
IMAGE_PREFIX=${REGISTRY}/${USERNAME}/freebsd

fetch_base()
{
	printf "Download Latest FreeBSD OCI Image (%s)\n" ${BASE_TYPE}
	# Mirror mode: only re-download when the snapshot has changed
	fetch -m ${OCI_IMAGE_URL}
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
	buildah push ${IMAGE_PREFIX}-base:${OCI_LABEL}
	buildah push ${IMAGE_PREFIX}-base:latest
}

pull_oci_image()
{
	local image_tag

	# Pull it first for cache
	for img in $1;
	do
		image_tag=${IMAGE_PREFIX}-${img}
		printf "Pull: %s\n" $image_tag
		buildah pull $image_tag
	done
}


build_oci_image()
{
	local image_tag failed

	if [ -n "$PKG_CACHE" ]; then
		mkdir -p "$PKG_CACHE"
		BUDFLAGS="${BUDFLAGS} -v $(realpath "$PKG_CACHE"):/var/cache/pkg"
	fi

	failed=""
	for img in $1;
	do
		image_tag=${IMAGE_PREFIX}-${img}
		printf "Build: %s\n" $image_tag
		if buildah build -f ${img}/Containerfile ${BUDFLAGS} \
		    -t ${image_tag}:latest -t ${image_tag}:${OCI_LABEL} &&
		    buildah push ${image_tag}:${OCI_LABEL} &&
		    buildah push ${image_tag}:latest; then
			continue
		fi

		printf "Failed: %s\n" $image_tag >&2
		# Every other image is built on top of baseutils or devel
		case "$img" in
		baseutils|devel) return 1 ;;
		esac
		failed="${failed} ${img}"
	done

	if [ -n "$failed" ]; then
		printf "Failed images:%s\n" "$failed" >&2
		return 1
	fi
}

main()
{
	local bflag dflag iflag mflag pflag

	IMAGE=""
	bflag=true
	dflag=false
	iflag=false
	mflag=false
	pflag=false

	while getopts "Bdipt:m:" flag
	do
		case $flag in
		B) bflag=false ;;
		d) dflag=true ;;
		i) iflag=true ;;
		p) pflag=true ;;
		t) OCI_LABEL="$OPTARG" ;;
		m)
			mflag=true
			IMAGE="${IMAGE:+${IMAGE} }$OPTARG"
			;;
		\?)
			printf "Usage: %s: [-Bdip] [-t tag] [-m image]\n" $0
			printf "\t-B: Skip loading and pushing the base image\n"
			printf "\t-d: Download base image first\n"
			printf "\t-i: Install dependencies\n"
			printf "\t-p: Pull images first\n"
			printf "\t-t: Tag to push alongside latest (default: today)\n"
			printf "\t-m: Images to build, space-separated or repeated (default: all)\n"
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

	if [ "$bflag" = true ]; then
		build_base_image
	fi
	if [ "$mflag" = false ]; then
		# baseutils and devel first: every other image is built on them
		IMAGE="baseutils devel $(find . -mindepth 2 -maxdepth 2 \
		    -name Containerfile ! -path './baseutils/*' \
		    ! -path './devel/*' | cut -d/ -f2 | sort)"
	fi

	if [ "$pflag" = true ]; then
		pull_oci_image "$IMAGE"
	fi
	build_oci_image "$IMAGE"
}

main "$@"
