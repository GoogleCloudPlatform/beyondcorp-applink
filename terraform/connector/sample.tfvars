// This file shows a sample input variable definitions file for the connector module.
// The input values shown here are not meant to be used as is directly.

project_id = "my-project"

connector_map = {
  c1 : {
    impersonating_account_email : "connector-admin@myorg.com",
    description : "Connector 1 for BCE Applink",
    // String key-value pairs.
    additional_metadata : {
      // Example samples.
      location : "dc-1-virginia",
      key2 : "value2"
    }
  },
}