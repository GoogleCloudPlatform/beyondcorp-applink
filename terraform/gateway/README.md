# BCE Applink Gateway Terraform Module

Modular BCE Applink Gateways


## Key Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| project_id | The project to deploy to. | n/a | yes |
| application_map | Map from unique keys for applications to their configurations.. | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| application_info | Map from application keys to it's relevant information. |

## Getting Started

1.  [Create a GCP project & setup billing](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
    ```
    gcloud projects create [PROJECT_ID]
    gcloud beta billing projects link [PROJECT_ID] --billing-account=[ACCOUNT_ID]
    ```
2.  Enable the following APIs:

    -   [Compute Engine API](https://console.cloud.google.com/apis/library/compute.googleapis.com)
    -   [Identity Aware Proxy API](https://console.cloud.google.com/apis/library/iap.googleapis.com)

    ```
    gcloud services enable compute.googleapis.com
    gcloud services enable iap.googleapis.com
    ```

3.  Ensure your project and account has been allow listed by the GCP team as detailed in the user guide.

4.  Configure OAuth consent screen as detailed [here](https://cloud.google.com/iap/docs/tutorial-gce#set_up_iap).

5.  The configured brand name can be fetched for use as iap_brand_name variable using
    ```
    gcloud alpha iap oauth-brands list --format="value(name)"
    ```
6.  Run terraform to actuate resources
    ```
    terraform apply -var-file=[FILEPATH]
    ```
7.  Authorize connectors to connect to the gateway instances by re-running terraform
    ```
    terraform apply -var-file=[FILEPATH]
    ```
    NOTE: This is needed in order to fetch information about resources created in step 6.
    Do not make any additional modifications between step 6 & 7.
8.  Setup load balancer front end configuration as desired.
