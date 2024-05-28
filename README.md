El error "unable to scaffold with 'base.go.kubebuilder.io/v3': exit status 1" indica que hubo un problema durante el proceso de scaffolding del proyecto. Esto puede deberse a varias razones, como permisos, problemas de configuración del entorno, o versiones incompatibles.

Para solucionar esto, vamos a asegurarnos de que estamos siguiendo los pasos correctamente y verificando el entorno. Aquí hay un procedimiento paso a paso:

### Paso 1: Crear el Dockerfile

Vamos a usar el siguiente Dockerfile que instala una versión compatible de Go y el Operator SDK:

```Dockerfile
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
```

### Paso 2: Construir y Ejecutar el Contenedor

1. **Construir la Imagen Docker**:

    ```sh
    docker build -t ubuntu-go:1.16 .
    ```

2. **Ejecutar el Contenedor**:

    ```sh
    docker run -it --name operator-container ubuntu-go:1.16
    ```

### Paso 3: Inicializar el Proyecto en un Nuevo Directorio

Dentro del contenedor, sigue estos pasos:

1. **Crear un Nuevo Directorio**:

    ```sh
    mkdir -p /go/src/github.com/example/memcached-operator
    cd /go/src/github.com/example/memcached-operator
    ```

2. **Inicializar el Proyecto**:

    ```sh
    operator-sdk init --domain=example.com --repo=github.com/example/memcached-operator --project-name=memcached-operator
    ```

### Paso 4: Crear una API y un Controlador

Si la inicialización del proyecto fue exitosa, procede a crear la API y el controlador:

```sh
operator-sdk create api --group=cache --version=v1alpha1 --kind=Memcached --resource --controller
```

### Depuración Adicional

Si encuentras más errores, puedes hacer lo siguiente:

1. **Verificar Permisos**: Asegúrate de que el usuario dentro del contenedor tenga permisos suficientes para crear y modificar archivos en el directorio de trabajo.
2. **Verificar Dependencias**: Asegúrate de que todas las dependencias están correctamente instaladas.
3. **Logs Detallados**: Ejecuta los comandos con mayor nivel de detalle para obtener más información sobre los errores:

    ```sh
    operator-sdk init --domain=example.com --repo=github.com/example/memcached-operator --project-name=memcached-operator --verbose
    ```




Una vez que has creado el proyecto de operador, la API y el controlador, los siguientes pasos implican la implementación de la lógica del operador, la construcción y el despliegue del operador en un clúster de Kubernetes. Aquí te detallo los pasos a seguir:


### Paso 1: Implementar la Lógica del Controlador

1. **Definir el Esquema del Recurso**: Actualiza el archivo `api/v1alpha1/memcached_types.go` para definir el esquema del recurso Memcached. Este archivo ya tendrá una estructura básica generada por el `operator-sdk`.

    ```go
    // MemcachedSpec defines the desired state of Memcached
    type MemcachedSpec struct {
        Size int32 `json:"size"`
    }

    // MemcachedStatus defines the observed state of Memcached
    type MemcachedStatus struct {
        Nodes []string `json:"nodes"`
    }
    ```

2. **Implementar el Controlador**: Abre el archivo `controllers/memcached_controller.go` y añade la lógica necesaria para gestionar el recurso. Este archivo contiene el esqueleto del reconciler que debes completar.

    ```go
    func (r *MemcachedReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
        // Fetch the Memcached instance
        memcached := &cachev1alpha1.Memcached{}
        err := r.Get(ctx, req.NamespacedName, memcached)
        if err != nil {
            if errors.IsNotFound(err) {
                // Request object not found, could have been deleted after reconcile request.
                // Owned objects are automatically garbage collected. For additional cleanup logic use finalizers.
                return ctrl.Result{}, nil
            }
            // Error reading the object - requeue the request.
            return ctrl.Result{}, err
        }

        // Define your logic to handle the Memcached resource here

        // Return and don't requeue
        return ctrl.Result{}, nil
    }
    ```

3. **Actualizar el Setup del Controlador**: Configura el controlador para que administre el recurso Memcached.

    ```go
    func (r *MemcachedReconciler) SetupWithManager(mgr ctrl.Manager) error {
        return ctrl.NewControllerManagedBy(mgr).
            For(&cachev1alpha1.Memcached{}).
            Complete(r)
    }
    ```

### Paso 2: Construir y Empaquetar el Operador

1. **Construir el Binario**: En el directorio raíz del proyecto, ejecuta el siguiente comando para construir el binario del operador.

    ```sh
    make build
    ```

2. **Construir la Imagen Docker**: Construye la imagen Docker del operador.

    ```sh
    make docker-build docker-push IMG=<your-docker-repo>/memcached-operator:v0.1.0
    ```

### Paso 3: Desplegar el Operador en un Clúster de Kubernetes

1. **Desplegar el CRD**: Despliega el CustomResourceDefinition (CRD) para el recurso Memcached.

    ```sh
    make install
    ```

2. **Desplegar el Operador**: Despliega el operador en el clúster.

    ```sh
    make deploy IMG=<your-docker-repo>/memcached-operator:v0.1.0
    ```

### Paso 4: Probar el Operador

1. **Crear una Instancia del Recurso**: Crea un archivo YAML para definir una instancia del recurso Memcached.

    ```yaml
    apiVersion: cache.example.com/v1alpha1
    kind: Memcached
    metadata:
      name: memcached-sample
    spec:
      size: 3
    ```

    Aplica este archivo en el clúster:

    ```sh
    kubectl apply -f config/samples/cache_v1alpha1_memcached.yaml
    ```

2. **Verificar el Despliegue**: Verifica que el operador está gestionando correctamente el recurso Memcached.

    ```sh
    kubectl get pods
    kubectl get memcached memcached-sample -o yaml
    ```

### Paso 5: Monitorizar y Depurar

1. **Ver Logs del Operador**: Verifica los logs del operador para asegurarte de que está funcionando correctamente.

    ```sh
    kubectl logs -l control-plane=controller-manager -n <namespace>
    ```

2. **Ajustar el Código y Redeploy**: Si encuentras problemas, ajusta el código del controlador, reconstruye la imagen y despliega de nuevo.

### Paso 6: (Opcional) Publicar el Operador

1. **Publicar en un Registro de Imágenes**: Asegúrate de que tu imagen Docker está publicada en un registro accesible (por ejemplo, Docker Hub, Quay, etc.).

2. **Escribir Documentación**: Escribe documentación detallada sobre cómo usar tu operador.

3. **Contribuir a un Catálogo**: Considera contribuir tu operador a un catálogo de operadores, como OperatorHub.io.

Con estos pasos, deberías tener un operador funcional y desplegable en Kubernetes.