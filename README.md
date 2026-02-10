# Развертывание кластера Kubernetes

# Автоматическая настройка
#### На мастер ноде запустить ./scripts/master.sh
Проверяем : ШАГ 2.4


# Ручная настройка 
## 1. ВСЕ НОДЫ кластера

### Инструкция:
https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/


#### На докере требуются дополнительные настройки. Лучше контейнеризировать через containerd

```bash
sudo apt update -y
sudo apt upgrade -y
```

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
 
###### установка helm
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
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




 kubeadm join 46.173.18.173:6443 --token uvw88v.d1ehi0h17xzbd8zd \
	--discovery-token-ca-cert-hash sha256:20ca9998a598eaf8907d613e9108ffd9b722de3d99e7d5d333df60f1e829202d 













у меня есть приложение laravel + potgres, я хочу его запустить в кластере и развернуть БД на statefull ( к примеру longhorn), как это сделать ? у меня есть мастер и node, как развернуть бд

Для развертывания Laravel приложения с PostgreSQL в Kubernetes кластере с StatefulSet для БД (используя Longhorn), вот пошаговый план:
1. Структура проекта:
text

laravel-k8s/
├── namespace.yaml
├── postgres/
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── statefulset.yaml
│   ├── service.yaml
│   └── pvc.yaml
├── laravel/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── storageclass-longhorn.yaml

2. Создать StorageClass для Longhorn:
yaml

# storageclass-longhorn.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "1"
  staleReplicaTimeout: "2880" # 48 часов в минутах
  fromBackup: ""

Применить:
bash

kubectl apply -f storageclass-longhorn.yaml

3. Создать Namespace:
yaml

# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: laravel-app
  labels:
    name: laravel-app

4. PostgreSQL StatefulSet с Longhorn:
Secret для паролей:
yaml

# postgres/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: laravel-app
type: Opaque
data:
  postgres-password: cG9zdGdyZXNwYXNzd29yZA==  # postgrespassword в base64
  # echo -n "postgrespassword" | base64

ConfigMap для конфигурации:
yaml

# postgres/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: laravel-app
data:
  POSTGRES_DB: laravel_db
  POSTGRES_USER: laravel_user
  PGDATA: /var/lib/postgresql/data/pgdata

PersistentVolumeClaim:
yaml

# postgres/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: laravel-app
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 10Gi

StatefulSet для PostgreSQL:
yaml

# postgres/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: laravel-app
spec:
  serviceName: "postgres"
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        imagePullPolicy: "IfNotPresent"
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: postgres-password
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: POSTGRES_DB
        - name: POSTGRES_USER
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: POSTGRES_USER
        - name: PGDATA
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: PGDATA
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

Service для PostgreSQL:
yaml

# postgres/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: laravel-app
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None  # Headless service для StatefulSet

5. Laravel Deployment:
ConfigMap для Laravel:
yaml

# laravel/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: laravel-config
  namespace: laravel-app
data:
  APP_ENV: production
  APP_DEBUG: "false"
  DB_CONNECTION: pgsql
  DB_HOST: postgres.laravel-app.svc.cluster.local
  DB_PORT: "5432"
  DB_DATABASE: laravel_db
  DB_USERNAME: laravel_user
  CACHE_DRIVER: redis
  QUEUE_CONNECTION: redis

Deployment:
yaml

# laravel/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: laravel-app
  namespace: laravel-app
  labels:
    app: laravel
spec:
  replicas: 2
  selector:
    matchLabels:
      app: laravel
  template:
    metadata:
      labels:
        app: laravel
    spec:
      containers:
      - name: laravel
        image: ваш-laravel-образ:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
        env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: laravel-config
              key: APP_ENV
        - name: APP_DEBUG
          valueFrom:
            configMapKeyRef:
              name: laravel-config
              key: APP_DEBUG
        - name: DB_CONNECTION
          valueFrom:
            configMapKeyRef:
              name: laravel-config
              key: DB_CONNECTION
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: laravel-config
              key: DB_HOST
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: laravel-config
              key: DB_PORT
        - name: DB_DATABASE
          valueFrom:
            configMapKeyRef:
              name: laravel-config
              key: DB_DATABASE
        - name: DB_USERNAME
          valueFrom:
            configMapKeyRef:
              name: laravel-config
              key: DB_USERNAME
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: postgres-password
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 30

Service для Laravel:
yaml

# laravel/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: laravel-service
  namespace: laravel-app
spec:
  selector:
    app: laravel
  ports:
  - port: 80
    targetPort: 8000
  type: ClusterIP

Ingress (если нужен доступ извне):
yaml

# laravel/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: laravel-ingress
  namespace: laravel-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: laravel.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: laravel-service
            port:
              number: 80

6. Дополнительно: Redis для кэша и очередей:
yaml

# redis/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
  namespace: laravel-app
spec:
  serviceName: "redis"
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: redis-data
          mountPath: /data
        command: ["redis-server", "--appendonly", "yes"]
      volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: laravel-app
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: redis
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc
  namespace: laravel-app
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 5Gi

7. Полный скрипт развертывания:
bash

#!/bin/bash
# deploy-laravel.sh

echo "=== Развертывание Laravel с PostgreSQL в Kubernetes ==="

# 1. Проверяем Longhorn
echo "1. Проверяем Longhorn..."
kubectl get storageclass
kubectl get pods -n longhorn-system

# 2. Создаем namespace
echo "2. Создаем namespace..."
kubectl apply -f namespace.yaml

# 3. Развертываем PostgreSQL
echo "3. Развертываем PostgreSQL..."
kubectl apply -f postgres/secret.yaml
kubectl apply -f postgres/configmap.yaml
kubectl apply -f postgres/pvc.yaml
kubectl apply -f postgres/service.yaml
kubectl apply -f postgres/statefulset.yaml

# Ждем готовности PostgreSQL
echo "Ожидаем запуска PostgreSQL..."
sleep 30
kubectl wait --namespace=laravel-app --for=condition=ready pod -l app=postgres --timeout=300s

# 4. Развертываем Laravel
echo "4. Развертываем Laravel..."
# Сначала соберите Docker образ Laravel
# docker build -t ваш-laravel-образ:latest -f Dockerfile .
# docker push ваш-laravel-образ:latest

kubectl apply -f laravel/configmap.yaml
kubectl apply -f laravel/deployment.yaml
kubectl apply -f laravel/service.yaml

# 5. Применяем миграции
echo "5. Применяем миграции базы данных..."
kubectl exec -n laravel-app deployment/laravel-app -- php artisan migrate --force

echo "=== Развертывание завершено! ==="
echo "Проверка статуса:"
kubectl get all -n laravel-app
echo ""
echo "Доступ к приложению:"
echo "Внутри кластера: http://laravel-service.laravel-app.svc.cluster.local"
echo "Снаружи (если настроен Ingress): http://laravel.example.com"

8. Dockerfile для Laravel:
dockerfile

FROM php:8.2-fpm-alpine

# Устанавливаем зависимости
RUN apk add --no-cache \
    postgresql-dev \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    nodejs \
    npm

# Устанавливаем PHP расширения
RUN docker-php-ext-install pdo pdo_pgsql gd zip

# Устанавливаем Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Рабочая директория
WORKDIR /var/www/html

# Копируем зависимости
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Копируем код приложения
COPY . .

# Устанавливаем права
RUN chown -R www-data:www-data storage bootstrap/cache

# Экспонируем порт
EXPOSE 8000

# Запускаем приложение
CMD php artisan serve --host=0.0.0.0 --port=8000

9. Проверка работы:
bash

# Проверить все компоненты
kubectl get all,pvc -n laravel-app

# Проверить логи PostgreSQL
kubectl logs -n laravel-app statefulset/postgres

# Проверить логи Laravel
kubectl logs -n laravel-app deployment/laravel-app -f

# Проверить доступ к БД
kubectl exec -n laravel-app -it postgres-0 -- psql -U laravel_user -d laravel_db

# Получить доступ к приложению
kubectl port-forward -n laravel-app service/laravel-service 8080:80

Такой подход обеспечит отказоустойчивое развертывание Laravel с PostgreSQL на Longhorn storage.