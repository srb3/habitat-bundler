BUNDLE_NAME="automate-backend-deployment-bundle"
BUNDLE_VERSION="v0.0.1"
source ./utils.sh

SERVICES=(
  core/hab/0.82.0/20190605214032
  core/hab-sup/0.82.0/20190605220053
  core/hab-launcher/11300/20190605211433
  chef/automate-backend-deployment/0.1.127/20190702114140
)

make_pkgs_and_keys_dir
main
archive ${BUNDLE_NAME} ${BUNDLE_VERSION} ${KEY_PATH} ${PKG_PATH}
clean_pkgs_and_keys_dir
