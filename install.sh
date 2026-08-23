#!/usr/bin/env bash
set -euo pipefail

REPO="${VOHIVE_RELEASE_REPO:-nkguo/vohive-release}"
DOWNLOAD_PROXY="${VOHIVE_DOWNLOAD_PROXY:-}"
VERSION=""
NO_SYSTEMD=0
DRY_RUN=0
FORCE=0

ROOT_DIR="/opt/vohive"
INSTALL_DIR="${ROOT_DIR}/bin"
CONFIG_DIR="${ROOT_DIR}/config"
DATA_DIR="${ROOT_DIR}/data"
LOG_DIR="${ROOT_DIR}/logs"
BIN_PATH="${INSTALL_DIR}/vohive"
BACKUP_PATH="${INSTALL_DIR}/vohive.bak"
SERVICE_PATH="/etc/systemd/system/vohive.service"

log() { printf '[vohive-install] %s\n' "$*"; }
err() { printf '[vohive-install] 错误: %s\n' "$*" >&2; }

usage() {
  cat <<USAGE
用法: install.sh [选项]
  --version <X.Y.Z|latest>
  VOHIVE_DOWNLOAD_PROXY=<url-prefix> 使用下载代理（例如 https://gh-proxy.com）
  --no-systemd
  --dry-run
  --force
USAGE
}

run_root() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '[dry-run] %q' "$1"
    shift
    for arg in "$@"; do printf ' %q' "$arg"; done
    printf '\n'
    return 0
  fi

  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    err "需要 root 权限（请使用 root 用户或安装 sudo）。"
    exit 1
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "缺少命令: $1"
    exit 1
  }
}

proxy_url() {
  printf '%s/%s\n' "${DOWNLOAD_PROXY%/}" "$1"
}

fetch_url() {
  local url="$1"
  if [[ -n "${DOWNLOAD_PROXY}" ]]; then
    curl -fsSL --retry 2 --connect-timeout 10 "$(proxy_url "${url}")"
  else
    curl -fsSL --retry 2 --connect-timeout 10 "${url}"
  fi
}

download_file() {
  local url="$1"
  local destination="$2"

  local request_url="${url}"
  if [[ -n "${DOWNLOAD_PROXY}" ]]; then
    request_url="$(proxy_url "${url}")"
    log "使用下载代理: ${request_url}"
  else
    log "正在下载: ${request_url}"
  fi
  curl -fsSL --retry 2 --connect-timeout 10 "${request_url}" -o "${destination}"
}

resolve_version() {
  local v="$1"
  if [[ -n "${v}" && "${v}" != "latest" ]]; then
    v="${v#v}"
    v="${v#V}"
    printf '%s\n' "${v}"
    return 0
  fi

  local api_url="https://api.github.com/repos/${REPO}/releases/latest"
  local latest_json
  latest_json="$(fetch_url "${api_url}")"
  local resolved
  resolved="$(printf '%s\n' "${latest_json}" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  if [[ -z "${resolved}" ]]; then
    err "无法从 GitHub API 获取最新 Release 版本号。"
    exit 1
  fi
  resolved="${resolved#v}"
  resolved="${resolved#V}"
  printf '%s\n' "${resolved}"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version)
        VERSION="${2:-}"
        shift 2
        ;;
      --no-systemd)
        NO_SYSTEMD=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --force)
        FORCE=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "未知参数: $1"
        usage
        exit 1
        ;;
    esac
  done
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    armv7|armv7l) echo "armv7" ;;
    *)
      err "不支持的架构: $(uname -m)"
      exit 1
      ;;
  esac
}

install_default_config() {
  run_root mkdir -p "${INSTALL_DIR}" "${CONFIG_DIR}" "${DATA_DIR}" "${LOG_DIR}"
  if [[ "${DRY_RUN}" == "1" ]]; then
    return 0
  fi
  if [[ ! -f "${CONFIG_DIR}/config.yaml" || "${FORCE}" == "1" ]]; then
    run_root tee "${CONFIG_DIR}/config.yaml" >/dev/null <<CFG
server:
  port: ":7575"

web:
  username: "admin"
  password: "admin"
CFG
  fi
}

install_systemd() {
  local tmp_unit="$1"
  cat > "${tmp_unit}" <<UNIT
[Unit]
Description=VoHive Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=${ROOT_DIR}
ExecStart=${BIN_PATH} -c ${CONFIG_DIR}/config.yaml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
UNIT

  run_root install -m 0644 "${tmp_unit}" "${SERVICE_PATH}"
  run_root systemctl daemon-reload
  run_root systemctl enable vohive
  run_root systemctl restart vohive
  run_root systemctl is-active --quiet vohive
}

print_access_info() {
  local port="7575"
  local links="http://127.0.0.1:${port}"
  local ip
  local ips=""

  if command -v hostname >/dev/null 2>&1; then
    ips="$(hostname -I 2>/dev/null || true)"
  fi

  for ip in ${ips}; do
    if [[ "${ip}" == "127."* || "${ip}" == "::1" ]]; then
      continue
    fi
    links="${links} http://${ip}:${port}"
  done

  log "最小配置已生成: ${CONFIG_DIR}/config.yaml"
  log "默认 Web 账号密码: admin / admin"
  for ip in ${links}; do
    log "一键访问链接: ${ip}"
  done
}

main() {
  parse_args "$@"

  need_cmd curl
  need_cmd uname

  local os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  if [[ "${os}" != "linux" ]]; then
    err "不支持的系统: ${os}"
    exit 1
  fi

  local arch
  arch="$(detect_arch)"
  local resolved_version
  resolved_version="$(resolve_version "${VERSION}")"
  if ! [[ "${resolved_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.-]+)?$ ]]; then
    err "无效版本号: ${resolved_version}"
    exit 1
  fi

  local asset="vohive-linux-${arch}"
  local release_tag="v${resolved_version}"
  local base="https://github.com/${REPO}/releases/download/${release_tag}"

  local tmp
  tmp="$(mktemp -d)"
  trap "rm -rf '${tmp}'" EXIT

  local downloaded="${tmp}/${asset}"

  log "已解析版本: ${resolved_version}"
  if ! download_file "${base}/${asset}" "${downloaded}"; then
    local legacy_asset
    local legacy_downloaded=0
    for legacy_asset in \
      "vohive_v${resolved_version}_linux_${arch}" \
      "vohive_${resolved_version}_linux_${arch}"; do
      log "主资产下载失败，尝试历史资产: ${legacy_asset}"
      if download_file "${base}/${legacy_asset}" "${downloaded}"; then
        asset="${legacy_asset}"
        legacy_downloaded=1
        break
      fi
    done

    if [[ "${legacy_downloaded}" != "1" ]]; then
      err "无法下载适用于 ${arch} 的 Release 资产"
      exit 1
    fi
  fi

  local checksums="${tmp}/SHA256SUMS"
  if download_file "${base}/SHA256SUMS" "${checksums}"; then
    need_cmd sha256sum
    local expected_checksum
    expected_checksum="$(awk -v asset="${asset}" '$2 == asset || $2 == "*" asset { print $1; exit }' "${checksums}")"
    if [[ -z "${expected_checksum}" ]]; then
      err "SHA256SUMS 中缺少 ${asset}"
      exit 1
    fi

    local actual_checksum
    actual_checksum="$(sha256sum "${downloaded}" | awk '{ print $1 }')"
    if [[ "${actual_checksum}" != "${expected_checksum}" ]]; then
      err "二进制 SHA-256 校验失败"
      exit 1
    fi
    log "SHA-256 校验通过"
  else
    log "当前 Release 未提供 SHA256SUMS，跳过校验"
  fi

  chmod +x "${downloaded}"

  local extracted="${downloaded}"
  if [[ ! -f "${extracted}" ]]; then
    err "下载的二进制文件不存在"
    exit 1
  fi

  if [[ -x "${BIN_PATH}" ]]; then
    log "检测到已安装版本，备份到: ${BACKUP_PATH}"
    run_root cp -f "${BIN_PATH}" "${BACKUP_PATH}"
  fi

  local rollback_needed=0
  rollback() {
    if [[ "${rollback_needed}" == "1" && -f "${BACKUP_PATH}" ]]; then
      err "正在回滚到上一个版本"
      run_root cp -f "${BACKUP_PATH}" "${BIN_PATH}" || true
      if [[ "${NO_SYSTEMD}" == "0" && -x "$(command -v systemctl || true)" ]]; then
        run_root systemctl restart vohive || true
      fi
    fi
  }

  install_default_config
  rollback_needed=1
  run_root install -m 0755 "${extracted}" "${BIN_PATH}"

  if [[ "${NO_SYSTEMD}" == "0" ]]; then
    need_cmd systemctl
    local unit_tmp="${tmp}/vohive.service"
    if ! install_systemd "${unit_tmp}"; then
      rollback
      err "systemd 安装或启动失败"
      exit 1
    fi
  fi

  rollback_needed=0
  log "安装完成: ${BIN_PATH} (${resolved_version})"
  if [[ "${NO_SYSTEMD}" == "0" ]]; then
    log "服务状态: 运行中（systemd）"
    print_access_info
  else
    log "已跳过 systemd 安装（--no-systemd）"
    log "手动启动命令: ${BIN_PATH} -c ${CONFIG_DIR}/config.yaml"
    print_access_info
  fi
}

main "$@"
