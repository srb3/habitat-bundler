BUNDLE_NAME="${1:-on-prem-builder-bundle}"
BUNDLE_VERSION="v${2:-0.6.0}"
S_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${S_DIR}/utils.sh
# top level builder services
# Salim said to pull from latest, not stable
# for sup and launcher using latest stable
SERVICES=(
  core/hab-sup/0.72.0/20190103234046
  core/hab-launcher/9167/20181203215950
  devoptimist/builder-api/0.1.0/20190110164551
  devoptimist/builder-api-proxy/0.1.0/20190110185259
  devoptimist/builder-memcached/0.1.0/20190110164642
  devoptimist/builder-minio/0.1.0/20190110164837
  devoptimist/builder-datastore/9.6.9/20190110164626
  habitat/builder-api/8025/20181221003740
  habitat/builder-api-proxy/8017/20181218183317
  habitat/builder-memcached/7997/20181212200027
  habitat/builder-minio/7997/20181212200726
  habitat/builder-api/8025/20181221003740
)

make_pkgs_and_keys_dir
make_bin_dir
get_hab_cli
make_install_script
main
archive ${BUNDLE_NAME} ${BUNDLE_VERSION} ${KEY_PATH} ${PKG_PATH} ${BIN_PATH} ${BASE_PATH}/install.sh
clean_pkgs_and_keys_dir
clean_bin_dir
clean_install_file
