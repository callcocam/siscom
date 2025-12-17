#!/bin/bash

# Script para deploy manual no Kubernetes

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

NAMESPACE="kb-app"

echo -e "${BLUE}🚀 Deploy Manual para Kubernetes${NC}"
echo "=================================="
echo ""

# Verificar conexão
echo -e "${YELLOW}🔍 Verificando conexão com cluster...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Não foi possível conectar ao cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Conectado${NC}"
echo ""

# Aplicar configurações
echo -e "${YELLOW}⚙️  Aplicando configurações...${NC}"
kubectl apply -f kubernetes/secrets.yaml -n $NAMESPACE
kubectl apply -f kubernetes/configmap.yaml -n $NAMESPACE
kubectl apply -f kubernetes/cert-issuer.yaml
echo -e "${GREEN}✅ Configurações aplicadas${NC}"
echo ""

# Atualizar deployment
echo -e "${YELLOW}🔄 Atualizando deployment...${NC}"
kubectl apply -f kubernetes/deployment.yaml -n $NAMESPACE
kubectl apply -f kubernetes/service.yaml -n $NAMESPACE
kubectl apply -f kubernetes/ingress.yaml -n $NAMESPACE
echo -e "${GREEN}✅ Deployment atualizado${NC}"
echo ""

# Reiniciar pods para pegar nova imagem
echo -e "${YELLOW}♻️  Reiniciando pods...${NC}"
kubectl rollout restart deployment/app -n $NAMESPACE
echo -e "${GREEN}✅ Pods reiniciados${NC}"
echo ""

# Aguardar rollout
echo -e "${YELLOW}⏳ Aguardando rollout...${NC}"
kubectl rollout status deployment/app -n $NAMESPACE --timeout=5m
echo -e "${GREEN}✅ Rollout completo${NC}"
echo ""

# Executar migrations
echo -e "${YELLOW}🗃️  Executando migrations...${NC}"
kubectl delete job migration -n $NAMESPACE 2>/dev/null || true
kubectl apply -f kubernetes/migration-job.yaml -n $NAMESPACE
kubectl wait --for=condition=complete job/migration -n $NAMESPACE --timeout=180s 2>/dev/null || {
    echo -e "${RED}⚠️  Verificar logs da migration${NC}"
}
echo -e "${GREEN}✅ Migrations executadas${NC}"
echo ""

# Status final
echo "=================================="
echo -e "${GREEN}🎉 Deploy completo!${NC}"
echo "=================================="
echo ""
kubectl get pods -n $NAMESPACE
echo ""
echo -e "${BLUE}🌐 Acesse: https://plannerate.cloud${NC}"
