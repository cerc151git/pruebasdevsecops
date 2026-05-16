# pruebasdevsecops

Este repositorio contiene un pipeline completo de DevSecOps para desplegar una web estatica contenerisada en Azure. Este proyecto usa terraform para infraestructura como codigo, docker para contenerizar la aplicacion, y GitHub Actions para la automatizacion de CI/CD, incluyendo escaneo de seguridad, despliegue, monitoreo y rollback automatico.

## Estructura del proyect

El proyecto esta organizado dentro del siguiente directorio principal:

-   `.github/workflows/`: contienen todas los workflows de GitHub ActionsContains para CI/CD.
-   `infra/`: Contiene el codigo de terraform para provisionar la infraestructura en Azure.
-   `src/`: Contiene el codigo fuente de la pagina Web estatica junto con el dockerfile el cual esta basado en una imagen de nginx

```
/
├── .github/workflows/      # GitHub Actions CI/CD pipelines
│   ├── despliegue_completo.yml # Pipeline principal para el despliegue total
│   ├── deploywebdocker.yml    # Builds, escanea, y despliega la imagen Docker
│   ├── infraiac.yml           # Despliega la infraestructura usando terraform
│   ├── rollback.yml           # Maneja el rollback de la aplicacion
│   └── destroy.yml            # Destruye la infraestructura desplegada
│
├── infra/                    # Terraform Infrastructure as Code
│   ├── main.tf               # configuracion principal de terraforma para el despliegue en Azure
│   ├── variables.tf          # Variables de terraform
│   ├── backend/              # Definicion del estado de despliegue de terraform por ambiente (dev, qa, prod). El estado es guardado en un storage Account que debe ser desplegado previamente
│   └── environments/         # variables por ambiente (dev, qa, prod)
│
└── src/                      # Codigo fuente de la web estatica
    ├── Dockerfile            # Dockerfile para construir el contenedor basado en nginx
    └── sitio_web/            # Plantilla de un sitio web descargado de internet
```

## Infraestructura (Terraform)

La infraestructura es administrada usando terraform y es definida en el directorio infra/

-   **Resources**: The `main.tf` provisiona los siguientes recursos en azure:
    -   Azure Resource Group (`azurerm_resource_group`)
    -   Azure App Service Plan (`azurerm_service_plan`)
    -   Azure Linux Web App (`azurerm_linux_web_app`)

-   **Ambientes**: El proyecto es configurado para soportar los ambientes `dev`, `qa`, y `prod`. Cada ambiente tiene su propio archivo de configuracion (`.tfvars`) en el directorio `infra/environments/`, Permitiendo diferentes configuraciones (resource names, SKU, container image tags).

-   **State Management**: El estado de terraform es administrado remotamente usando como backend Azure Storage Account. La configuracion del archivo de estado para cada ambiente esta ubicado en el directorio `infra/backend/`.

## Application (Docker)

La aplicacion es un sitio web estatico ubicado en el directorio `src/sitio_web/`.

-   **Containerization**: El archivo `src/Dockerfile` empaqueta un sitio web estatico usando `nginx:latest` como base. El contenido del sitio Web es copiado en la rura por defecto de nginx `/usr/share/nginx/html` dentro del contenedor.
-   **Image Repository**: La construccion de imagenes son almacenadas en el repositorio de dockerhub `devsecopspruebas/webserver`. Las imagenes son tageadas con un identificador unico el cual es la combinacion del ambiente el numero de commit y su SHA (`dev-v12-a1b2c3d`).

## CI/CD (GitHub Actions)

El despliegue y procesos de seguridad son automatizados a traves de una serie de Worflows de GitHub Actions

### Main Workflows

-   `despliegue_completo.yml`: Es el pipeline orquestados para un ciclo completo de despliegue. Corre en la siguiente secuencia de jobs:
    1.  **Deploy Infra**: `infraiac.yml` provisiona o actualiza la infraestructura en Azure.
    2.  **Deploy App**: `deploywebdocker.yml` construye y despliega el contenedor del sitio web.
    3.  **Monitoring**: Realiza el  health check de la URL desplegada.
    4.  **Rollback**: Si el monitoreo falla, automaticamente se ejecuta el workflow `rollback.yml` para redesplegar la ultima version estable conocida.

-   `infraiac.yml`:
    -   Provisiona infraestructura en Terraform (`plan` and `apply`).
    -   Ejecuta un escaneo de seguridad en el codigo de terraform usando `tfsec` para encontrar malas configuraciones potenciales.
    -   Puede jecutarse de manera manual o automatica en el directorio `infra/`.

-   `deploywebdocker.yml`:
    -   Construye la imagen docker para la pagina web.
    -   Escanea la imagen construida para encontrar vulnerabilidades usando `Trivy`.
    -   Hace Push de la imagen a Docker Hub.
    -   Despliega la nueva imagen en Azure Web App.
    -   Actualiza las variables del repositorio (`DEV_VERSION`, `QA_VERSION`, o `PROD_VERSION`) con la nueva imagen exitosamente desplegada.

-   `rollback.yml`:
    -   Redespliega la ultima imagen exitosamente desplegada en cada ambiente.
    -   Puede ser ejecutado de manera manual o automatica en caso de un despliegue fallido.

-   `destroy.yml`:
    -   Workflow manual para destruir la infraestrucutra desplegada de un ambiente especifico.

### Prerequisites for CI/CD

Para correr los worflows, Los siguientes secretos y variables deben ser configurados en el repositorio de GitHub:

-   **Secrets**:
    -   `AZURE_AD_CLIENT_ID`: Azure Client ID de un usuario de servicio con privilegios de contributor en Azure.
    -   `AZURE_AD_CLIENT_SECRET`: Secreto del usuario de servicio en Azure.
    -   `AZURE_SUSCRIPTION_ID`: Azure Subscription ID.
    -   `AZURE_AD_TENANT_ID`: Azure Tenant ID.
    -   `AZURE_WEBAPP_PROFILE_DEV`, `_QA`, `_PROD`: Perfiles de publicacion para cada ambiente de Azure Web App.
    -   `DOCKERHUB_USERNAME`: Docker Hub username.
    -   `DOCKERHUB_TOKEN`: Docker Hub access token.
    -   `SAS_TOKEN`: SAS token para el Azure Storage Account usado para el backend de Terraform.
    -   `GV_PAT`: Un token personal de GitHub (PAT) con `repo` y `actions:write` scope para actualizar variables del repositorio.
-   **Variables**:
    -   `DEV_VERSION`, `QA_VERSION`, `PROD_VERSION`: Usado para guardar el tag de la ultima version exitosamente desplegada por cada ambiente.

### How to Deploy

1.  Navegar a la pestaña de **Actions** en el repositorio de GitHub.
2.  Seleccione el workflow **Pipeline Completo** del listado de la izquierda.
3.  Click en **Run workflow**.
4.  Escoja del listado el **Ambiente** (`dev`, `qa`, or `prod`).
5.  Click **Run workflow** para comenzar el despliege.
6.  Si es la primer ves de la ejecucion solo se desplegara la infraestructura y fallara el despliege de la aplicacion.
7.  Una ves desplegada la infraestructura por primera ves se puede obtener en Azure los valores del secreto `AZURE_WEBAPP_PROFILE_DEV`, `_QA`, `_PROD`
8.  Realice nuevamente el despliegue del workflow **Pipeline Completo**
