# BeyondCorp AppConnector CLI

This CLI is a tool used to automate the end-to-end process of setting up
BeyondCorp AppConnector for your applications. The goal is to make integration
simple and seamless for the user. With this CLI, you can integrate with
BeyondCorp AppConnector in just a few commands and in a matter of minutes.

## Prerequisites

1.  The CLI needs `jq` to function, so make sure to
    [install it](https://stedolan.github.io/jq/) beforehand.
2.  Have a GCP consumer project set up and ready to go in the region
    `us-central1`, as this is the only supported region for now.
3.  Have an
    [OAuth brand](https://cloud.google.com/iap/docs/programmatic-oauth-clients)
    set up.
4.  IAP & Compute APIs need to be enabled.
5.  Have your application that you want to protect with BeyondCorp AppConnector
    ready.

## Usage

1.  Create a network in the consumer VPC where remote applications are attached
    using PSC endpoints. The network creation is a one-time effort and currently
    the CLI only supports having one network at a time. On network creation,
    various parameters such as network name and project ID are stored in a
    configuration file in `~/bce_network_settings`. These parameters will be
    reused for all subsequent CLI operations.

    ```sh
    $ ./beyondcorp.sh network create <NAME> -r <REGION> -p <PROJECT_ID>
    ```

    In the above command, `REGION` is the GCP region of your consumer project,
    should just be `us-central` for now, and `PROJECT_ID` is the ID of your
    consumer project.

2.  Create a connector. This step calls the BeyondCorp API to create a connector
    resource and prints the instructions for installing the agent on the remote
    VM.

    ```sh
    $ ./beyondcorp.sh connectors create <CONNECTOR_NAME>
    ```

    **Make sure to also follow the onscreen instructions afterwards to install
    the connection agent on the remote VM.**

3.  Create a connection. This step calls the BeyondCorp API to create a
    connection resource and creates a network address in the consumer VPC. After
    this step completes, the remote application should be reachable in the VPC
    at that address on port `19443`.

    ```sh
    $ ./beyondcorp.sh connections create <CONNECTION_NAME> -c <CONNECTOR_NAME> -h <APP_HOST> -p <APP_PORT>
    ```

    In the above command, `CONNECTOR_NAME` is the name you used to create the
    connector in step 2; `APP_HOST` and `APP_PORT` are the host and port of your
    application.

4.  Publish the connection. This step publishes your app on the internet under
    the protection of BeyondCorp AppConnector.

    ```sh
    $ ./beyondcorp.sh app publish <CONNECTION_NAME> -f <http|https> -b <http|https> [optional_flags]
    ```

    In the above command, `CONNECTION_NAME` is the name you used to create the
    connection in step 3, `-f` specifies the protocol your app will be accessed
    through on the internet, and `-b` specifies the protocol of the server
    running your application. 
    
    As an example, if you want to
    publish using https on the domain `domain.com` (requires DNS to be set up
    beforehand), and your app is running on a http server, and you want to
    enable IAP and grant only user `user1@gmail.com` access to your app, then
    you would run:

    ```sh
    $ ./beyondcorp.sh app publish <CONNECTION_NAME> -f https -b http -d domain.com -e -u user1@gmail.com
    ```

    After the above succeeds, you should be able to see an OAuth screen at
    `domain.com` and you should be able to use `user1@gmail.com` to access your
    app.

**For a complete list of commands supported, please see `./beyondcorp.sh -h`.**
