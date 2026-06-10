#!/bin/bash
cd wg-easy && sudo docker compose down
cd ../Caddy && sudo docker compose down
sudo docker compose up -d
cd ../wg-easy && sudo docker compose up -d
