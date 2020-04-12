#!/usr/bin/env sh
set -euo pipefail

echo "Create install-dir"
nsenter -t 1 -m -- mkdir -p /etc/install-dir
echo "Get $IGNITION_FILE"
nsenter -t 1 -m -- curl -s $S3_URL/$BUCKET/$CLUSTER_ID/$IGNITION_FILE -o /etc/install-dir/$IGNITION_FILE

echo "Writing image and ignition to disk"
nsenter -t 1 -m -- sudo coreos-installer install --image-url https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.4/latest/rhcos-4.4.0-rc.1-x86_64-metal.x86_64.raw.gz --insecure -i /etc/install-dir/$IGNITION_FILE $DEVICE
echo "Done"

echo "Rebooting node"
nsenter -t 1 -m -- sudo reboot
