#!/bin/bash
set -e

NAMESPACE=${1:-plannerate}

echo "🚀 Instalando Plannerate COMPLETO no Kubernetes"
echo "================================================"
echo "📍 Namespace: ${NAMESPACE}"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl não encontrado!${NC}"
    exit 1
fi

# Verificar conexão com cluster
echo "🔍 Verificando conexão com cluster..."
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Não foi possível conectar ao cluster Kubernetes${NC}"
    echo "   Configure kubectl primeiro"
    exit 1
fi
echo -e "${GREEN}✅ Conectado ao cluster${NC}"
echo ""

# Criar namespace
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo "📦 Criando namespace ${NAMESPACE}..."
    kubectl create namespace ${NAMESPACE}
else
    echo -e "${YELLOW}⚠️  Namespace ${NAMESPACE} já existe${NC}"
fi
echo ""

# Deploy PostgreSQL
echo "🐘 Instalando PostgreSQL..."
kubectl apply -f kubernetes/postgres.yaml -n ${NAMESPACE}
echo -e "${GREEN}✅ PostgreSQL configurado${NC}"
echo "   Host: postgres"
echo "   Database: plannerate"
echo "   User: plannerate"
echo "   Password: plannerate_password_2024"
echo ""

# Deploy Redis
echo "🔴 Instalando Redis..."
kubectl apply -f kubernetes/redis.yaml -n ${NAMESPACE}
echo -e "${GREEN}✅ Redis configurado${NC}"
echo "   Host: redis"
echo "   Password: plannerate_redis_2024"
echo ""

# Aguardar PostgreSQL e Redis
echo "⏳ Aguardando PostgreSQL estar pronto..."
kubectl wait --for=condition=ready pod -l app=postgres -n ${NAMESPACE} --timeout=180s
echo -e "${GREEN}✅ PostgreSQL pronto!${NC}"

echo "⏳ Aguardando Redis estar pronto..."
kubectl wait --for=condition=ready pod -l app=redis -n ${NAMESPACE} --timeout=180s
echo -e "${GREEN}✅ Redis pronto!${NC}"
echo ""

# ConfigMap e Secrets
echo "⚙️  Aplicando configurações..."
kubectl apply -f kubernetes/configmap.yaml -n ${NAMESPACE}
kubectl apply -f kubernetes/secrets.yaml -n ${NAMESPACE}
echo -e "${GREEN}✅ Configurações aplicadas${NC}"
echo ""

# Deploy da aplicação
echo "🌐 Instalando aplicação Plannerate..."
kubectl apply -f kubernetes/deployment.yaml -n ${NAMESPACE}
kubectl apply -f kubernetes/queue-deployment.yaml -n ${NAMESPACE}
kubectl apply -f kubernetes/service.yaml -n ${NAMESPACE}
echo -e "${GREEN}✅ Aplicação configurada${NC}"
echo ""

# Aguardar aplicação
echo "⏳ Aguardando aplicação estar pronta..."
kubectl wait --for=condition=ready pod -l app=plannerate,tier=app -n ${NAMESPACE} --timeout=300s
echo -e "${GREEN}✅ Aplicação pronta!${NC}"
echo ""

# Executar migrations
echo "🗃️  Executando migrations do banco de dados..."
kubectl apply -f kubernetes/migration-job.yaml -n ${NAMESPACE}
echo "   Aguardando migrations..."
kubectl wait --for=condition=complete job/plannerate-migration -n ${NAMESPACE} --timeout=180s 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Verificando logs da migration...${NC}"
    kubectl logs job/plannerate-migration -n ${NAMESPACE}
}
echo -e "${GREEN}✅ Migrations executadas${NC}"
echo ""

# Deploy Ingress
echo "🌐 Configurando Ingress..."
kubectl apply -f kubernetes/ingress.yaml -n ${NAMESPACE}
echo -e "${GREEN}✅ Ingress configurado${NC}"
echo ""

# Instalar cert-manager se necessário
if ! kubectl get clusterissuer letsencrypt-prod &> /dev/null; then
    echo "🔐 Configurando certificados SSL..."
    read -p "Deseja instalar cert-manager para SSL automático? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
        echo "Aguardando cert-manager..."
        sleep 30
        kubectl apply -f kubernetes/cert-issuer.yaml
        echo -e "${GREEN}✅ Cert-manager instalado${NC}"
    fi
fi
echo ""

# Status final
echo "================================================"
echo -e "${GREEN}🎉 INSTALAÇÃO COMPLETA!${NC}"
echo "================================================"
echo ""

echo "📊 Status dos serviços:"
echo ""
echo "PostgreSQL:"
kubectl get pods -n ${NAMESPACE} -l app=postgres
echo ""
echo "Redis:"
kubectl get pods -n ${NAMESPACE} -l app=redis
echo ""
echo "Aplicação:"
kubectl get pods -n ${NAMESPACE} -l app=plannerate
echo ""
echo "Services:"
kubectl get svc -n ${NAMESPACE}
echo ""
echo "Ingress:"
kubectl get ingress -n ${NAMESPACE}
echo ""

echo "================================================"
echo "📝 INFORMAÇÕES IMPORTANTES"
echo "================================================"
echo ""
echo "🔑 Credenciais do PostgreSQL:"
echo "   Host: postgres (interno)"
echo "   Database: plannerate"
echo "   User: plannerate"
echo "   Password: plannerate_password_2024"
echo ""
echo "🔴 Credenciais do Redis:"
echo "   Host: redis (interno)"
echo "   Password: plannerate_redis_2024"
echo ""
echo "⚠️  ATENÇÃO: Você ainda precisa configurar:"
echo "   1. APP_KEY no secrets.yaml (gere com: php artisan key:generate --show)"
echo "   2. Credenciais do DigitalOcean Spaces no secrets.yaml"
echo "   3. Seu domínio no ingress.yaml"
echo ""
echo "🔧 Comandos úteis:"
echo "   Ver logs: kubectl logs -l app=plannerate,tier=app -n ${NAMESPACE}"
echo "   Escalar: kubectl scale deployment plannerate-app --replicas=3 -n ${NAMESPACE}"
echo "   Executar artisan: kubectl exec -it deployment/plannerate-app -n ${NAMESPACE} -- php artisan cache:clear"
echo ""
echo -e "${GREEN}✅ Tudo pronto para uso!${NC}"
