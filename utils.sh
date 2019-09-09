#!/bin/bash

BASE_PATH="."
BLDR_P="https://bldr.habitat.sh/v1/depot/pkgs"
BLDR_K="https://bldr.habitat.sh/v1/depot/origins"
BLDR_L="https://bldr.habitat.sh/v1/depot"
PKG_PATH="${BASE_PATH}/harts"
KEY_PATH="${BASE_PATH}/keys"
BIN_PATH="${BASE_PATH}/bin"
HAB_CLI_URL="https://api.bintray.com/content/habitat/stable/linux/x86_64/hab-%24latest-x86_64-linux.tar.gz?bt_package=hab-x86_64-linux"
HAB_BIN_TMP="/tmp/hab-latest-x86_64-linux.tar.gz"

function get_keys() {
  local keys=$(curl -s -H "Accept: application/json" ${1} | jq -r ".[] | .location")
  for k in ${keys}; do
    key=$(tr -d '"' <<< "$k")
    release=$(cut -d '/' -f 5 <<< "$key")
    if [[ ! -f ${2}/$release.pub ]]; then
      echo "curl -s -H \"Accept: application/json\" -o \"${2}/$release.pub\" \"${3}${key}\""
      curl -s -H "Accept: application/json" -o "${2}/$release.pub" "${3}${key}"
    fi
  done
}

function get_hab_cli() {
  curl -L -o /tmp/hab-latest-x86_64-linux.tar.gz ${HAB_CLI_URL}
  tar xzf ${HAB_BIN_TMP} --strip-components=1 -C ${BIN_PATH}
}

function get_dl() {
  if [[ ! -f ${2}/${3} ]]; then
    curl -s ${1} -o ${2}/${3}
  fi
}

function get_filename() {
 filename=$(curl -sI  ${1} | grep -o -E 'filename=.*$' | sed -e 's/filename=//'  | sed 's/"//g')
 echo ${filename} | sed $'s/[^[:print:]\t]//g'
}

function dload() {
  local t="download"
  local o=${1}; local p=${2}
  local v=${3}; local b=${4}
  url="${BLDR_P}/${o}/${p}/${v}/${b}/${t}"
  name=$(get_filename $url)
  get_dl $url ${PKG_PATH} $name
}

function get_u() {
  for row in $(curl -s ${1} | jq -c  ".${2}"); do
    local name=$(echo ${row} | jq -r '.name')
    local origin=$(echo ${row} | jq -r '.origin')
    local version=$(echo ${row} | jq -r '.version')
    local release=$(echo ${row} | jq -r '.release')
    dload ${origin} ${name} ${version} ${release}
  done
}

function latest() {
  local t="latest"
  local o=${1}; local p=${2}
  url="${BLDR_P}/${o}/${p}/${t}"
  get_u ${url} 'tdeps[]'
}

function version() {
  local t="$1/$2/$3/$4"
  url="${BLDR_P}/${t}"
  echo ${url}
  get_u ${url} 'tdeps[]'
}

function version_ident() {
  local t="$1/$2/$3/$4"
  url="${BLDR_P}/${t}"
  echo ${url}
  get_u ${url} 'ident'
}

function ident() {
  local t="latest"
  local o=${1}; local p=${2}
  url="${BLDR_P}/${o}/${p}/${t}"
  get_u ${url} 'ident'
}

function keys() {
  local t="keys"
  local o=${1};
  url="${BLDR_K}/${o}/${t}"
  get_keys ${url} ${KEY_PATH} ${BLDR_L}
}

function archive() {
  if [[ ! -f ${1}-${2}.tar.gz ]]; then
    if [ -z ${6+x} ]; then
      echo "no bin path to include";
      tar -zcvf ${1}-${2}.tar.gz ${3} ${4}
    else
      echo "including bin path ${5}"
      tar -zcvf ${1}-${2}.tar.gz ${3} ${4} ${5} ${6}
    fi
  fi
}

function clean_pkgs_and_keys_dir() {
  if [[ -d ${PKG_PATH} ]]; then
    rm -rf ${PKG_PATH}
  fi
  if [[ -d ${KEY_PATH} ]]; then
    rm -rf ${KEY_PATH}
  fi
}

function make_bin_dir() {
  if [[ ! -d ${BIN_PATH} ]]; then
    mkdir -p ${BIN_PATH}
  fi
}

function clean_bin_dir() {
  if [[ -d ${BIN_PATH} ]]; then
    rm -rf ${BIN_PATH}
  fi
}

function clean_install_file() {
  if [[ -f ${BASE_PATH}/install.sh ]]; then
    rm -rf ${BASE_PATH}/install.sh
  fi
}

function make_pkgs_and_keys_dir() {
  if [[ ! -d ${PKG_PATH} ]]; then
    mkdir -p ${PKG_PATH}
  fi

  if [[ ! -d ${KEY_PATH} ]]; then
    mkdir -p ${KEY_PATH}
  fi
}
# if we are bootstrapping the builder then we
# need to make a small install scritp
function make_install_script() {
  cat << "EOF" >${BASE_PATH}/install.sh
#!/bin/bash

PKG_PATH="harts"
KEY_PATH="keys"
BIN_PATH="bin"
HAB="/bin/hab"

cp ${BIN_PATH}/hab ${HAB}

${HAB} license accept

# these hab packages need to be installed in order (as far as I know)
# otherwise we get dep issues when we do a hab pkg install <local-file>
# might be a better way to do this
# https://github.com/habitat-sh/on-prem-builder/issues/117
CORE=(
core-linux-headers
core-glibc
core-gcc-libs
core-gdbm
core-gmp
core-pcre
core-grep
core-groff
core-attr
core-acl
core-libcap
core-sed
core-zlib
core-binutils
core-coreutils
core-libtool
core-libffi
core-ncurses
core-cacerts
core-openssl-fips
core-openssl
core-readline
core-sqlite
core-bzip2
core-expat
core-python
core-nghttp2
core-xz
core-libarchive
core-libsodium
core-zeromq
core-proj
core-bash
core-libossp-uuid
core-db
core-less
core-perl
core-curl
core-gdal
core-geos
core-libxml2
core-postgresql
core-libedit
core-nginx
core-cyrus-sasl
core-libevent
core-memcached
core-aws-cli
core-minio
habitat-builder-datastore
habitat-builder-api
habitat-builder-api-proxy
habitat-builder-memcached
habitat-builder-minio
)

# install all keys
for i in $(ls ${KEY_PATH}/*); do
  cat $i | ${HAB} origin key import
done

# install all packages that need to be installed in a particuler order
for i in ${CORE[@]}; do
  if ls ${PKG_PATH}/* | egrep "$i"; then
    ${HAB} pkg install ${PKG_PATH}/${i}-*x86_64*.hart
  fi
done

# install all packages (we just skip the previously installed ones)
for i in $(ls ${PKG_PATH}/*); do
  ${HAB} pkg install $i
done
EOF
  chmod +x ${BASE_PATH}/install.sh
}

function main() {
  for pkg in "${SERVICES[@]}"; do
    IFS='/' read -r -a array <<< "$pkg"
    version ${array[0]} ${array[1]} ${array[2]} ${array[3]}
    version_ident ${array[0]} ${array[1]} ${array[2]} ${array[3]}
    keys ${array[0]}
  done
}
