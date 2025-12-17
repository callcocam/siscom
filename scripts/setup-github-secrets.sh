#!/bin/bash

echo "🔧 Configurando GitHub Actions Secrets"
echo "======================================"
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificar gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) não encontrado!${NC}"
    echo "Instale: https://cli.github.com/"
    exit 1
fi

# Verificar autenticação
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Não está autenticado no GitHub${NC}"
    echo "Execute: gh auth login"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI configurado${NC}"
echo ""

# Obter repository
REPO=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
if [ -z "$REPO" ]; then
    echo -e "${RED}❌ Não foi possível detectar o repositório GitHub${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Repositório: ${REPO}${NC}"
echo ""

# 1. APP_KEY
echo "🔑 1. APP_KEY do Laravel"
echo "Execute: php artisan key:generate --show"
read -p "Cole a APP_KEY aqui: " APP_KEY

if [ -n "$APP_KEY" ]; then
    gh secret set APP_KEY -b"$APP_KEY" -R "$REPO"
    echo -e "${GREEN}✅ APP_KEY configurada${NC}"
else
    echo -e "${YELLOW}⚠️  APP_KEY não configurada${NC}"
fi
echo ""

# 2. KUBECONFIG
echo "☸️  2. KUBECONFIG (Kubernetes)"
echo "Cole o conteúdo do seu ~/.kube/config (ou kubeconfig da Hostinger)"
echo "Pressione Ctrl+D quando terminar:"
KUBECONFIG_CONTENT=$(cat)

if [ -n "$KUBECONFIG_CONTENT" ]; then
    KUBECONFIG_BASE64=$(echo "$KUBECONFIG_CONTENT" | base64 -w 0)
    gh secret set KUBECONFIG -b"$KUBECONFIG_BASE64" -R "$REPO"
    echo -e "${GREEN}✅ KUBECONFIG configurado${NC}"
else
    echo -e "${YELLOW}⚠️  KUBECONFIG não configurado${NC}"
fi
echo ""

# 3. DigitalOcean Spaces
echo "🌊 3. DigitalOcean Spaces (opcional)"
read -p "DO_SPACES_KEY: " DO_SPACES_KEY
read -p "DO_SPACES_SECRET: " DO_SPACES_SECRET

if [ -n "$DO_SPACES_KEY" ]; then
    gh secret set DO_SPACES_KEY -b"$DO_SPACES_KEY" -R "$REPO"
    echo -e "${GREEN}✅ DO_SPACES_KEY configurado${NC}"
fi

if [ -n "$DO_SPACES_SECRET" ]; then
    gh secret set DO_SPACES_SECRET -b"$DO_SPACES_SECRET" -R "$REPO"
    echo -e "${GREEN}✅ DO_SPACES_SECRET configurado${NC}"
fi
echo ""

echo "======================================"
echo -e "${GREEN}🎉 Configuração completa!${NC}"
echo ""
echo "📝 Secrets configurados:"
gh secret list -R "$REPO"
echo ""
echo "🚀 Próximos passos:"
echo "1. git add ."
echo "2. git commit -m 'Configure Kubernetes deployment'"
echo "3. git push origin main"
echo ""
echo "O deploy será feito automaticamente! 🎊"
