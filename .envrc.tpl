export PROJECT_NAME=jitsi-deploy
export DEPLOYMENT_ENVIRONMENT=dev  # dev, live, local
export PROJECT_ROOT=${PWD}
export PATH="${PROJECT_ROOT}:${PATH}"

# Cloud Provider Secrets
export HCLOUD_TOKEN=
export VAGRANT_IP=10.180.0.111
export CF_API_EMAIL=
export CF_API_KEY=

# Cloud Provider Variables
export HCLOUD_IMAGE=ubuntu-20.04
export HCLOUD_LOCATION=nbg1
export HCLOUD_SERVER_TYPE=cx11
export DNS_PROVIDER=cloudflare
export ROOT_SSH_USER=root
export PRIMARY_SSH_USER=ubuntu

# Container Secrets
export ACME_EMAIL=
export TRAEFIK_BASICAUTH_USERS=''

# Container Variables
export DOMAIN=jitsi.meet
export DOMAIN_TRAEFIK=router.${DOMAIN}

export ACME_DOMAIN=${DOMAIN}
export ACME_CERTS_DIR=/media/certs/${ACME_DOMAIN}
