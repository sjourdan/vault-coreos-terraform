# Configure the DigitalOcean Provider
provider "digitalocean" {
    token = "${var.do_token}"
}

# Create a new SSH key
resource "digitalocean_ssh_key" "default" {
    name = "DO SSH Key"
    public_key = "${file("${var.ssh_key_file}.pub")}"
}

# Create a new vault droplet
resource "digitalocean_droplet" "coreos-1" {
    image = "coreos-stable"
    name = "core-1"
    region = "ams3"
    size = "512mb"
    ssh_keys = ["${digitalocean_ssh_key.default.id}"]
    private_networking = true
    user_data = <<EOF
#cloud-config
coreos:
  etcd:
    # generate a new token for each cluster from https://discovery.etcd.io/new
    discovery: https://discovery.etcd.io/c1750e36ea1804f21877cb53c9d66bad
    addr: $private_ipv4:4001
    peer-addr: $private_ipv4:7001
  fleet:
    public-ip: $private_ipv4
  units:
    - name: etcd.service
      command: start
    - name: fleet.service
      command: start
EOF
}

output "core-1.ipv4_address" {
	value = "${digitalocean_droplet.coreos-1.ipv4_address}"
}
