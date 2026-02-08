# Развертывание кластера Kubernetes

## 1. ВСЕ НОДЫ кластера

### Инструкция:
https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

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
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

#### Шаг 2.2: Настройка kubectl
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### Шаг 2.3: Установка Flannel (самый простой способ)
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

###### Проверка Flannel
```bash
kubectl get pods -n kube-system -l app=flannel
```


## 3. ПРОВЕРКА МАСТЕР Ноды 
#### ШАГ 3.1: проверяем запущенные компоненты

```bash
sudo crictl ps
```
#### Должны быть запущены в статусе 'Running' следующие сервисы :
- kube-scheduler 
- coredns ( возможно в нескольких экземплярах)
- kube-controller-manager
- kube-apiserver 
- etcd    






 