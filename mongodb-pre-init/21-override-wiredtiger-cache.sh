# Replace WiredTiger cache size in mongod.conf added by 20-setup-wiredtiger-cache.sh
# with a command line argument that supports cache sizes less than 1GiB.
function setup_wiredtiger_cache() {
  local config_file
  config_file=${1:-$MONGODB_CONFIG_PATH}

  declare $(cgroup-limits)
  if [[ ! -v MEMORY_LIMIT_IN_BYTES || "${NO_MEMORY_LIMIT:-}" == "true" ]]; then
    return 0;
  fi

  # Remove cacheSizeGB from config file
  # Use temp file because we don't have write access to config file's directory
  local tmp_file="${HOME}/mongod.conf.tmp"
  sed 's/storage\.wiredTiger\.engineConfig\.cacheSizeGB.*//g' "${config_file}" > "${tmp_file}"
  cat "${tmp_file}" > "${config_file}"
  rm -f "${tmp_file}"

  # Add cache size in MiB as a command line argument
  cache_size_mb=$(python -c "min=1; limit=int(($MEMORY_LIMIT_IN_BYTES / pow(2,20) - 1) * 0.6); print( min if limit < min else limit)")
  mongo_common_args="--wiredTigerEngineConfigString=cache_size=${cache_size_mb}M ${mongo_common_args}"

  info "Overriding WiredTiger cache size to ${cache_size_mb}MiB"
}

setup_wiredtiger_cache ${CONTAINER_SCRIPTS_PATH}/mongod.conf.template
