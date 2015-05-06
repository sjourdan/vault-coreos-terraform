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
    user_data = "${file("cloud-config.yml")}"
}

output "core-1.ipv4_address" {
	value = "${digitalocean_droplet.coreos-1.ipv4_address}"
}
