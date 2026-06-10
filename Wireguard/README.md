Setup Summary
This setup deployed a WireGuard VPN (wg-easy) behind a reverse proxy (Caddy) using Docker Compose on a cloud server, ensuring your admin dashboard is securely encrypted.

The Role of Caddy
Caddy acts as a secure front door. Because wg-easy does not natively encrypt its web UI, Caddy intercepts incoming web traffic, wraps it in HTTPS (using a self-signed TLS certificate for your public IP address), and safely passes it to the dashboard over an internal Docker network.

The Importance of Ports
Proper port management in your firewall (UFW) and Docker configs is critical here:

Open 80/tcp & 443/tcp, udp: Allows Caddy to handle HTTP and HTTPS traffic to serve the web dashboard.

Open 51820/udp: The dedicated port for the heavily encrypted WireGuard VPN tunnel. This must be open for your devices to connect to the VPN.

Closed 51821/tcp: The default wg-easy web UI port was deliberately removed from the public configuration. Keeping this closed prevents anyone from bypassing Caddy and intercepting your admin password in plain text
