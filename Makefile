

start_bootstrap:
	sudo virt-install --name bootstrap --memory 6000 --vcpus 2  --network=network:eran-jcr2x,mac=52:54:00:EE:42:E1  --cdrom /home/eran/Downloads/fedora-eran-31.20200322.dev.1-live.x86_64.iso --disk pool=default,size=10 --os-type=linux --os-variant=generic --noautoconsole --events on_poweroff=preserve

start_master:
	sudo virt-install --name master0 --memory 6000 --vcpus 2  --network=network:eran-jcr2x,mac=52:54:00:D6:A8:ED  --cdrom /home/eran/Downloads/fedora-eran-31.20200322.dev.1-live.x86_64.iso --disk pool=default,size=10 --os-type=linux --os-variant=generic --noautoconsole --events on_poweroff=preserve

bootkube:
	ssh -o StrictHostKeyChecking=no core@192.168.126.10 mkdir -p ./install-dir
	scp -o StrictHostKeyChecking=no install-config.yaml core@192.168.126.10:install-dir/
	scp -o StrictHostKeyChecking=no bootstrap.sh   core@192.168.126.10:
	ssh -o StrictHostKeyChecking=no core@192.168.126.10 sudo ./bootstrap.sh
	ssh -o StrictHostKeyChecking=no core@192.168.126.10 sudo systemctl start bootkube.service

master_ign:
	ssh core@192.168.126.10 "sudo cat ~/install-dir/master.ign" > ./master.ign

install_master:
	scp -o StrictHostKeyChecking=no ./master.ign   core@192.168.126.11:
	ssh -o StrictHostKeyChecking=no core@192.168.126.11 "sudo coreos-installer install --image-url https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.3/latest/rhcos-4.3.0-x86_64-metal.raw.gz --insecure -i /var/home/core/master.ign /dev/sda"
