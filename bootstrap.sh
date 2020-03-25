#!/usr/bin/env bash
set -euoE pipefail ## -E option will cause functions to inherit trap

OPENSHIFT_INSTALLER_IMAGE=docker.io/eranco/openshift-installer:ignition
podman_run() {
    echo "${@}"
    podman run --net=host "${@}"
}

echo "Generating ignition configs"

podman_run \
        --volume "$PWD/install-dir:/install-dir:Z" \
        --env OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=quay.io/openshift-release-dev/ocp-release:4.4.0-rc.4-x86_64 \
        "${OPENSHIFT_INSTALLER_IMAGE}" \
        create ignition-configs \
        --dir=/install-dir


echo "Extracting machine-config-daemon"
podman_run \
        --volume "$PWD/install-dir:/install-dir:Z" \
        --entrypoint cp \
        "${OPENSHIFT_INSTALLER_IMAGE}" \
        /machine-config-daemon /install-dir/

echo "Writing bootstrap ignition to disk"
./install-dir/machine-config-daemon start --node-name $(hostname) --root-mount / --once-from $(pwd)/install-dir/bootstrap.ign --skip-reboot
