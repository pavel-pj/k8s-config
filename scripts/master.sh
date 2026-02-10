# Запрашиваем имя ноды
sudo hostnamectl set-hostname master-k8s
read -p "Введите имя ноды (например node-01): " NODE_NAME

# Проверяем ввод
if [ -z "$NODE_NAME" ]; then
    echo "Ошибка: имя ноды не может быть пустым!"
    exit 1
fi

# Ищем и заменяем блок PS1 в .bashrc
sed -i "/if \[ \"\\\$color_prompt\" = yes \]; then/,/^fi$/c\
if [ \"\\\$color_prompt\" = yes ]; then\n\
    PS1='\\\${debian_chroot:+(\\\$debian_chroot)}\\\\\[\\\\033[01;32m\\\\]\\\\u@$NODE_NAME\\\\[\\\\033[00m\\\\]:\\\\[\\\\033[01;34m\\\\]\\\\w\\\\[\\\\033[00m\\\\]\\\\\$ '\n\
else\n\
    PS1='\\\${debian_chroot:+(\\\$debian_chroot)}\\\\\\\\u@$NODE_NAME:\\\\\\\\w\\\\\\\\\\\\\$ '\n\
fi" ~/.bashrc

# Применяем изменения
source ~/.bashrc
echo "Готово! Теперь приглашение: user@$NODE_NAME"

sudo apt update -y
sudo apt upgrade -y

sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
sudo swapoff -a

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

sudo apt-get install -y kubelet=1.35.0-* kubeadm=1.35.0-* kubectl=1.35.0-*

sudo kubeadm init \
--pod-network-cidr=10.244.0.0/16 \
--cri-socket=unix:///var/run/containerd/containerd.sock \
--ignore-preflight-errors=Port-6443 \
--upload-certs

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "export KUBECONFIG=$HOME/.kube/config" >> ~/.bashrc
source ~/.bashrc

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml


 