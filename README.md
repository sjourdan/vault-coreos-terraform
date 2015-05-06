# Vault on CoreOS + Docker with Terraform (on Digital Ocean)

This will deploy [Vault](https://vaultproject.io) on [CoreOS](http://coreos.com/) using [my Vault Docker container](https://registry.hub.docker.com/u/sjourdan/vault/) with [Terraform](http://terraform.io/).

A first version of this will use [demo.consul.io](https://demo.consul.io) as a backend, but using [docker-vault](https://github.com/sjourdan/docker-vault) it can easily be extended to a private [Consul](https://consul.io/) backend.

Terraform will start/manage the CoreOS infrastructure, cloud-init will give enough information to start/join the cluster and deploy required files. Then fleet will manage the containers.

You **will** need to generate a [new etcd discovery token](https://discovery.etcd.io/new) and enter it in the `terraform.tf` file for the demo to work.

The file `cloud-config.yml` contains:
* The Vault configuration file (`/home/core/config/demo.hcl`)
* The two `fleet` unit service files (`/home/core/services/vault@.service` and `/home/core/services/vault-discovery@.service`)
* enough to start `etcd` and `fleet`

## Deploy the base infrastructure

Fill in the blanks in the configuration file:

    $ cp terraform.tfvars.example terraform.tfvars
    $ terraform apply

## CoreOS

Login and check `fleetctl` sees all the cluster machines:

    fleetctl list-machines
    MACHINE         IP              METADATA
    6147c03d...     10.133.169.81   -
    [...]

Units are empty:

    fleetctl list-units
    UNIT    MACHINE ACTIVE  SUB

The unit files are empty:

    fleetctl list-unit-files
    UNIT            HASH    DSTATE  STATE   TARGET

### Vault Service (Unit) Files

Submit the service files sent by cloud-config under `services/`:

    fleetctl submit services/vault\@.service services/vault-discovery\@.service

Now we have unit files:

    fleetctl list-unit-files
    UNIT                            HASH    DSTATE          STATE           TARGET
    vault-discovery@.service        d15726b inactive        inactive        -
    vault@.service                  de5c96e inactive        inactive        -

We want to start a Vault service on TCP/8200:

    fleetctl load vault@8200.service
    Unit vault@8200.service loaded on 6147c03d.../10.133.169.81

    fleetctl load vault-discovery@8200.service
    Unit vault-discovery@8200.service loaded on 6147c03d.../10.133.169.81

### Start the Vault Service

Transfer the Vault configuration file from `config/` over to `/home/core/config`

    fleetctl start vault@8200.service
    Unit vault@8200.service launched on 6147c03d.../10.133.169.81

Check the status:

<pre>
fleetctl status vault@8200.service
● vault@8200.service - Vault Service
   Loaded: loaded (/run/fleet/units/vault@8200.service; linked-runtime; vendor preset: disabled)
   Active: active (running) since Tue 2015-05-05 21:04:15 UTC; 2s ago
May 05 21:04:15 core-1 docker[1628]: fdaa9c66787e: Download complete
May 05 21:04:15 core-1 docker[1628]: fdaa9c66787e: Download complete
May 05 21:04:15 core-1 docker[1628]: Status: Image is up to date for sjourdan/vault:latest
May 05 21:04:15 core-1 systemd[1]: Started Vault Service.
May 05 21:04:15 core-1 docker[1637]: ==> Vault server configuration:
May 05 21:04:15 core-1 docker[1637]: Log Level: info
May 05 21:04:15 core-1 docker[1637]: Mlock: supported: true, enabled: true
May 05 21:04:15 core-1 docker[1637]: Backend: consul (HA available)
May 05 21:04:15 core-1 docker[1637]: Listener 1: tcp (addr: "0.0.0.0:8200", tls: "disabled")
May 05 21:04:15 core-1 docker[1637]: ==> Vault server started! Log data will stream in below:
</pre>

Get from etcd the public IP and port to use:

    etcdctl get /announce/services/vault8200
    188.166.87.74:8200

### Use the Vault Service

On your workstation you can now use Vault:

    export VAULT_ADDR='http://188.166.87.74:8200'
    vault init
    vault --help

### Vault Container Logs

Tail the 100 last line of container's logs:

    fleetctl journal -lines=100 -f vault@8200.service
    -- Logs begin at Tue 2015-05-05 17:13:23 UTC, end at Tue 2015-05-05 17:19:14 UTC. --
    [...]

If needed, attach a terminal to debug:

    docker exec -t -i <CID> /bin/sh

### Stop the service

    fleetctl stop vault@8200.service

### Destroy the Service Unit files

If needed:

    fleetctl destroy vault@8200.service
    fleetctl destroy vault@.service

### Destroy the demo infrastructure.

    terraform destroy

## Debug

To get the etcd discovery address:

    grep DISCOVERY /run/systemd/system/etcd.service.d/20-cloudinit.conf

To try to validate the cloud-config.yml: [validator](https://coreos.com/validate/)

To apply a new cloudinit:

    sudo /usr/bin/coreos-cloudinit --oem=digitalocean
    sudo /usr/bin/coreos-cloudinit --from-file conf.yml
