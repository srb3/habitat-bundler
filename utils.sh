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

# these hab packages need to be installed in order (as far as I know)
# otherwise we get dep issues when we do a hab pkg install <local-file>
# might be a better way to do this
# https://github.com/habitat-sh/on-prem-builder/issues/117
CORE=(
core-linux-headers-*x86_64*.hart
core-glibc-*x86_64*.hart
core-gcc-libs-*x86_64*.hart
core-gdbm-*x86_64*.hart
core-gmp-*x86_64*.hart
core-pcre-*x86_64*.hart
core-grep-*x86_64*.hart
core-groff-*x86_64*.hart
core-attr-*x86_64*.hart
core-acl-*x86_64*.hart
core-libcap-*x86_64*.hart
core-sed-*x86_64*.hart
core-zlib-*x86_64*.hart
core-binutils-*x86_64*.hart
core-coreutils-*x86_64*.hart
core-libtool-*x86_64*.hart
core-libffi-*x86_64*.hart
core-ncurses-*x86_64*.hart
core-cacerts-2018.03.07-*x86_64*.hart
core-openssl-*x86_64*.hart
core-readline-*x86_64*.hart
core-sqlite-*x86_64*.hart
core-bzip2-*x86_64*.hart
core-expat-*x86_64*.hart
core-python-*x86_64*.hart
core-nghttp2-*x86_64*.hart
core-xz-*x86_64*.hart
core-libarchive-*x86_64*.hart
core-libsodium-*x86_64*.hart
core-zeromq-*x86_64*.hart
core-proj-*x86_64*.hart
core-bash-*x86_64*.hart
core-libossp-uuid-*x86_64*.hart
core-db-*x86_64*.hart
core-less-*x86_64*.hart
core-perl-*x86_64*.hart
core-curl-*x86_64*.hart
core-gdal-*x86_64*.hart
core-geos-*x86_64*.hart
core-libxml2-*x86_64*.hart
core-postgresql-*x86_64*.hart
core-libedit-*x86_64*.hart
core-nginx-*x86_64*.hart
core-cyrus-sasl-*x86_64*.hart
core-libevent-*x86_64*.hart
core-memcached-*x86_64*.hart
core-aws-cli-*x86_64*.hart
core-minio-*x86_64*.hart
habitat-builder-datastore-*x86_64*.hart
habitat-builder-api-*x86_64*.hart
habitat-builder-api-proxy-*x86_64*.hart
habitat-builder-memcached*x86_64*.hart
habitat-builder-minio-*x86_64*.hart
)

# install all keys
for i in $(ls ${KEY_PATH}/*); do
  cat $i | ${HAB} origin key import
done

# install all packages that need to be installed in a particuler order
for i in ${CORE[@]}; do
  ${HAB} pkg install ${PKG_PATH}/$i
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
