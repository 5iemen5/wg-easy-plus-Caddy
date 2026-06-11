

# WireGuard + Caddy reverse proxy setup guide

This is a deployment guide for hosting a secure WireGuard VPN using **wg-easy** and **Caddy** as a reverse proxy with automatic HTTPS.
# Table of Contents

- [What is wg-easy?](#what-is-wg-easy)
- [Architecture](#architecture)
- [Firewall Configuration](#firewall-configuration)
- [Helper Scripts](#helper-scripts)
- [Step 1: Secure the Administrator Password (bcrypt)](#step-1-secure-the-administrator-password-bcrypt)
- [Step 2: Configure Caddy](#step-2-configure-caddy)
- [Step 3: Configure wg-easy](#step-3-configure-wg-easy)
- [Step 4: Deploy](#step-4-deploy)
- [Security Warning](#security-warning)
---



## What is wg-easy?

**wg-easy** is a web-based management interface for the WireGuard VPN engine. It eliminates the need to manually manage cryptographic keys, peer configurations, and routing tables through the command line.

With wg-easy, you can:

* Generate WireGuard client profiles with a single click
* Monitor connected devices and bandwidth usage in real time
* Configure mobile devices instantly using QR codes
* Manage VPN peers through a simple web interface

---

## Architecture

### WireGuard

The VPN engine responsible for encrypted network tunneling.

* Public Port: `51820/UDP`

### wg-easy Dashboard

The management interface running only on the internal Docker network.

* Internal Port: `80/TCP`
* Not directly exposed to the internet

### Caddy Reverse Proxy

Acts as the public entry point.

Responsibilities:

* Automatic SSL/TLS certificate provisioning
* HTTPS termination
* Secure reverse proxying to the internal wg-easy dashboard

Public Ports:

* `80/TCP` (Let's Encrypt verification)
* `443/TCP` (HTTPS)

---

# Server Requirements

## Firewall Configuration

Before deployment, ensure your firewall allows the following inbound traffic:

| Port  | Protocol | Purpose                     |
| ----- | -------- | --------------------------- |
| 22    | TCP      | SSH administration          |
| 80    | TCP      | HTTP challenge verification |
| 443   | TCP      | HTTPS dashboard access      |
| 51820 | UDP      | WireGuard VPN traffic       |

### UFW Example

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 51820/udp
```

---

## Helper Scripts
### `get-docker.sh`

Installs Docker and Docker Compose on supported Linux distributions. Run this script before continuing if Docker is not already installed.


### `checkports.sh`

Verifies that all required ports are open and listening correctly.

### `reload.sh`

Safely recreates the Docker stack after configuration changes.

---

# Configuration

## Step 1: Secure the Administrator Password (bcrypt)

Recent versions of wg-easy require passwords to be stored as bcrypt hashes rather than plain text.

### Generate a Hash

1. Choose a strong administrator password.
2. Generate a bcrypt hash using a trusted generator.
3. Copy the resulting hash.

### Docker Compose Formatting Requirement

When placing a bcrypt hash inside `docker-compose.yml`, every `$` character must be doubled:

```text
$  →  $$
```

Example:

```text
$2y$10$abcdef...
```

becomes:

```text
$$2y$$10$$abcdef...
```

This prevents Docker Compose from interpreting the hash as an environment variable.

> ⚠️ **Security Notice**
>
> Never share your administrator password or bcrypt hash publicly, including screenshots, forum posts, or Git commits.

---

## Step 2: Configure Caddy

Edit your `Caddyfile`:

```caddy
your-domain.duckdns.org {

    # Email used for Let's Encrypt notifications
    email your-email@example.com

    # Forward requests to the internal wg-easy container
    reverse_proxy wg-easy:80
}
```

Replace:

* `your-domain.duckdns.org`
* `your-email@example.com`

with your own values.

---

## Step 3: Configure wg-easy

Edit your `docker-compose.yml`:

```yaml
version: '3.8'

services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy

    environment:
      - WG_HOST=your-domain.duckdns.org
      - PASSWORD_HASH=$$2y$$10$$YourDoubledDollarSignHashHere
      - PORT=80

    ports:
      - "51820:51820/udp"

      # IMPORTANT:
      # Do NOT expose the management UI directly
      # - "51821:51821/tcp"
```

### Important Changes

#### Set the public hostname

```yaml
WG_HOST=your-domain.duckdns.org
```

#### Use the bcrypt password hash

```yaml
PASSWORD_HASH=$$2y$$10$$...
```

#### Move the internal web server to port 80

```yaml
PORT=80
```

#### Hide the dashboard from the public internet

Comment out:

```yaml
- "51821:51821/tcp"
```

This ensures all dashboard access goes through Caddy and HTTPS.

---

## Step 4: Deploy

Start or restart the stack:

```bash
./reload.sh
```

In theory. during startup, Caddy will:

1. Reach Let's Encrypt through port `80/TCP`
2. Complete domain ownership verification
3. Obtain a trusted SSL certificate
4. Begin serving the dashboard over HTTPS

Once complete, visit:

```text
https://your-domain.duckdns.org
```

You should see the **wg-easy** management interface.

---

# Alternative: Direct HTTP Access (No Reverse Proxy)

If you need to bypass Caddy and access the dashboard directly via IP address:

### Re-enable the dashboard port

```yaml
ports:
  - "51820:51820/udp"
  - "51821:51821/tcp"
```

### Open the firewall

```bash
sudo ufw allow 51821/tcp
```

### Redeploy

```bash
./reload.sh
```

### Access the Dashboard

```text
http://YOUR_SERVER_IP:51821
```

---

## Security Warning

> ⚠️ **WARNING**
>
> When using plain HTTP, administrator credentials travel across the network without encryption.
>
> Anyone capable of intercepting the traffic may be able to read usernames, passwords, and session information.
>
> HTTPS through Caddy is strongly recommended for any internet-accessible deployment.

---

# Final Verification Checklist

* [ ] Firewall ports opened (`22`, `80`, `443`, `51820`)
* [ ] Domain DNS record points to the server
* [ ] bcrypt hash generated and escaped with `$$`
* [ ] `WG_HOST` configured correctly
* [ ] Dashboard port `51821/TCP` disabled
* [ ] Caddy reverse proxy configured
* [ ] Docker stack restarted successfully
* [ ] HTTPS certificate issued
* [ ] wg-easy dashboard accessible through your domain

If everything is configured correctly, opening your domain in a browser should display the **wg-easy** web interface over a secure HTTPS connection.
