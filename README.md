# Развертывание кластера Kubernetes

## 1. ВСЕ НОДЫ кластера

### Инструкция:
https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/


#### На докере требуются дополнительные настройки. Лучше контейнеризировать через containerd

##### установка containerd 
```bash
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```
##### Проверить
```bash
sudo systemctl status containerd
ls -la /var/run/containerd/containerd.sock
```


##### На всех нодах (master, worker) ОБЯЗАТЕЛЬНО выполнить.
#### Шаг 1.1: Отключение swap (обязательно для Kubernetes)
```bash
sudo swapoff -a
```
##### проверка :
```bash 
sudo swapon --show
```

#### Шаг 1.2: Настройка сетевого моста (если не настроен)
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

#### Шаг 1.3: sysctl параметры
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


#### Шаг 1.4: Добавление репозитория Kubernetes
```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

Добавление GPG ключа
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

###### Добавление репозитория
```bash 
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
```bash
sudo apt-get update
```


#### Шаг 1.5: Установка kubeadm, kubelet, kubectl
Версии могут быть ВЫШЕ, но у всех программ в этом шаге версия должна быть ОДИНАКОВАЯ
```bash
sudo apt-get install -y kubelet=1.35.0-* kubeadm=1.35.0-* kubectl=1.35.0-*
```

###### Проверка версий
```bash 
kubeadm version
kubectl version --client
kubelet --version
```
 
## 2. МАСТЕР нода
#### Шаг 2.1: Инициализация кластера (Flannel любит 10.244.0.0/16)
```bash
sudo kubeadm init \
--pod-network-cidr=10.244.0.0/16 \
--cri-socket=unix:///var/run/containerd/containerd.sock \
--ignore-preflight-errors=Port-6443 \
--upload-certs
```  
##### В результате в конце будет СОХРАНЯЕМ ТОКЕН в блокнот на host(Каждый раз выдача разная, ниже - пример): 
```bash
kubeadm join 85.239.53.102:6443 --token 3bwvyf.n7krgs7cpq62aalu \
--discovery-token-ca-cert-hash sha256:acf4df6056c7fa6f9de57bf1086b6565ef0a996b8752cadd6bf99f4526f1076c 
```
 

#### Шаг 2.2: Настройка kubectl
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "export KUBECONFIG=$HOME/.kube/config" >> ~/.bashrc
source ~/.bashrc
```
##### проверка : 
```bash
kubectl cluster-info
```


#### Шаг 2.3: Установка Flannel (самый простой способ)
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

###### Проверка Flannel
```bash
kubectl get pods -n kube-system -l app=flannel
```
 
#### ШАГ 2.4: проверяем запущенные компоненты

```bash
sudo crictl ps
```
#### Должны обязательно быть запущены в статусе 'Running' следующие сервисы:
- kube-scheduler 
- coredns
- coredns ( 2 экземпляра)
- kube-controller-manager
- kube-apiserver 
- etcd  
- kube-flannel
 
 
## 3. WORKER нода
##### Подключаемся к мастеру , выполняем сохраненную в шаге 2.1 команду
```bash
 kubeadm join 85.239.53.102:6443 --token 3bwvyf.n7krgs7cpq62aalu \
--discovery-token-ca-cert-hash sha256:acf4df6056c7fa6f9de57bf1086b6565ef0a996b8752cadd6bf99f4526f1076c 
```




 