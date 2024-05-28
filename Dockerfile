# Usa la imagen base de Ubuntu
FROM ubuntu:20.04

# Establecer variables de entorno para no pedir información en la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Actualizar el sistema e instalar dependencias
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    build-essential

# Definir la versión de Go compatible con kubebuilder
ENV GO_VERSION=1.16.15

# Descargar y extraer Go
RUN wget https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz \
    && rm go$GO_VERSION.linux-amd64.tar.gz

# Establecer las variables de entorno para Go
ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/go
ENV PATH=$PATH:$GOPATH/bin

# Crear directorios de trabajo
RUN mkdir -p $GOPATH/src $GOPATH/bin

# Establecer el directorio de trabajo
WORKDIR /go

# Instalar operator-sdk
RUN curl -LO https://github.com/operator-framework/operator-sdk/releases/download/v1.10.1/operator-sdk_linux_amd64 \
    && chmod +x operator-sdk_linux_amd64 \
    && mv operator-sdk_linux_amd64 /usr/local/bin/operator-sdk

# Comando por defecto
CMD ["bash"]
