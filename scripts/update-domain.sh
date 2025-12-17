#!/bin/bash

# Script para atualizar o domínio do projeto

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🌐 Atualizar Domínio do Projeto${NC}"
echo "================================"
echo ""

# Pegar domínio atual
CURRENT_DOMAIN=$(grep -m1 "host:" ../kubernetes/ingress.yaml | awk '{print $3}')
echo -e "Domínio atual: ${YELLOW}${CURRENT_DOMAIN}${NC}"
echo ""

# Solicitar novo domínio
read -p "Novo domínio (ex: meusite.com): " NEW_DOMAIN

if [ -z "$NEW_DOMAIN" ]; then
    echo -e "${YELLOW}⚠️  Cancelado${NC}"
    exit 0
fi

# Solicitar email para SSL
read -p "Email para certificado SSL (ex: admin@${NEW_DOMAIN}): " SSL_EMAIL

if [ -z "$SSL_EMAIL" ]; then
    SSL_EMAIL="admin@${NEW_DOMAIN}"
fi

echo ""
echo -e "${BLUE}📝 Atualizando arquivos...${NC}"

# Atualizar ingress.yaml
sed -i "s/${CURRENT_DOMAIN}/${NEW_DOMAIN}/g" ../kubernetes/ingress.yaml
echo -e "${GREEN}✅ kubernetes/ingress.yaml${NC}"

# Atualizar cert-issuer.yaml
CURRENT_EMAIL=$(grep "email:" ../kubernetes/cert-issuer.yaml | awk '{print $2}')
sed -i "s/${CURRENT_EMAIL}/${SSL_EMAIL}/g" ../kubernetes/cert-issuer.yaml
echo -e "${GREEN}✅ kubernetes/cert-issuer.yaml${NC}"

echo ""
echo -e "${GREEN}✅ Domínio atualizado com sucesso!${NC}"
echo ""
echo -e "${YELLOW}📋 Próximos passos:${NC}"
echo -e "  1. Configure o DNS de ${NEW_DOMAIN} para o IP da VPS"
echo -e "  2. Aplique as mudanças: ${BLUE}kubectl apply -f kubernetes/ingress.yaml -n kb-app${NC}"
echo -e "  3. Commit: ${BLUE}git add kubernetes/ && git commit -m 'Update domain to ${NEW_DOMAIN}'${NC}"
echo ""
