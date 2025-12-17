# 💼 Exemplos de Uso - Casos Reais

Este documento mostra exemplos práticos de como usar o setup em diferentes cenários.

## 🎯 Cenário 1: Primeiro Projeto Laravel

**Situação**: Você tem um projeto Laravel rodando localmente e quer fazer deploy em produção.

**Requisitos**:
- VPS com Kubernetes já configurado (PARTE 1 do DEPLOY_VPS.md)
- Domínio: `minhaloja.com`
- Projeto Laravel funcionando localmente

**Passos**:

```bash
# 1. Ir para o diretório do projeto
cd ~/projetos/minha-loja

# 2. Copiar pasta kubernetes-vps-setup para o projeto
cp -r ~/kubernetes-vps-setup .

# 3. Executar configurador
cd kubernetes-vps-setup
./setup.sh
```

**Respostas no setup.sh**:
```
Nome do projeto: minha-loja
Namespace: loja-prod
Domínio: minhaloja.com
IP VPS: 159.89.123.45
Docker Hub user: joaosilva
APP_KEY: [ENTER - gera automático]
Email: admin@minhaloja.com
Database: loja_db
User DB: loja_user
PostgreSQL password: [ENTER - gera automático]
Redis password: [ENTER - gera automático]
Spaces: n
Recursos: [ENTER - padrões]
```

**Resultado**: Arquivos criados em `~/projetos/minha-loja/kubernetes/`

---

## 🎯 Cenário 2: Múltiplos Ambientes (Staging + Produção)

**Situação**: Quer ter ambiente de staging e produção na mesma VPS.

### Staging

```bash
cd ~/projeto
cd kubernetes-vps-setup
./setup.sh
```

Respostas:
```
Nome: meu-app
Namespace: app-staging        # ← Diferente!
Domínio: staging.app.com      # ← Diferente!
Réplicas: 1                   # ← Menos recursos
Memória: 256Mi-512Mi          # ← Menor
```

### Produção

```bash
# Executar novamente
./setup.sh
```

Respostas:
```
Nome: meu-app
Namespace: app-production      # ← Diferente!
Domínio: app.com               # ← Diferente!
Réplicas: 3                    # ← Mais réplicas
Memória: 512Mi-1Gi             # ← Mais recursos
```

**Resultado**: Dois ambientes isolados na mesma VPS!

```bash
# Ver ambos
kubectl get pods -n app-staging
kubectl get pods -n app-production
```

---

## 🎯 Cenário 3: Projeto com DigitalOcean Spaces

**Situação**: Projeto que precisa armazenar uploads em cloud storage.

**Configuração Spaces**:
1. Criar bucket no DigitalOcean Spaces
2. Gerar Access Key e Secret Key
3. Anotar região (ex: sfo3)

**No setup.sh**:
```
Usar Spaces: s                          # ← Sim
Access Key: DO00ABCDEFGH123456789      # ← Sua key
Secret Key: [senha do spaces]          # ← Seu secret
Região: sfo3                           # ← Sua região
Bucket: meu-app-uploads                # ← Nome do bucket
Endpoint: https://sfo3.digitaloceanspaces.com
```

**No Laravel** (`config/filesystems.php`):
```php
'disks' => [
    'do_spaces' => [
        'driver' => 's3',
        'key' => env('DO_SPACES_KEY'),
        'secret' => env('DO_SPACES_SECRET'),
        'region' => env('DO_SPACES_REGION'),
        'bucket' => env('DO_SPACES_BUCKET'),
        'url' => env('DO_SPACES_URL'),
        'endpoint' => env('DO_SPACES_ENDPOINT'),
        'use_path_style_endpoint' => false,
    ],
],

'default' => env('FILESYSTEM_DISK', 'do_spaces'),
```

---

## 🎯 Cenário 4: Migração de Projeto Existente

**Situação**: Já tem projeto em outra hospedagem e quer migrar para Kubernetes.

**Passos**:

### 1. Backup do banco atual
```bash
# Na hospedagem antiga
mysqldump -u usuario -p banco > backup.sql
# ou para PostgreSQL:
pg_dump -U usuario banco > backup.sql
```

### 2. Configurar novo ambiente
```bash
cd seu-projeto
cd kubernetes-vps-setup
./setup.sh
```

### 3. Deploy inicial
```bash
git add .
git commit -m "feat: Add Kubernetes config"
git push origin main
```

### 4. Aguardar pods ficarem prontos
```bash
kubectl get pods -n seu-namespace
```

### 5. Restaurar backup
```bash
# Converter MySQL para PostgreSQL se necessário
# Depois:
cat backup.sql | kubectl exec -i postgres-0 -n seu-namespace -- \
    psql -U seu-usuario -d seu-banco
```

### 6. Atualizar DNS
```
Tipo: A
Nome: @
Valor: [IP da nova VPS]
TTL: 300 (5 minutos para testar)
```

### 7. Testar
```bash
curl -I https://seu-dominio.com
```

### 8. Confirmar DNS (aumentar TTL)
```
TTL: 3600 (1 hora)
```

---

## 🎯 Cenário 5: Projeto com Workers Intensivos

**Situação**: Aplicação que processa muitas filas (envio de emails, processamento de imagens, etc).

**Customização necessária**:

Editar `templates/deployment.yaml.stub` antes de executar `setup.sh`:

```yaml
# Adicionar deployment separado para workers
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: queue-worker
  namespace: {{NAMESPACE}}
spec:
  replicas: 5  # ← Mais workers
  selector:
    matchLabels:
      app: laravel-queue
  template:
    metadata:
      labels:
        app: laravel-queue
    spec:
      containers:
      - name: worker
        image: {{DOCKER_IMAGE}}:latest
        command: ["php", "artisan", "queue:work", "--sleep=3", "--tries=3"]
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

Depois executar:
```bash
./setup.sh
```

---

## 🎯 Cenário 6: Projeto com Múltiplos Domínios

**Situação**: Mesma aplicação servindo vários domínios (multi-tenant).

**Editar** `kubernetes/ingress.yaml` após executar `setup.sh`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: meu-namespace
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.com
    - www.app.com
    - app.com.br
    - www.app.com.br
    secretName: app-tls-multi
  rules:
  - host: app.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
  - host: www.app.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
  - host: app.com.br
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
  - host: www.app.com.br
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

Aplicar:
```bash
kubectl apply -f kubernetes/ingress.yaml
```

**Configurar DNS** para todos os domínios:
```
app.com         → A → [IP VPS]
www.app.com     → A → [IP VPS]
app.com.br      → A → [IP VPS]
www.app.com.br  → A → [IP VPS]
```

---

## 🎯 Cenário 7: Desenvolvimento Local com Minikube

**Situação**: Testar configurações Kubernetes localmente antes de deploy.

**Instalar Minikube**:
```bash
# Ubuntu/Debian
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Iniciar
minikube start

# Habilitar ingress
minikube addons enable ingress
```

**Executar setup.sh** com configurações locais:
```
Domínio: app.local
IP VPS: 192.168.49.2    # ← IP do Minikube
[resto normal]
```

**Adicionar ao /etc/hosts**:
```bash
echo "192.168.49.2 app.local" | sudo tee -a /etc/hosts
```

**Aplicar configurações**:
```bash
kubectl apply -f kubernetes/
```

**Testar**:
```bash
curl http://app.local
```

---

## 🎯 Cenário 8: CI/CD com GitLab

**Situação**: Usar GitLab CI/CD em vez de GitHub Actions.

**Criar** `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - deploy

variables:
  DOCKER_IMAGE: $CI_REGISTRY_IMAGE
  NAMESPACE: meu-app

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $DOCKER_IMAGE:$CI_COMMIT_SHA .
    - docker build -t $DOCKER_IMAGE:latest .
    - docker push $DOCKER_IMAGE:$CI_COMMIT_SHA
    - docker push $DOCKER_IMAGE:latest
  only:
    - main

deploy:
  stage: deploy
  image: bitnami/kubectl:latest
  before_script:
    - mkdir -p ~/.kube
    - echo "$KUBECONFIG" > ~/.kube/config
  script:
    - kubectl apply -f kubernetes/
    - kubectl set image deployment/app app=$DOCKER_IMAGE:$CI_COMMIT_SHA -n $NAMESPACE
    - kubectl rollout status deployment/app -n $NAMESPACE
  only:
    - main
```

**Configurar variáveis no GitLab**:
- Settings → CI/CD → Variables
- Adicionar: `KUBECONFIG`

---

## 🎯 Cenário 9: Monitoramento com Prometheus

**Situação**: Adicionar monitoramento de métricas.

**Instalar Prometheus**:
```bash
kubectl create namespace monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring
```

**Adicionar annotations** no `deployment.yaml`:
```yaml
template:
  metadata:
    labels:
      app: laravel-app
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "9090"
      prometheus.io/path: "/metrics"
```

**Acessar Grafana**:
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Abrir: http://localhost:3000
# User: admin
# Pass: prom-operator
```

---

## 🎯 Cenário 10: Backup Automático para S3

**Situação**: Backup diário do banco para AWS S3.

**Criar CronJob** `kubernetes/backup-cronjob.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: db-backup
  namespace: {{NAMESPACE}}
spec:
  schedule: "0 2 * * *"  # 2h da manhã todo dia
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:16-alpine
            env:
            - name: AWS_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: AWS_ACCESS_KEY
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: AWS_SECRET_KEY
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: DB_PASSWORD
            command:
            - /bin/sh
            - -c
            - |
              apk add --no-cache aws-cli
              DATE=$(date +%Y%m%d_%H%M%S)
              pg_dump -h postgres-service -U laravel laravel | gzip > /tmp/backup_${DATE}.sql.gz
              aws s3 cp /tmp/backup_${DATE}.sql.gz s3://meu-bucket/backups/
          restartPolicy: OnFailure
```

**Aplicar**:
```bash
kubectl apply -f kubernetes/backup-cronjob.yaml
```

---

## 📊 Resumo de Casos de Uso

| Cenário | Complexidade | Tempo Estimado |
|---------|--------------|----------------|
| 1. Primeiro Projeto | ⭐ Fácil | 30 min |
| 2. Múltiplos Ambientes | ⭐⭐ Médio | 45 min |
| 3. Com Spaces/S3 | ⭐ Fácil | 35 min |
| 4. Migração | ⭐⭐⭐ Difícil | 2-3 horas |
| 5. Workers Intensivos | ⭐⭐ Médio | 1 hora |
| 6. Múltiplos Domínios | ⭐⭐ Médio | 45 min |
| 7. Dev Local | ⭐⭐ Médio | 1 hora |
| 8. GitLab CI/CD | ⭐⭐ Médio | 1 hora |
| 9. Monitoramento | ⭐⭐⭐ Difícil | 2 horas |
| 10. Backup S3 | ⭐⭐ Médio | 45 min |

---

**💡 Dica**: Comece pelo Cenário 1, depois explore os outros conforme sua necessidade!
