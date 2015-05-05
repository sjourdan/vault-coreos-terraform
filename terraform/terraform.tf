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
  etcd2:
    # generate a new token for each cluster: https://discovery.etcd.io/new
    discovery: https://discovery.etcd.io/1cebf45fc192bd4013bf4b4e7634097f
    # multi-region and multi-cloud deployments need to use $public_ipv4
    advertise-client-urls: http://$public_ipv4:2379
    listen-client-urls: http://0.0.0.0:2379
    listen-peer-urls: http://$private_ipv4:2380
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
