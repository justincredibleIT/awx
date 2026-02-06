#!/bin/bash

set -e

echo "[STEP 1] Updating system and installing dependencies..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

echo "[STEP 2] Setting up Docker GPG key and repo..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "[STEP 3] Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
echo "[STEP 4] Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[STEP 5] Installing K3s..."
curl -sfL https://get.k3s.io | sh -

echo "[STEP 6] Configuring kubectl access..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

echo "[STEP 7] Creating AWX namespace..."
kubectl create namespace awx || echo "Namespace 'awx' already exists."

echo "[STEP 9] Preparing AWX deployment with kustomize..."
mkdir -p ~/awx-deploy
cat <<EOF > ~/awx-deploy/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/ansible/awx-operator/config/default?ref=2.19.1
  - awx-server.yaml
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.19.1
namespace: awx
EOF

cat <<EOF > ~/awx-deploy/awx-server.yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-server
spec:
  service_type: nodeport
EOF

echo "[STEP 10] Deploying AWX..."
kubectl apply -k ~/awx-deploy

echo "[STEP 11] Setting default namespace to 'awx'..."
kubectl config set-context --current --namespace=awx

echo "[STEP 12] Waiting for AWX custom resource to exist..."
until kubectl -n awx get awx awx-server >/dev/null 2>&1; do
  echo "  Waiting for AWX CR awx-server to appear..."
  sleep 5
done

echo "[STEP 12.1] Waiting for AWX operator to start reconciling (web/task deployments to exist)..."
until kubectl -n awx get deploy awx-server-web >/dev/null 2>&1 && kubectl -n awx get deploy awx-server-task >/dev/null 2>&1; do
  echo "  Waiting for awx-server-web/task deployments..."
  sleep 5
done

echo "[STEP 12.2] Waiting for AWX web/task deployments to be Available..."
kubectl -n awx rollout status deploy/awx-server-web --timeout=600s
kubectl -n awx rollout status deploy/awx-server-task --timeout=600s

echo "[STEP 12.3] Waiting for admin password secret..."
until kubectl -n awx get secret awx-server-admin-password >/dev/null 2>&1; do
  echo "  Waiting for secret awx-server-admin-password..."
  sleep 5
done

echo "[STEP 13] AWX pods:"
kubectl get pods -n awx

echo "[STEP 14] AWX services:"
kubectl get svc -n awx

NODE_IP=$(ip -4 route get 1.1.1.1 | awk '{print $7}')
NODE_PORT=$(kubectl -n awx get svc awx-server-service \
  -o jsonpath='{.spec.ports[0].nodePort}')

AWX_URL="http://${NODE_IP}:${NODE_PORT}"

echo "[STEP 15] AWX admin password:"
kubectl get secret -n awx awx-server-admin-password \
  -o jsonpath="{.data.password}" | base64 --decode
echo

echo "[DONE] You can now access AWX at:"
echo "  ${AWX_URL}"
