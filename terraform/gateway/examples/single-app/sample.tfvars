// This file shows a sample input variable definitions file for the single-app setup.
// The input values shown here are not meant to be used as is directly.

project_id = "my-project"

app_name = "myapp"

app_endpoint = "10.128.0.15:80"

dns_name = "myapp.myorg.com."

// Can be obtained using `gcloud alpha iap oauth-brands list --format="value(name)"`
iap_brand_name = "projects/XXXXXXXXXXXX/brands/XXXXXXXXXXXX"

connector_info = {
  // Use output from connector module
  // Example:
  /*
  "c1" = {
    "config_url" = "https://www.googleapis.com/storage/v1/b/647538708490-connector-c1/o/config%2Finit-config.yaml"
    "service_account_email" = "connector-c1-sa@my-project.iam.gserviceaccount.com"
    "service_account_id" = "projects/my-project/serviceAccounts/connector-c1-sa@my-project.iam.gserviceaccount.com"
  }
  */
}
