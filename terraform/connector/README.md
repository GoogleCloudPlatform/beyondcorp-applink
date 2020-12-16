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

## Getting Started

1.  [Create a GCP project & setup billing](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
    ```
    gcloud projects create [PROJECT_ID]
    gcloud beta billing projects link [PROJECT_ID] --billing-account=[ACCOUNT_ID]
    ```
2.  Dry run of actuating resources using terraform
    ```
    terraform plan -var-file=[FILEPATH]
    ```
    NOTE: If service account impersonation is needed, the impersonating accounts must be created prior to this step.

3.  Actuate resources using terraform
    ```
    terraform apply -var-file=[FILEPATH]
    ```
