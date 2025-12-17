# 🚀 Configurador Kubernetes para Laravel

Este diretório contém templates e scripts para configurar automaticamente projetos Laravel para deploy em Kubernetes.

## 📦 O que está incluído?

- ✅ **Templates Kubernetes** prontos para uso
- ✅ **Configurações Docker** otimizadas para Laravel
- ✅ **CI/CD com GitHub Actions**
- ✅ **Script interativo** que gera tudo automaticamente
- ✅ **SSL automático** com cert-manager e Let's Encrypt

## 🎯 Para quem é?

Este setup é perfeito para:

- 👶 **Iniciantes** em Kubernetes
- 🚀 **Desenvolvedores Laravel** que querem deploy profissional
- 💼 **Equipes** que precisam de processo padronizado
- 📊 **Projetos** que precisam escalar

## 🛠️ Como usar?

### Passo 1: Executar o script de configuração

```bash
cd kubernetes-vps-setup
chmod +x setup.sh
./setup.sh
```

O script vai perguntar:
- 📦 Nome do projeto
- 🌐 Domínio
- 🖥️ IP da VPS
- 🐳 Usuário Docker Hub
- 🔑 Senhas (ou gera automaticamente)
- ⚙️ Recursos (CPU/Memória)

### Passo 2: Verificar arquivos gerados

Após executar o script, os seguintes arquivos serão criados:

```
seu-projeto/
├── kubernetes/              # ← Arquivos Kubernetes prontos
│   ├── namespace.yaml
│   ├── secrets.yaml
│   ├── configmap.yaml
│   ├── postgres.yaml
│   ├── redis.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── cert-issuer.yaml
│   └── migration-job.yaml
├── docker/                  # ← Configurações Docker
│   ├── nginx/
│   │   └── default.conf
│   └── supervisor/
│       └── supervisord.conf
├── .github/workflows/       # ← CI/CD
│   ├── deploy.yml          # Deploy automático no Kubernetes
│   ├── docker-build.yml    # Build da imagem Docker
│   ├── tests.yml           # Testes automatizados
│   └── lint.yml            # Linter e formatação
├── Dockerfile              # ← Build da aplicação
└── .dockerignore          # ← Arquivos ignorados
```

### Passo 3: Seguir os próximos passos

O script mostrará os comandos necessários para:

1. 🗄️ Criar diretórios na VPS
2. 🔐 Configurar GitHub Secrets
3. 🌐 Configurar DNS
4. 🚀 Fazer deploy

## 📋 Pré-requisitos

### Na VPS (já configurada):

- ✅ Ubuntu 22.04 LTS
- ✅ Docker instalado
- ✅ Kubernetes configurado (kubeadm, kubectl, kubelet)
- ✅ Ingress Controller (Nginx)
- ✅ cert-manager instalado
- ✅ Firewall configurado

> 💡 **Dica**: Siga a **PARTE 1** do [DEPLOY_VPS.md](DEPLOY_VPS.md) para configurar a VPS.  
> 📖 **Detalhes técnicos**: Veja [DEPLOY_VPS_ADVANCED.md](DEPLOY_VPS_ADVANCED.md) para entender cada configuração.

### No seu computador:

- ✅ kubectl instalado e configurado
- ✅ Git instalado
- ✅ Conta no GitHub (usaremos GitHub Container Registry)
- ✅ Domínio próprio

## 🎨 Personalização

Todos os templates estão em `templates/` e podem ser editados conforme necessário:

- `*.yaml.stub` - Templates Kubernetes
- `Dockerfile.stub` - Configuração Docker
- `deploy.yml.stub` - GitHub Actions

As variáveis disponíveis são:

```
{{PROJECT_NAME}}      - Nome do projeto
{{NAMESPACE}}         - Namespace Kubernetes
{{DOMAIN}}            - Domínio da aplicação
{{VPS_IP}}            - IP da VPS
{{DOCKER_USERNAME}}   - Usuário Docker Hub
{{DOCKER_IMAGE}}      - Nome da imagem Docker
{{APP_KEY}}           - Chave do Laravel
{{DB_NAME}}           - Nome do banco
{{DB_USER}}           - Usuário do banco
{{DB_PASSWORD}}       - Senha do banco
{{REDIS_PASSWORD}}    - Senha do Redis
{{MEM_REQUEST}}       - Memória mínima
{{MEM_LIMIT}}         - Memória máxima
{{CPU_REQUEST}}       - CPU mínima
{{CPU_LIMIT}}         - CPU máxima
{{REPLICAS}}          - Número de réplicas
```

## 🔄 Re-executar o script

Você pode executar o script quantas vezes quiser:

```bash
./setup.sh
```

Os arquivos serão recriados com as novas configurações.

## 📚 Recursos incluídos

### Kubernetes:

- **Namespace** - Isolamento do projeto
- **Secrets** - Senhas e chaves seguras
- **ConfigMap** - Configurações da aplicação
- **PostgreSQL** - Banco de dados com volume persistente
- **Redis** - Cache e filas com volume persistente
- **Deployment** - Gerenciamento de pods
- **Service** - Exposição interna
- **Ingress** - Roteamento HTTP/HTTPS
- **ClusterIssuer** - Certificados SSL automáticos
- **Job** - Execução de migrations

### Docker:

- **PHP 8.4** com extensões otimizadas
- **Nginx** como web server
- **Supervisor** gerenciando processos
- **Queue Workers** automáticos
- **Multi-stage build** para otimização

### CI/CD:

- **Build automático** ao fazer push
- **Deploy automático** no Kubernetes
- **Rollback** fácil em caso de erro
- **Zero-downtime** deploys

## ⚙️ Configurações padrão

### Recursos (podem ser alterados no script):

- **Memória**: 256Mi - 512Mi
- **CPU**: 250m - 500m
- **Réplicas**: 2 pods
- **PostgreSQL**: 10Gi de storage
- **Redis**: 5Gi de storage

### Probes (health checks):

- **Liveness**: Verifica se app está viva
- **Readiness**: Verifica se app está pronta

### Segurança:

- ✅ Senhas geradas automaticamente
- ✅ Secrets do Kubernetes
- ✅ SSL/TLS obrigatório
- ✅ Comunicação criptografada

## 🐛 Troubleshooting

### Script não executa:

```bash
chmod +x setup.sh
```

### APP_KEY não gerada:

Execute manualmente:
```bash
php artisan key:generate --show
```

E cole o valor quando o script pedir.

### Templates não encontrados:

Certifique-se de estar executando de dentro da pasta `kubernetes-vps-setup/`:

```bash
cd /caminho/para/seu-projeto/kubernetes-vps-setup
./setup.sh
```

## 📖 Documentação completa

Para guia completo de configuração da VPS e deploy:

👉 [DEPLOY_VPS.md](DEPLOY_VPS.md)

## 🤝 Contribuindo

Melhorias são bem-vindas! Sugestões:

- Adicionar suporte para outros bancos de dados
- Mais opções de customização
- Templates para outros frameworks
- Monitoramento e observabilidade

## 📝 Licença

Este setup é fornecido "como está" para uso livre em projetos Laravel.

## 🆘 Suporte

Encontrou algum problema? 

1. Verifique se seguiu todos os pré-requisitos
2. Consulte [DEPLOY_VPS.md](DEPLOY_VPS.md) seção de troubleshooting
3. Revise os logs: `kubectl logs -n seu-namespace`

---

**Criado para facilitar a vida de desenvolvedores Laravel! 🚀**

Feito com ❤️ para a comunidade Laravel
