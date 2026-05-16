# pruebasdevsecops
[![Preguntas](https://devin.ai/assets/askdeepwiki.png)]((https://github.com/cerc151git/pruebasdevsecops))

This repository contains a full DevSecOps pipeline for deploying a containerized static web application to Azure. The project uses Terraform for Infrastructure as Code (IaC), Docker to containerize the application, and GitHub Actions for CI/CD automation, including security scanning, deployment, monitoring, and automated rollbacks.

## Project Structure

The repository is organized into the following main directories:

-   `.github/workflows/`: Contains all GitHub Actions workflow definitions for CI/CD.
-   `infra/`: Holds the Terraform code for provisioning Azure infrastructure.
-   `src/`: Contains the source code for the static website and its Dockerfile.

```
/
├── .github/workflows/      # GitHub Actions CI/CD pipelines
│   ├── despliegue_completo.yml # Main pipeline for full deployment
│   ├── deploywebdocker.yml    # Builds, scans, and deploys the Docker image
│   ├── infraiac.yml           # Deploys infrastructure using Terraform
│   ├── rollback.yml           # Handles application rollback
│   └── destroy.yml            # Destroys Terraform-managed infrastructure
│
├── infra/                    # Terraform Infrastructure as Code
│   ├── main.tf               # Main Terraform configuration for Azure resources
│   ├── variables.tf          # Terraform variable declarations
│   ├── backend/              # Terraform backend state configurations (dev, qa, prod)
│   └── environments/         # Environment-specific variable files (dev, qa, prod)
│
└── src/                      # Application source code
    ├── Dockerfile            # Dockerfile to build the NGINX web server image
    └── sitio_web/            # Static e-commerce website files (HTML, CSS, JS)
```

## Infrastructure (Terraform)

The infrastructure is managed using Terraform and is defined in the `infra/` directory.

-   **Resources**: The `main.tf` file provisions the following Azure resources:
    -   Azure Resource Group (`azurerm_resource_group`)
    -   Azure App Service Plan (`azurerm_service_plan`)
    -   Azure Linux Web App (`azurerm_linux_web_app`), configured to run a Docker container.

-   **Environments**: The project is structured to support `dev`, `qa`, and `prod` environments. Each environment has its own configuration file (`.tfvars`) in the `infra/environments/` directory, allowing for different settings (e.g., resource names, SKU, container image tags).

-   **State Management**: Terraform's state is managed remotely using an Azure Storage Account backend. The configuration for each environment's state file is located in the `infra/backend/` directory.

## Application (Docker)

The application is a simple static e-commerce website template located in `src/sitio_web/`.

-   **Containerization**: The `src/Dockerfile` packages the static website files into a Docker image using `nginx:latest` as the base. The website content is copied to the `/usr/share/nginx/html` directory inside the container.
-   **Image Repository**: Built images are pushed to Docker Hub under the `devsecopspruebas/webserver` repository. Images are tagged with a unique identifier combining the environment, run number, and commit SHA (e.g., `dev-v12-a1b2c3d`).

## CI/CD (GitHub Actions)

The deployment and security processes are automated through a series of GitHub Actions workflows.

### Main Workflows

-   `despliegue_completo.yml`: This is the orchestrator pipeline for a full deployment cycle. It runs the following jobs in sequence:
    1.  **Deploy Infra**: Triggers `infraiac.yml` to provision or update the Azure infrastructure.
    2.  **Deploy App**: Triggers `deploywebdocker.yml` to build and deploy the application container.
    3.  **Monitoring**: Performs a health check on the deployed application's URL.
    4.  **Rollback**: If the monitoring step fails, it automatically triggers the `rollback.yml` workflow to redeploy the last known stable version.

-   `infraiac.yml`:
    -   Provisions infrastructure using Terraform (`plan` and `apply`).
    -   Runs a security scan on the Terraform code using `tfsec` to find potential misconfigurations.
    -   Can be triggered manually or automatically on pushes/PRs to the `infra/` directory.

-   `deploywebdocker.yml`:
    -   Builds the Docker image for the web application.
    -   Scans the built image for vulnerabilities using `Trivy`.
    -   Pushes the image to Docker Hub.
    -   Deploys the new image to the corresponding Azure Web App.
    -   Updates a repository variable (`DEV_VERSION`, `QA_VERSION`, or `PROD_VERSION`) with the new image tag upon successful deployment.

-   `rollback.yml`:
    -   Redeploys a specific, previously successful Docker image tag to an environment.
    -   Can be triggered manually or automatically by the main pipeline in case of a deployment failure.

-   `destroy.yml`:
    -   A manually triggered workflow to destroy all resources managed by Terraform for a specific environment.

### Prerequisites for CI/CD

To run the workflows, the following secrets and variables must be configured in the GitHub repository:

-   **Secrets**:
    -   `AZURE_AD_CLIENT_ID`: Azure Service Principal Client ID.
    -   `AZURE_AD_CLIENT_SECRET`: Azure Service Principal Client Secret.
    -   `AZURE_SUSCRIPTION_ID`: Azure Subscription ID.
    -   `AZURE_AD_TENANT_ID`: Azure Tenant ID.
    -   `AZURE_WEBAPP_PROFILE_DEV`, `_QA`, `_PROD`: Publish profiles for each Azure Web App environment.
    -   `DOCKERHUB_USERNAME`: Docker Hub username.
    -   `DOCKERHUB_TOKEN`: Docker Hub access token.
    -   `SAS_TOKEN`: SAS token for the Azure Storage Account used for the Terraform backend.
    -   `GV_PAT`: A GitHub Personal Access Token (PAT) with `repo` and `actions:write` scope to update repository variables.
-   **Variables**:
    -   `DEV_VERSION`, `QA_VERSION`, `PROD_VERSION`: Used to store the image tag of the last successfully deployed version for each environment.

### How to Deploy

1.  Navigate to the **Actions** tab in the GitHub repository.
2.  Select the **Pipeline Completo** workflow from the list on the left.
3.  Click the **Run workflow** dropdown.
4.  Choose the target **Ambiente** (`dev`, `qa`, or `prod`).
5.  Click **Run workflow** to start the deployment.
