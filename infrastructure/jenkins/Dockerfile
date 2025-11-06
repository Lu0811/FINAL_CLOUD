# Imagen base de Jenkins LTS
FROM jenkins/jenkins:lts

# Cambiar a root para instalar paquetes
USER root

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    unzip \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Instalar Google Cloud SDK con plugin de autenticación GKE
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update && apt-get install -y google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin && \
    rm -rf /var/lib/apt/lists/*

# Instalar OpenTofu
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh && \
    chmod +x install-opentofu.sh && \
    ./install-opentofu.sh --install-method deb && \
    rm -f install-opentofu.sh

# Instalar kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Instalar Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-buildx-plugin && \
    rm -rf /var/lib/apt/lists/*

# Dar permisos al grupo docker
RUN groupadd -f docker && usermod -aG docker jenkins

# Verificar instalaciones
RUN gcloud --version && \
    tofu --version && \
    kubectl version --client && \
    docker --version

# Volver al usuario jenkins
USER jenkins

# Pre-instalar plugins de Jenkins necesarios
RUN jenkins-plugin-cli --plugins \
    workflow-aggregator \
    git \
    credentials \
    google-compute-engine \
    kubernetes

# Exponer puerto
EXPOSE 8080
EXPOSE 50000
