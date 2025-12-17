# ⚡ Início Rápido - Deploy Laravel com Kubernetes

Este guia te leva do zero ao deploy em **menos de 30 minutos**!

## 🎯 Pré-requisitos Checklist

Antes de começar, certifique-se de ter:

- [ ] VPS Ubuntu 22.04 com Kubernetes configurado ([PARTE 1 do DEPLOY_VPS.md](DEPLOY_VPS.md))
- [ ] Domínio próprio (ex: exemplo.com)
- [ ] Conta no GitHub (usaremos GitHub Container Registry)
- [ ] kubectl configurado localmente

> 💡 **Primeira vez?** Configure a VPS primeiro seguindo a **PARTE 1** do [DEPLOY_VPS.md](DEPLOY_VPS.md)  
> 📖 **Quer detalhes?** Veja [DEPLOY_VPS_ADVANCED.md](DEPLOY_VPS_ADVANCED.md) para entender cada configuração

---

## 🚀 Passos Rápidos

### 1️⃣ Execute o Configurador (2 minutos)

```bash
cd kubernetes-vps-setup
./setup.sh
```

**Responda as perguntas:**

```
📦 Nome do projeto: meu-app
🏢 Namespace: meu-app
🌐 Domínio: app.exemplo.com
🖥️  IP da VPS: 203.0.113.10
 APP_KEY: [ENTER para gerar]
📧 Email: admin@exemplo.com
🗄️  Banco: laravel
👤 Usuário DB: laravel
🔐 Senha PostgreSQL: [ENTER para gerar]
🔐 Senha Redis: [ENTER para gerar]
☁️  DigitalOcean Spaces: n
💾 Recursos: [ENTER para padrões]
```

✅ **Arquivos criados em**: `kubernetes/`, `docker/`, `.github/workflows/`

---

### 2️⃣ Preparar VPS (3 minutos)

```bash
# Conectar na VPS
ssh root@203.0.113.10

# Criar diretórios para dados
mkdir -p /data/postgresql /data/redis
chmod 700 /data/postgresql
chmod 755 /data/redis

# Verificar se tudo está OK
kubectl get nodes
# Deve mostrar: Ready

exit
```

---

### 3️⃣ Configurar GitHub Secrets (5 minutos)

```bash
# No diretório do projeto
cd ~/meu-projeto

# Instalar GitHub CLI (se necessário)
# Ubuntu/Debian:
# sudo apt install gh

# Autenticar
gh auth login

# APP_KEY (copie do output do script setup.sh)
gh secret set APP_KEY --body "base64:sua-chave-aqui"

# KUBE_CONFIG (em base64)
# Pegar o kubeconfig da VPS e converter para base64:
ssh root@203.0.113.10 'cat /etc/kubernetes/admin.conf' | base64 -w 0 | gh secret set KUBE_CONFIG --body-file -

# Verificar
gh secret list

# Deve mostrar:
# APP_KEY
# KUBE_CONFIG
```

---

### 4️⃣ Configurar DNS (5 minutos)

No seu provedor de DNS (Cloudflare, etc):

| Tipo | Nome | Valor | Proxy |
|------|------|-------|-------|
| A | @ | 203.0.113.10 | DNS only |
| A | * | 203.0.113.10 | DNS only |

**Testar propagação:**

```bash
dig app.exemplo.com
# Deve retornar: 203.0.113.10
```

---

### 5️⃣ Deploy! (10 minutos)

```bash
# Commit e push
git add .
git commit -m "feat: Add Kubernetes configuration"
git push origin main

# Acompanhar build
gh run watch

# Ou ver no browser:
# https://github.com/seu-usuario/seu-repo/actions
```

**Enquanto aguarda, aplicar configurações Kubernetes:**

```bash
# Aplicar na ordem:
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/cert-issuer.yaml
kubectl apply -f kubernetes/postgres.yaml
kubectl apply -f kubernetes/redis.yaml

# Aguardar bancos de dados ficarem prontos
kubectl wait --for=condition=ready pod -l app=postgres -n meu-app --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n meu-app --timeout=120s

# Aplicar aplicação
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml

# Executar migrations
kubectl apply -f kubernetes/migration-job.yaml
```

---

### 6️⃣ Verificar Deploy (2 minutos)

```bash
# Ver pods
kubectl get pods -n meu-app

# Ver certificado SSL (pode levar 2-5 minutos)
kubectl get certificate -n meu-app

# Ver ingress
kubectl get ingress -n meu-app

# Ver logs
kubectl logs -f deployment/app -n meu-app
```

**Saída esperada:**

```
NAME                   READY   STATUS    RESTARTS   AGE
app-xxx                2/2     Running   0          2m
postgres-0             1/1     Running   0          3m
redis-0                1/1     Running   0          3m

NAME      READY   SECRET    AGE
app-tls   True    app-tls   3m
```

---

### 7️⃣ Acessar Aplicação (1 minuto)

```bash
# Testar
curl -I https://app.exemplo.com

# Ou abrir no navegador
open https://app.exemplo.com
```

**✅ Se aparecer com cadeado verde, SUCESSO! 🎉**

---

## 🔄 Próximos Deploys

Muito mais simples:

```bash
# Fazer alterações no código
git add .
git commit -m "feat: Nova funcionalidade"
git push origin main

# Deploy automático via GitHub Actions!
# Acompanhar: gh run watch
```

> 💡 **Importante**: O GitHub Actions possui 2 workflows:
> 1. **Build and Push Docker Image** - Cria a imagem e envia para ghcr.io
> 2. **Deploy to Kubernetes** - Atualiza os pods com a nova imagem
> 
> Ambos devem completar com sucesso (✓) para o deploy funcionar.

---

## 🐛 Problemas Comuns

### Pods não iniciam

```bash
# Ver erro
kubectl describe pod POD_NAME -n meu-app

# Ver logs
kubectl logs POD_NAME -n meu-app
```

### Certificado SSL não criado

```bash
# Ver status
kubectl describe certificate app-tls -n meu-app

# Ver challenges
kubectl get challenges -n meu-app

# Causas comuns:
# - DNS não propagou (aguarde 10-30 min)
# - Porta 80 bloqueada no firewall
# - Email inválido no cert-issuer.yaml
```

### Site não abre (502/504)

```bash
# Ver pods
kubectl get pods -n meu-app

# Se não estão Running, ver logs:
kubectl logs deployment/app -n meu-app

# Verificar ingress
kubectl get ingress -n meu-app
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### GitHub Actions falha

```bash
# Ver erro no GitHub
gh run view --log-failed

# Erros comuns:

# 1. "error loading config file" ou "couldn't get version/kind"
# Causa: KUBE_CONFIG não está em base64 ou está corrompido
# Solução:
ssh root@SEU_IP_VPS 'cat /etc/kubernetes/admin.conf' | base64 -w 0 | gh secret set KUBE_CONFIG --body-file -

# 2. "connection refused" para o cluster
# Causa: IP interno no kubeconfig em vez do público
# Solução: O comando acima já pega o correto

# 3. "ImagePullBackOff"
# Causa: Imagem não foi publicada no GitHub Container Registry
# Solução: Verificar se o workflow "Build and Push Docker Image" rodou com sucesso
gh run list --workflow="Build and Push Docker Image"
```

---

## 📊 Comandos Úteis

```bash
# Ver tudo do namespace
kubectl get all -n meu-app

# Ver logs em tempo real
kubectl logs -f deployment/app -n meu-app

# Executar comando no pod
kubectl exec -it deployment/app -n meu-app -- bash

# Executar migrations
kubectl exec -it deployment/app -n meu-app -- php artisan migrate

# Reiniciar deployment
kubectl rollout restart deployment/app -n meu-app

# Ver eventos
kubectl get events -n meu-app --sort-by='.lastTimestamp'
```

---

## 🎓 Próximos Passos

1. **Configurar Backup Automático** - Ver [DEPLOY_VPS.md](DEPLOY_VPS.md#próximos-passos)
2. **Adicionar Monitoramento** - Prometheus + Grafana
3. **Configurar Staging Environment** - Criar namespace separado
4. **Implementar Blue/Green Deploy** - Zero-downtime garantido
5. **Adicionar CDN** - CloudFlare para assets

---

## 🆘 Precisa de Ajuda?

1. **Documentação Completa**: [DEPLOY_VPS.md](DEPLOY_VPS.md)
2. **Troubleshooting Detalhado**: Seção 11 do DEPLOY_VPS.md
3. **Templates e Customização**: [README.md](README.md)

---

## 📝 Resumo dos Tempos

| Etapa | Tempo Estimado |
|-------|----------------|
| 1. Executar configurador | 2 minutos |
| 2. Preparar VPS | 3 minutos |
| 3. GitHub Secrets | 5 minutos |
| 4. Configurar DNS | 5 minutos |
| 5. Deploy | 10 minutos |
| 6. Verificar | 2 minutos |
| 7. Acessar | 1 minuto |
| **TOTAL** | **~28 minutos** |

> 💡 Após primeira vez, próximos deploys levam **menos de 1 minuto** (apenas `git push`)!

---

**🎉 Parabéns! Você tem um setup profissional de Kubernetes para Laravel!**

Deploy automático ✅ | SSL grátis ✅ | Escalável ✅ | Profissional ✅
