BUNDLE_NAME="chef-load"
BUNDLE_VERSION="v4.0.0-20190306204146"
source ./utils.sh

SERVICES=(
  core/hab/0.82.0/20190605214032
  core/hab-sup/0.82.0/20190605220053
  core/hab-launcher/11300/20190605211433
  chef/chef-load/4.0.0/20190306204146
)

make_pkgs_and_keys_dir
make_bin_dir # creats a directory to store the hab binary
get_hab_cli # pulls down the lates hab binary
make_install_script # writes the install script, this is a script which makes sure the correct order of packages are installed
main
archive ${BUNDLE_NAME} ${BUNDLE_VERSION} ${KEY_PATH} ${PKG_PATH} ${BIN_PATH} ${BASE_PATH}/install.sh
clean_bin_dir # remove the bin directory
clean_pkgs_and_keys_dir
clean_install_file # remove the install file
