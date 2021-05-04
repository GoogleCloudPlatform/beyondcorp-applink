# Frequently asked questions

#### Table of Contents

*   [Connector Configuration](#connector-configuration)

*   [Credentials](#credentials)

*   [Application Connectivity Troubleshooting](#application-connectivity-troubleshooting)

## Connector Configuration

### How can I create a redundant connector for a high availability (HA) setup?

Simply start another VM and run the connector bash script with the same
configuration.

### What types of connections does the connector support? What about HTTPS or fully qualified domain names (FQDNs)?

The connector supports the following connection configurations:

1.  HTTP with an IP address for the app_endpoint

    Gateway
    [sample.tfvars file](terraform/gateway/examples/single-app/sample.tfvars):

    ```
    ...
    app_endpoint = "10.0.0.2:80"
    backend_service_protocol = "HTTP"
    ...
    ```

2.  HTTP with a FQDN for the app_endpoint

    Gateway
    [sample.tfvars file](terraform/gateway/examples/single-app/sample.tfvars):

    ```
    ...
    app_endpoint = "myapp.com:80"
    backend_service_protocol = "HTTP"
    ...
    ```

3.  HTTPS with an IP address for the app_endpoint

    Gateway
    [sample.tfvars file](terraform/gateway/examples/single-app/sample.tfvars):

    ```
    ...
    app_endpoint = "10.0.0.2:443"
    backend_service_protocol = "HTTPS"
    ...
    ```

4.  HTTPS with a FQDN for the app_endpoint

    Gateway
    [sample.tfvars file](terraform/gateway/examples/single-app/sample.tfvars):

    ```
    ...
    app_endpoint = "myapp.com:443"
    backend_service_protocol = "HTTPS"
    ...
    ```

## Credentials

### I'm getting a token parsing error similar to the one below. What should I do?

```
ERROR: 2021/04/16 15:44:08 gwConn: 0xc0001d4990 :: tunnelet.Run() failed with error: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing failed to get token: parsing time \"\" as \"2006-01-02T15:04:05Z07:00\": cannot parse \"\" as \"2006\""
```

Most likely your credentials have expired, and you'll need to reauthenticate.
Remove the existing connector if it's currently running by executing the
following command:

```
docker rm -f bce-applink-connector
```

Next, run the connector bash script again, and select "Yes" at the
authentication step.

### What are the various identities used when running Applink?

There are 3 identities in the Applink workflow:

1.  The Default Compute Service Account \
    (\[*project-id*\]-compute@developer.gserviceaccount.com)
2.  The Admin User Account
3.  The Connector Service Account. This is the service account that is created
    and returned in the [Connector](terraform-config.md#applink-connector) step.

Identities **#1** and **#2** need to be part of the signup request for BCE
AppLink and provided to your GCP Customer Engineer/Cloud Security Specialist.

On the *Gateway(GCP)* side: **#1** (Default Compute Service Account) acts as the
identity of the gateway GCP VM. It is used to fetch the image from GCR and run
the VM itself.

On the *Connector(on-prem)* side: **#2** (Admin User Account) is used when the bash
script runs *gcloud auth login*. **#2** is then used to fetch the connector
image for GCR.

Later, the AppLink connector container is started with **#2** (Admin User
Account) impersonating **#3** (Connector Service Account). Thus, internally all
Applink-related IAM bindings are tied to **#3** (Connector Service Account).

## Application Connectivity Troubleshooting

1.  Log in to the connector VM. If your app endpoint is a domain name, verify
    that it gets resolved correctly on the connector VM:

    ```
    nslookup [app_endpoint_hostname]
    ```

2.  Make sure the app endpoint host is accessible:

    ```
    ping [app_endpoint_hostname]
    ```

3.  On the connector VM, try to fetch a page from the app endpoint using curl:

    ```
    curl http(s)://[app_endpoint]
    ```

4.  If all the previous steps have succeeded, you can also check that the app is
    accessible from the gateway. First, SSH into the gateway GCP VM (it should
    have "bce-applink" and "mig" in its name). Next, from the gateway, type the
    following command to fetch your app's home page though the gateway:

    ```
    curl http://localhost:19443
    ```

    If your app_endpoint uses HTTPS, use "https" in the URL for *curl*, and use
    the -k option if your app_endpoint certificate is self-signed:

    ```
    curl https://localhost:19443 -k
    ```
