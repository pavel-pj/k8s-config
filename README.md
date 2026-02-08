# Развертывание кластера Kubernetes

## 1. ВСЕ НОДЫ кластера

### Инструкция:
https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

##### На всех нодах (master, worker) ОБЯЗАТЕЛЬНО выполнить.
#### 1. Отключение swap (обязательно для Kubernetes)
```bash
sudo swapoff -a
```
##### проверка :
```bash 
sudo swapon --show
```

#### 2. Настройка сетевого моста (если не настроен)
```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```
```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

#### 3. sysctl параметры
```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```
```bash
sudo sysctl --system
```


##### 4 : Добавление репозитория Kubernetes
```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

###### Добавление GPG ключа
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

##### Добавление репозитория
```bash 
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
```bash
sudo apt-get update
```

##### Шаг 4: Установка kubeadm, kubelet, kubectl
```bash
sudo apt-get install -y kubelet=1.35.0-* kubeadm=1.35.0-* kubectl=1.35.0-*
```

###### Проверка версий
```bash 
kubeadm version
kubectl version --client
kubelet --version
# Проверка, что kubelet запущен
sudo systemctl status kubelet
```

