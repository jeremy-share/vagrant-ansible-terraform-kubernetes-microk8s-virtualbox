KUBECTL_CONFIG=--kubeconfig kubeconfig.yml
REMOTE_HOSTNAME="test-microk8s"
SSH_OPTIONS=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

# === RUN ==================================================================
up:
	make vagrant-up
	echo "INFO: Waiting for VM to restart"
	sleep 90
	make vm-k8-config-download
	make tf-init
	make tf-apply-yes

down:
	make vagrant-down

cleanup:
	make vagrant-down || true
	make tf-reset || true
	make k8-reset || true

up-clean:
	make cleanup
	make up

# === VAGRANT ===============================================================
vagrant-init:
	# https://app.vagrantup.com/ubuntu/boxes/focal64
	vagrant init ubuntu/focal64

vagrant-up:
	vagrant up

vagrant-re-provision:
	vagrant up --provision

vagrant-down:
	vagrant destroy --force

vagrant-ssh:
	vagrant ssh

# === ANSIBLE ===============================================================
ansible-run:
	make vagrant-re-provision

ansible-lint:
	ansible-lint ansible-playbook.yml

# === VIRTUAL MACHINE =======================================================
vm-check:
	ssh $(SSH_OPTIONS) $(REMOTE_HOSTNAME) "sudo whoami"

vm-ssh:
	ssh $(SSH_OPTIONS) $(REMOTE_HOSTNAME)

# === K8 Checks ===
vm-k8-check:
	ssh $(SSH_OPTIONS) $(REMOTE_HOSTNAME) "microk8s status --wait-ready"

vm-k8-get-all:
	ssh $(SSH_OPTIONS) $(REMOTE_HOSTNAME) "microk8s kubectl get all --all-namespaces"

# === CONFIG DOWNLOAD and test ===
# Note: The 'server' address is sometimes wrong
vm-k8-config-download:
	ssh $(SSH_OPTIONS) $(REMOTE_HOSTNAME) "sudo microk8s config" > kubeconfig.yml
	# yq -yi ".clusters[].cluster.server |= \"https://$(REMOTE_HOSTNAME):16443\"" kubeconfig.yml
	yq -yi ".clusters[].cluster.server |= \"https://`gethostip -d $(REMOTE_HOSTNAME)`:16443\"" kubeconfig.yml

# === KUBERNETES ============================================================

k8-reset:
	rm kubeconfig.yml

k8-get-all:
	kubectl $(KUBECTL_CONFIG) get all --all-namespaces

# === DASHBOARD ===
k8-get-dashboard-token:
# Note: You can also get this from the kubeconfig.yml
# kubectl $(KUBECTL_CONFIG) -n kube-system describe secret $$(kubectl $(KUBECTL_CONFIG) -n kube-system get secret | grep default-token | cut -d " " -f1) | grep "token:"
	cat kubeconfig.yml | yq -r ".users[] | select(.name == \"admin\") | .user.token"

k8-dashboard-remote-forward:
	kubectl $(KUBECTL_CONFIG) port-forward -n kube-system service/kubernetes-dashboard 10443:443 --address 0.0.0.0

# === kubectl test commands ===
k8-show-ingress-pods:
	kubectl $(KUBECTL_CONFIG) get pods -n ingress

k8-get-pods:
	kubectl $(KUBECTL_CONFIG) get pods -A

k8-get-services:
	kubectl $(KUBECTL_CONFIG) get services --all-namespaces

k8-get-namespaces:
	kubectl $(KUBECTL_CONFIG) get namespaces

# === TERRAFORM =============================================================

tf-reset:
	rm .terraform -rf
	rm .terraform.lock.hcl -rf
	rm terraform.tfstate -rf
	rm terraform.tfstate.backup -rf

tf-init:
	terraform init

tf-plan:
	terraform plan

tf-apply:
	terraform apply

tf-apply-yes:
	terraform apply -auto-approve

# === DEBUG =================================================================

debug-pod:
	kubectl $(KUBECTL_CONFIG) -n default describe pod terraform-example

debug-pod-shell:
	kubectl $(KUBECTL_CONFIG) -n default exec --stdin --tty terraform-example -- /bin/bash

debug-pod-logs:
	kubectl $(KUBECTL_CONFIG) -n default logs terraform-example

debug-ingress:
	kubectl $(KUBECTL_CONFIG) -n default describe ingress example_ingress

#
#debug-i
#
#kubectl --kubeconfig kubeconfig.yml logs -n default example-ingress