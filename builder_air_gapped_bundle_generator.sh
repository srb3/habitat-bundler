# the name for the archive produced.
BUNDLE_NAME="${1:-on-prem-builder-bundle}"
# this version number is used to track structual changes to the generated
# archive. it does not directly match a version of the builder services.
BUNDLE_VERSION="v${2:-0.6.0}"
# get current dir
S_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# source the utils script, utils contains the commands listed in the main section
source ${S_DIR}/utils.sh

# top level builder services
# - habitat builder services - Salim said to pull from latest, not stable
# - devoptimist builder services - using latest stable versios
#     these are forks of the corrisponding habitat builder services.
#     The forks demonstrate running the services as non hab and non root users.
#     This is nessaesry for some customers.
# - core sup and launcher: using latest stable versions
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

# === main section ===#
make_pkgs_and_keys_dir # creates the harts and keys directorys
make_bin_dir # creats a directory to store the hab binary
get_hab_cli # pulls down the lates hab binary
make_install_script # writes the install script, this is a script which makes sure the correct order of packages are installed
main # uses the SERVICES array to pull down all the required keys and packages to satisfy all of dependencies and transitive dependencies of each item in the array
archive ${BUNDLE_NAME} ${BUNDLE_VERSION} ${KEY_PATH} ${PKG_PATH} ${BIN_PATH} ${BASE_PATH}/install.sh # tar gzip the keys hart and bin directorys, and the install.sh file
clean_pkgs_and_keys_dir # remove the harts and keys directorys
clean_bin_dir # remove the bin directory
clean_install_file # remove the install file
