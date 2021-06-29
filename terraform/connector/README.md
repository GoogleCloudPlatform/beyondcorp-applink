# BCE Applink Connector

Modular BCE Applink Connectors for GCP.


## Key Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| project_id | The project to deploy to. | string | n/a | yes |
| connector_map | Map from unique keys for connectors to their description and additional metadata. | map(object({ description : string, additional_metadata : map(string) })) | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| connector_info | Map from connector keys to their relevant information. |

## Prerequisites

You should have created a GCP project for deploying BCE Applink Gateway. You
will use this project to actuate the resources associated with connector
metadata.

## Getting Started

1.  Run ```terraform init``` to install all modules

2.  Dry run of actuating resources using terraform
    ```
    terraform plan -var-file=[FILEPATH]
    ```
    NOTE: If service account impersonation is needed, the impersonating accounts must be created prior to this step.

3.  Actuate resources using terraform
    ```
    terraform apply -var-file=[FILEPATH]
    ```
