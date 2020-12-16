# BCE Applink Gateway example

This example demonstrates use of BCE Applink using an opinionated setup for a single application.
It creates 1 IAP backend service, sets up its OAuth client and configures an external HTTPS load balancer to forward all traffic directed to its IP to the backend service.


## Key Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| project_id | The project to deploy to. | string | n/a | yes |
| iap_brand_name | The Cloud OAuth brands in the project. | string | n/a | yes |
| app_name | The name of the application. | string | n/a | yes |
| app_endpoint | The address of the on-prem application (ip:port). | string | n/a | yes |
| dns_name | The DNS name of the application. | string | n/a | yes |
| connector_info | The Terraform output from the connector step. | map | n/a | yes |


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
    NOTE: Only internal org iap clients are supported by this script. Other types of clients must be manually created via the GCP console.

5.  The configured brand name can be fetched for use as iap_brand_name variable using
    ```
    gcloud alpha iap oauth-brands list --format="value(name)"
    ```
6. Run ```terraform init``` to install all modules

7. Run terraform to actuate resources
    ```
   terraform apply -var-file=[FILEPATH]
    ```
8.  Authorize connectors to connect to the gateway instances by re-running terraform 
    ```
    terraform apply -var-file=[FILEPATH]
    ```
    NOTE: This is needed in order to fetch information about resources created in step 6.
    Do not make any additional modifications between step 6 & 7.
9.  Update the DNS records for your domain to point to the load balancer's IP address returned as output of previous step.
