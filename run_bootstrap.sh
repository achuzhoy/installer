#!/usr/bin/env sh
set -euo pipefail

OPENSHIFT_INSTALLER_IMAGE=docker.io/eranco/mcd:latest
podman_run() {
    echo "${@}"
    nsenter -t 1 -m -- podman run --net=host "${@}"
}

nsenter -t 1 -m -- mkdir -p /etc/install-dir
echo "Get bootstrap.ign"
nsenter -t 1 -m -- curl -s $S3_URL/$BUCKET/$CLUSTER_ID/bootstrap.ign -o /etc/install-dir/bootstrap.ign

echo "Writing bootstrap ignition to disk"
podman_run \
        --volume "/:/rootfs:rw" \
        --privileged \
        --entrypoint /machine-config-daemon \
        "${OPENSHIFT_INSTALLER_IMAGE}" \
        start --node-name localhost --root-mount /rootfs --once-from /etc/install-dir/bootstrap.ign --skip-reboot

echo "Starting bootkube.service"
nsenter -t 1 -m -- systemctl start bootkube.service
echo "Starting approve-csr.service"
nsenter -t 1 -m -- systemctl start approve-csr.service
echo "Starting progress.service"
nsenter -t 1 -m -- systemctl start progress.service

echo Done
