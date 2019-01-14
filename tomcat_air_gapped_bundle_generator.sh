BUNDLE_NAME="tomcat-bundle"
BUNDLE_VERSION="v0.2.0"
source ./utils.sh
# latest stable
SERVICES=(
  core/jdk8/8.172.0/20180608174812
  core/tomcat8/8.5.9/20180609193916
)

make_pkgs_and_keys_dir
main
archive ${BUNDLE_NAME} ${BUNDLE_VERSION} ${KEY_PATH} ${PKG_PATH}
clean_pkgs_and_keys_dir
