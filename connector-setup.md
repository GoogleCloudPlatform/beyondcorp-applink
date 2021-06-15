# Connector VM Setup

Prior to the Connector VM setup, please follow the steps 1, 2 and 3 from the
[Step-by-Step Deployment](README.md#step-by-step-deployment). The BCE Applink
gateway(s) should be running and ready to receive connections from BCE Applink
connector(s).

*   Provision a VM for use by the connector in your enterprise network with
    access to the remote application to be secured.

    *   For the demo we would be using a Debian VM in Project A

*   [Install Docker](https://docs.docker.com/engine/install/) on the connector
    VM.

    *   If you're using a Linux-based operating system, such as Ubuntu or
        Debian, add your username to the docker group so that you can run Docker
        without using sudo:

        *   `$ sudo usermod -a -G docker ${USER}`
        *   Log out and log back in for group membership changes to take effect.
            You may need to restart the virtual machine for membership changes
            to take effect.

*   [Install](https://cloud.google.com/sdk/install) Google Cloud SDK on the
    connector VM

    *   On Google Compute Engine, Cloud SDK is installed by default. You can
        still manually install/update
        [using apt-get](https://cloud.google.com/sdk/docs/downloads-apt-get) for
        the installation.

## Start Connector Container

The bash script for this step is located
[here](bash-scripts/start-applink-connector). Access to the connector image
should have been granted as part of the Washboard sign-up process.

**NOTE: For this step, you must use an account you listed for "Storage Access"
in the Private Preview sign-up form**

*   Copy the bash script *start-applink-connector* to the Connector VM

*   Run the bash script *start-applink-connector* with the following flags:

    *   -c \[the Google Cloud Storage connection object returned from output of
        the [Gateway](terraform-config.md#applink-gateway) step (gs://...)\]
        **Required**

    *   -f **Optional**

        *   Set this flag to start a Fluentbit container alongside the
	    connector.

    *   -l \[The name for the connector Docker container\] **Optional**

    *   -n \[The name of the network to connect to\] **Optional**

        *   The Docker container will connect to the host network by default.

    *   -s \[*service_account_email* from the
        [Connector](terraform-config.md#applink-connector) step\]

        *   **Optional** if service account impersonation is desired.

        *   **Required** if Fluentbit container is desired.

*   To see all available options and usage, type `$ ./start-applink-connector
    -h`

Example:

```
$ ./start-applink-connector \
-c gs://921727625615-connector-c1/connections/apache \
-s connector-c1-sa@brettmeehan-applink.iam.gserviceaccount.com
```

## Start Fluentbit Container (Optional)

To start the Fluentbit container independently, follow the steps below. 
The bash script for this step is located
[here](bash-scripts/start-fluentbit).

* Copy the bash script *start-fluentbit* to the Connector VM.

* Run the bash script *start-fluentbit* with the following flags:
	
	* -c \[the path to the credentials file\] **Optional**  
	  This is the credentials to be used by Fluentbit to connect to your
	  Google Cloud project.

	* -l \[the path to the folder where Docker container logs are stored\] 
    **Optional**

    *   -s \[*service_account_email* from the
        [Connector](terraform-config.md#applink-connector) step\] **Required**

* To see all available options and usage, type `$ ./start-fluentbit -h`

Example:

```
$ ./start-fluentbit -s connector-c1-sa@brettmeehan-applink.iam.gserviceaccount.com
```

### Cloud Logging
To filter gateway logs, use the following query:

```
resource.type="gce_instance"
"applink_gw"
```

To filter connector logs, use the following query:

```
jsonPayload.attrs.tag = "beyondcorp.*"
```

[Next: Publish application using Identity Aware Proxy](iap-lb-setup.md)
