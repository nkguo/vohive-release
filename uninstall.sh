#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
PURGE=0
KEEP_CONFIG=0

ROOT_DIR="/opt/vohive"
BIN_PATH="${ROOT_DIR}/bin/vohive"
BACKUP_PATH="${ROOT_DIR}/bin/vohive.bak"
SERVICE_PATH="/etc/systemd/system/vohive.service"
CONFIG_DIR="${ROOT_DIR}/config"
DATA_DIR="${ROOT_DIR}/data"
LOG_DIR="${ROOT_DIR}/logs"

log() { printf '[vohive-uninstall] %s\n' "$*"; }
err() { printf '[vohive-uninstall] ERROR: %s\n' "$*" >&2; }

usage() {
  cat <<USAGE
用法: uninstall.sh [选项]
  --purge        删除配置、数据、日志及整个 ${ROOT_DIR} 目录
  --keep-config  与 --purge 一起使用，完整卸载但保留配置
  --dry-run      仅显示将执行的操作
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

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --purge)
        PURGE=1
        shift
        ;;
      --keep-config)
        KEEP_CONFIG=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
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

main() {
  parse_args "$@"

  if command -v systemctl >/dev/null 2>&1; then
    run_root systemctl stop vohive || true
    run_root systemctl disable vohive || true
  fi
  run_root rm -f "${SERVICE_PATH}"
  if command -v systemctl >/dev/null 2>&1; then
    run_root systemctl daemon-reload || true
  fi

  run_root rm -f "${BIN_PATH}" "${BACKUP_PATH}"

  if [[ "${PURGE}" == "1" ]]; then
    if [[ "${KEEP_CONFIG}" == "1" ]]; then
      run_root rm -rf "${ROOT_DIR}/bin" "${DATA_DIR}" "${LOG_DIR}"
      log "卸载完成，已保留配置目录: ${CONFIG_DIR}"
    else
      run_root rm -rf "${ROOT_DIR}"
      log "完整卸载完成，已删除: ${ROOT_DIR}"
    fi
  else
    run_root rmdir "${ROOT_DIR}/bin" 2>/dev/null || true
    log "程序和 systemd 服务已卸载。"
    log "已保留配置、数据和日志: ${CONFIG_DIR} ${DATA_DIR} ${LOG_DIR}"
    log "如需完全删除，请重新运行卸载脚本并传入 --purge。"
  fi
}

main "$@"
