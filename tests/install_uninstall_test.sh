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
  -m) printf '%s\n' "${FAKE_UNAME_M:-x86_64}" ;;
  *) printf 'Linux\n' ;;
esac
EOF

  cat > "${fake_bin}/curl" <<'EOF'
#!/usr/bin/env bash
url=""
destination=""
write_out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      destination="$2"
      shift 2
      ;;
    -w)
      write_out="$2"
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

if [[ "${url}" == "https://github.com/nkguo/vohive-release/releases/latest" ]]; then
  [[ -n "${write_out}" ]] || exit 1
  printf 'https://github.com/nkguo/vohive-release/releases/tag/v1.0.1'
  exit 0
fi

if [[ -n "${destination}" ]]; then
  if [[ "${url}" == */SHA256SUMS ]]; then
    cat > "${destination}" <<'SUMS'
test-checksum  vohive_v1.0.1_linux_amd64
test-checksum  vohive_v1.0.1_linux_arm64
test-checksum  vohive_v1.0.1_linux_armv7
SUMS
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

assert_latest_asset_for_arch() {
  local uname_arch="$1"
  local release_arch="$2"
  local test_name="${uname_arch//[^0-9A-Za-z]/-}"
  local fake_bin="${TEST_TMP}/fake-bin-${test_name}"
  local curl_log="${TEST_TMP}/curl-${test_name}.log"
  make_install_fakes "${fake_bin}"

  local output
  if ! output="$(
    CURL_LOG="${curl_log}" \
      FAKE_UNAME_M="${uname_arch}" \
      PATH="${fake_bin}:${PATH}" \
      VOHIVE_DOWNLOAD_PROXY="https://should-not-be-used.example" \
      bash "${REPO_DIR}/install.sh" --dry-run --no-systemd 2>&1
  )"; then
    printf '%s\n' "${output}" >&2
    fail "latest install should succeed for ${uname_arch}"
  fi

  local requests
  requests="$(cat "${curl_log}")"
  assert_contains "${requests}" 'https://github.com/nkguo/vohive-release/releases/latest' 'latest install should resolve the release tag without the GitHub API'
  assert_contains "${requests}" "https://github.com/nkguo/vohive-release/releases/download/v1.0.1/vohive_v1.0.1_linux_${release_arch}" "${uname_arch} should select the ${release_arch} asset"
  assert_contains "${requests}" 'https://github.com/nkguo/vohive-release/releases/download/v1.0.1/SHA256SUMS' 'checksum should come from the resolved release'
  assert_not_contains "${requests}" 'api.github.com' 'latest install must not query the rate-limited API'
  assert_not_contains "${requests}" 'should-not-be-used.example' 'the removed download proxy variable must not affect requests'
}

test_latest_install_maps_all_supported_architectures() {
  assert_latest_asset_for_arch x86_64 amd64
  assert_latest_asset_for_arch amd64 amd64
  assert_latest_asset_for_arch aarch64 arm64
  assert_latest_asset_for_arch arm64 arm64
  assert_latest_asset_for_arch armv7 armv7
  assert_latest_asset_for_arch armv7l armv7
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
    test_latest_install_maps_all_supported_architectures
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
    test_latest_install_maps_all_supported_architectures
    test_uninstall_reports_preserved_data_by_default
    test_purge_removes_the_entire_application_directory
    test_purge_can_preserve_configuration
    ;;
  *)
    fail "unknown test: $1"
    ;;
esac
printf 'PASS: %s\n' "${1:-all}"
