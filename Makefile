
bootstrap=192.168.126.10
master0=192.168.126.11
master1=192.168.126.12
master2=192.168.126.13
SSH=ssh -o StrictHostKeyChecking=no core@
SCP=scp -o StrictHostKeyChecking=no

start_bootstrap:
	sudo virt-install --name bootstrap --memory 6000 --vcpus 2  --network=network:eran-jcr2x,mac=52:54:00:EE:42:E1  --cdrom /home/eran/Downloads/fedora-eran-31.20200322.dev.1-live.x86_64.iso --disk pool=default,size=10 --os-type=linux --os-variant=generic --noautoconsole --events on_poweroff=preserve

start_masters:
	sudo virt-install --name master0 --memory 6000 --vcpus 2  --network=network:eran-jcr2x,mac=52:54:00:D6:A8:ED  --cdrom /home/eran/Downloads/fedora-eran-31.20200322.dev.1-live.x86_64.iso --disk pool=default,size=10 --os-type=linux --os-variant=generic --noautoconsole --events on_poweroff=preserve
	sudo virt-install --name master1 --memory 6000 --vcpus 2  --network=network:eran-jcr2x,mac=52:54:00:D6:A8:EE  --cdrom /home/eran/Downloads/fedora-eran-31.20200322.dev.1-live.x86_64.iso --disk pool=default,size=10 --os-type=linux --os-variant=generic --noautoconsole --events on_poweroff=preserve
	sudo virt-install --name master2 --memory 6000 --vcpus 2  --network=network:eran-jcr2x,mac=52:54:00:D6:A8:EF  --cdrom /home/eran/Downloads/fedora-eran-31.20200322.dev.1-live.x86_64.iso --disk pool=default,size=10 --os-type=linux --os-variant=generic --noautoconsole --events on_poweroff=preserve

wait_for_ip:
	until ping -c1 $($(NAME)) >/dev/null 2>&1; do :; done

run_bootkube:
	$(SSH)$(bootstrap) mkdir -p ./install-dir
	$(SCP) install-config.yaml core@$(bootstrap):install-dir/
	$(SCP) bootstrap.sh   core@$(bootstrap):
	$(SSH)$(bootstrap) sudo ./bootstrap.sh
	$(SSH)$(bootstrap) sudo systemctl start bootkube.service
	$(SSH)$(bootstrap) sudo systemctl start approve-csr.service

master_ign:
	$(SSH)$(bootstrap) "sudo cat ~/install-dir/master.ign" > ./master.ign

install_master:
	$(SCP) ./master.ign   core@$($(NAME)):
	$(SSH)$($(NAME)) "sudo coreos-installer install --image-url https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.3/latest/rhcos-4.3.0-x86_64-metal.raw.gz --insecure -i /var/home/core/master.ign /dev/sda"

reboot:
	$(SSH)$($(NAME)) "sudo shutdown -r"
