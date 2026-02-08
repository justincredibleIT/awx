# 00-bootstrap

This layer prepares OS + installs k3s across 6 nodes:
- servers: 01-03
- agents:  04-06

Run:
  cd ansible
  ansible-playbook -i ../hosts.ini playbooks/00-os-prep.yml
  ansible-playbook -i ../hosts.ini playbooks/01-k3s-install.yml

After install, kubeconfig will be copied to:
  ~/.kube/config (on the machine you run Ansible from)
