#!/bin/bash

echo "🔧 Configuração inicial do Kubernetes na VPS"
echo "============================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Este script deve ser executado NA VPS${NC}"
echo ""

# Verificar se kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não encontrado!"
    echo "Instalando kubectl..."
    
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    echo -e "${GREEN}✅ kubectl instalado${NC}"
fi

# Verificar cluster
echo "🔍 Verificando cluster Kubernetes..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cluster Kubernetes não está acessível"
    echo "Certifique-se de que o Kubernetes está rodando"
    exit 1
fi

echo -e "${GREEN}✅ Cluster acessível${NC}"
echo ""

# Instalar Nginx Ingress Controller
echo "🌐 Instalando Nginx Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml

echo "⏳ Aguardando Ingress Controller ficar pronto..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo -e "${GREEN}✅ Ingress Controller instalado${NC}"
echo ""

# Instalar cert-manager para SSL
echo "🔐 Instalar cert-manager para certificados SSL? (y/n)"
read -p "> " install_cert

if [[ $install_cert =~ ^[Yy]$ ]]; then
    echo "Instalando cert-manager..."
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    echo "⏳ Aguardando cert-manager ficar pronto..."
    sleep 30
    kubectl wait --namespace cert-manager \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/instance=cert-manager \
      --timeout=120s
    
    echo -e "${GREEN}✅ cert-manager instalado${NC}"
fi

echo ""
echo "================================================"
echo -e "${GREEN}🎉 Configuração inicial completa!${NC}"
echo "================================================"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1. Obter IP do Ingress Controller:"
echo "   kubectl get svc -n ingress-nginx ingress-nginx-controller"
echo ""
echo "2. Configurar DNS apontando para esse IP:"
echo "   A    seu-dominio.com           → IP_DO_INGRESS"
echo "   A    *.seu-dominio.com         → IP_DO_INGRESS"
echo ""
echo "3. No seu computador local, copiar kubeconfig:"
echo "   cat /etc/kubernetes/admin.conf"
echo "   # Copie o conteúdo e salve no seu computador em ~/.kube/config"
echo ""
echo "4. Configurar GitHub Secrets:"
echo "   ./kubernetes/setup-github-secrets.sh"
echo ""
echo "5. Fazer deploy:"
echo "   git push origin main"
