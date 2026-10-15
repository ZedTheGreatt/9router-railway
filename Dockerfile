# This repository contains Railway deployment configuration, not the 9Router source.
# Use the official multi-platform image; it already sets PORT, HOSTNAME,
# NODE_ENV, DATA_DIR, and exposes port 20128.
FROM decolua/9router:latest
