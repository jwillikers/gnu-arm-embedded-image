#!/usr/bin/env bash
set -o errexit

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Generate a container image for the GNU Arm Embedded toolchain with Buildah."
   echo
   echo "Syntax: gnu-arm-embedded-image.sh [-a|h]"
   echo "options:"
   echo "a     Build for the specified target architecture, i.e. amd64, arm, arm64."
   echo "h     Print this Help."
   echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Set variables
ARCHITECTURE="$(podman info --format={{".Host.Arch"}})"

############################################################
# Process the input options. Add options as needed.        #
############################################################
while getopts ":a:h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      a) # Enter a target architecture
         ARCHITECTURE=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

CONTAINER=$(buildah from --arch "$ARCHITECTURE" registry.fedoraproject.org/fedora-minimal:latest)
IMAGE="gnu-arm-embedded"

buildah run "$CONTAINER" /bin/sh -c 'microdnf install -y clang-tools-extra cmake arm-none-eabi-binutils-cs arm-none-eabi-gcc-cs arm-none-eabi-gcc-cs-c++ arm-none-eabi-newlib ninja-build python3 python3-pip python3-wheel python-unversioned-command --nodocs --setopt install_weak_deps=0'

buildah run "$CONTAINER" /bin/sh -c 'microdnf clean all -y'

buildah run "$CONTAINER" /bin/sh -c 'python -m pip install conan'

buildah run "$CONTAINER" /bin/sh -c 'python -m pip install cmakelang[yaml]'

buildah run "$CONTAINER" /bin/sh -c 'python -m pip cache purge'

buildah run "$CONTAINER" /bin/sh -c 'useradd -ms /bin/bash user'

buildah config --user user "$CONTAINER"

buildah config --workingdir /home/user "$CONTAINER"

buildah config --label "io.containers.autoupdate=registry" "$CONTAINER"

buildah config --author "jordan@jwillikers.com" "$CONTAINER"

buildah commit "$CONTAINER" "$IMAGE"

buildah rm "$CONTAINER"
