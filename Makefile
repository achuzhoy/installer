
bootstrap=192.168.126.10
master0=192.168.126.11
master1=192.168.126.12
master2=192.168.126.13
SSH=ssh -o StrictHostKeyChecking=no core@
SCP=scp -o StrictHostKeyChecking=no

all: create_bootstrap create_masters
	NAME=bootstrap make wait_for_ip
	sleep 10
	make run_bootkube
	make master_ign
	make install_masters

create_network:
	sudo virsh net-create --file net.xml

create_bootstrap:
	sudo virt-install --name bootstrap --memory 6000 --vcpus 2  --network=network:eran-net,mac=52:54:00:1a:ed:b7  --cdrom /home/eran/Downloads/fedora-eran-31.20200322.dev.1-live.x86_64.iso --disk pool=default,size=10 --os-type=linux --os-variant=generic --noautoconsole --events on_reboot=restart

create_masters:
	sudo virt-install --name master0 --memory 6000 --vcpus 2  --network=network:eran-net,mac=52:54:00:26:b0:b9  --cdrom /home/eran/Downloads/fedora-eran-31.20200322.dev.1-live.x86_64.iso --disk pool=default,size=10 --os-type=linux --os-variant=generic --noautoconsole --events on_reboot=restart
	sudo virt-install --name master1 --memory 6000 --vcpus 2  --network=network:eran-net,mac=52:54:00:26:b0:ba  --cdrom /home/eran/Downloads/fedora-eran-31.20200322.dev.1-live.x86_64.iso --disk pool=default,size=10 --os-type=linux --os-variant=generic --noautoconsole --events on_reboot=restart
	sudo virt-install --name master2 --memory 6000 --vcpus 2  --network=network:eran-net,mac=52:54:00:b2:14:74  --cdrom /home/eran/Downloads/fedora-eran-31.20200322.dev.1-live.x86_64.iso --disk pool=default,size=10 --os-type=linux --os-variant=generic --noautoconsole --events on_reboot=restart

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

install_masters:
	for i in 0 1 2; do \
	NAME=master$$i make install_master & \
	done

install_master:
	$(SCP) ./master.ign   core@$($(NAME)):
	$(SSH)$($(NAME)) "sudo coreos-installer install --image-url https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.4/latest/rhcos-4.4.0-rc.1-x86_64-metal.x86_64.raw.gz --insecure -i /var/home/core/master.ign /dev/sda"
	make reboot

reboot:
	$(SSH)$($(NAME)) "sudo reboot"

start_masters:
	for i in 0 1 2; do \
	sudo virsh start master$$i; \
	done

destroy: destroy_masaters destroy_bootstrap

destroy_masaters:
	for i in 0 1 2; do \
	sudo virsh destroy master$$i && \
	sudo virsh undefine master$$i && \
	 sudo virsh  vol-delete master$$i.qcow2 --pool default; \
	done

destroy_bootstrap:
	sudo virsh destroy bootstrap
	sudo virsh undefine bootstrap
	sudo virsh  vol-delete bootstrap.qcow2 --pool default

destroy_network:
	sudo virsh net-destroy eran-net
	sudo virsh net-undefine eran-net
