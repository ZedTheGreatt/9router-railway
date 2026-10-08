# The upstream image already sets PORT=20128, HOSTNAME=0.0.0.0, NODE_ENV=production
# and DATA_DIR=/app/data, and EXPOSEs 20128 — nothing to override here. This file
# exists so Railway builds the template from this repo alongside railway.toml.
FROM decolua/9router
