#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d)"
trap 'rm -rf "${TEST_TMP}"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  [[ "${haystack}" == *"${needle}"* ]] || fail "${message}: missing ${needle}"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  [[ "${haystack}" != *"${needle}"* ]] || fail "${message}: unexpectedly found ${needle}"
}

assert_line() {
  local text="$1"
  local line="$2"
  local message="$3"

  printf '%s\n' "${text}" | grep -Fqx -- "${line}" || fail "${message}: missing line ${line}"
}

make_install_fakes() {
  local fake_bin="$1"
  mkdir -p "${fake_bin}"

  cat > "${fake_bin}/uname" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  -s) printf 'Linux\n' ;;
  -m) printf 'x86_64\n' ;;
  *) printf 'Linux\n' ;;
esac
EOF

  cat > "${fake_bin}/curl" <<'EOF'
#!/usr/bin/env bash
url=""
destination=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      destination="$2"
      shift 2
      ;;
    http://*|https://*)
      url="$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

printf '%s\n' "${url}" >> "${CURL_LOG}"
if [[ "${url}" == *api.github.com* ]]; then
  printf 'curl: (22) The requested URL returned error: 403\n' >&2
  exit 22
fi

if [[ -n "${destination}" ]]; then
  if [[ "${url}" == */SHA256SUMS ]]; then
    printf 'test-checksum  vohive-linux-amd64\n' > "${destination}"
  else
    printf 'binary\n' > "${destination}"
  fi
fi
EOF

  cat > "${fake_bin}/sha256sum" <<'EOF'
#!/usr/bin/env bash
printf 'test-checksum  %s\n' "$1"
EOF

  chmod +x "${fake_bin}/uname" "${fake_bin}/curl" "${fake_bin}/sha256sum"
}

test_latest_install_avoids_github_api() {
  local fake_bin="${TEST_TMP}/fake-bin"
  local curl_log="${TEST_TMP}/curl.log"
  make_install_fakes "${fake_bin}"

  local output
  if ! output="$(
    CURL_LOG="${curl_log}" \
      PATH="${fake_bin}:${PATH}" \
      VOHIVE_DOWNLOAD_PROXY="https://gh-proxy.com" \
      bash "${REPO_DIR}/install.sh" --dry-run --no-systemd 2>&1
  )"; then
    printf '%s\n' "${output}" >&2
    fail 'latest install should succeed without the GitHub API'
  fi

  local requests
  requests="$(cat "${curl_log}")"
  assert_not_contains "${requests}" 'api.github.com' 'latest install must not query the rate-limited API'
  assert_contains "${requests}" 'https://gh-proxy.com/https://github.com/nkguo/vohive-release/releases/latest/download/vohive-linux-amd64' 'latest asset should use the stable latest-download URL through the proxy'
  assert_contains "${requests}" 'https://gh-proxy.com/https://github.com/nkguo/vohive-release/releases/latest/download/SHA256SUMS' 'latest checksum should use the stable latest-download URL through the proxy'
}

test_uninstall_reports_preserved_data_by_default() {
  local output
  output="$(bash "${REPO_DIR}/uninstall.sh" --dry-run 2>&1)"

  assert_line "${output}" '[dry-run] rm -f /etc/systemd/system/vohive.service' 'uninstall should remove the service file even when systemctl is unavailable'
  assert_contains "${output}" '/opt/vohive/config' 'default uninstall should state that configuration is preserved'
  assert_contains "${output}" '/opt/vohive/data' 'default uninstall should state that data is preserved'
  assert_contains "${output}" '--purge' 'default uninstall should explain how to remove preserved files'
}

test_purge_removes_the_entire_application_directory() {
  local output
  output="$(bash "${REPO_DIR}/uninstall.sh" --dry-run --purge 2>&1)"

  assert_line "${output}" '[dry-run] rm -rf /opt/vohive' '--purge should remove the complete application directory'
}

test_purge_can_preserve_configuration() {
  local output
  output="$(bash "${REPO_DIR}/uninstall.sh" --dry-run --purge --keep-config 2>&1)"

  assert_line "${output}" '[dry-run] rm -rf /opt/vohive/bin /opt/vohive/data /opt/vohive/logs' '--keep-config should remove all non-configuration application directories'
  assert_not_contains "${output}" '[dry-run] rm -rf /opt/vohive/config' '--keep-config must preserve configuration'
  assert_contains "${output}" '/opt/vohive/config' '--keep-config should report the preserved configuration directory'
}

case "${1:-all}" in
  install)
    test_latest_install_avoids_github_api
    ;;
  uninstall-default)
    test_uninstall_reports_preserved_data_by_default
    ;;
  uninstall-purge)
    test_purge_removes_the_entire_application_directory
    ;;
  uninstall-keep-config)
    test_purge_can_preserve_configuration
    ;;
  all)
    test_latest_install_avoids_github_api
    test_uninstall_reports_preserved_data_by_default
    test_purge_removes_the_entire_application_directory
    test_purge_can_preserve_configuration
    ;;
  *)
    fail "unknown test: $1"
    ;;
esac
printf 'PASS: %s\n' "${1:-all}"
