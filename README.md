# VoHive Release

VoHive 的公开分发仓库，提供 Linux 二进制发布资产、一键安装与卸载脚本，以及部署和运维说明。

## 免责声明

> [!WARNING]
> VoHive 仅供个人内部测试使用，严禁商业使用，也不得用于任何违法或违规场景。
>
> 使用者应遵守所在地法律法规，并自行承担因违规或不当使用产生的全部责任。使用本软件即表示接受本声明。

## 功能概览

- 网页和 Bot 收发短信
- 多卡统一管理
- 实体 eSIM 和 eUICC 管理，包括加卡、切卡和删卡
- Telegram Bot、飞书 Bot 和 QQ Bot
- 在满足条件时进行 VoWiFi 测试
- 通过 `/vocall` 发起 VoWiFi 模拟外呼测试

## 支持环境

### 操作系统

安装脚本仅支持 Linux，推荐使用：

- Debian 或 Ubuntu
- 树莓派系统
- 支持 systemd 的 NAS 系统

使用 `--no-systemd` 可以只安装二进制文件。Docker 部署不依赖安装脚本。

### CPU 架构

安装脚本会通过 `uname -m` 自动选择资产：

| 系统架构 | Release 资产 |
| --- | --- |
| `x86_64`、`amd64` | `vohive-linux-amd64` |
| `aarch64`、`arm64` | `vohive-linux-arm64` |
| `armv7`、`armv7l` | `vohive-linux-armv7` |

每个 Release 还应提供 `SHA256SUMS`。安装脚本下载到校验文件时会自动验证二进制完整性。

### 硬件

推荐硬件包括：

- 移远 EC20CE 系列 4G 模组
- 移远 EM500Q 5G 模组
- 高通 410 Wi-Fi 板等可运行 Debian 或 OpenWrt 的设备
- 其他常见的高速 4G 或 5G USB 模组

设备需要具备 SIM 卡槽，或者搭配带 SIM 卡槽的 USB 底板。

## 快速安装

### 直连 GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh | bash
```

### 使用下载代理

无法稳定访问 GitHub 时，可通过代理下载安装脚本和 Release 资产：

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh \
  | VOHIVE_DOWNLOAD_PROXY=https://gh-proxy.com bash
```

安装最新版时，脚本直接使用 GitHub 官方的 `releases/latest/download` 地址，不调用 GitHub API。这样可以避免匿名 API 限流或公共代理共享出口导致的 `403`。

## 安装选项

### 指定版本

版本号可以带或不带 `v` 前缀：

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh \
  | bash -s -- --version 1.5.5
```

使用代理安装指定版本：

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh \
  | VOHIVE_DOWNLOAD_PROXY=https://gh-proxy.com bash -s -- --version 1.5.5
```

### 仅安装二进制

不创建或启动 systemd 服务：

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh \
  | bash -s -- --no-systemd
```

安装后可手动启动：

```bash
/opt/vohive/bin/vohive -c /opt/vohive/config/config.yaml
```

### 预览安装操作

`--dry-run` 会完成版本和资产下载检查，但不会写入系统安装目录或修改 systemd：

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh \
  | bash -s -- --dry-run
```

### 覆盖默认配置

默认情况下，重复安装不会覆盖已有的 `config.yaml`。如需重新生成最小配置，可传入 `--force`：

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh \
  | bash -s -- --force
```

> [!CAUTION]
> `--force` 会覆盖 `/opt/vohive/config/config.yaml`，执行前请备份现有配置。

### 环境变量

| 环境变量 | 默认值 | 说明 |
| --- | --- | --- |
| `VOHIVE_DOWNLOAD_PROXY` | 空 | Release 下载代理前缀，例如 `https://gh-proxy.com` |
| `VOHIVE_RELEASE_REPO` | `nkguo/vohive-release` | Release 所在的 GitHub 仓库，主要用于测试或镜像仓库 |

可用的命令行选项：

| 选项 | 说明 |
| --- | --- |
| `--version <X.Y.Z\|latest>` | 安装指定版本或最新版 |
| `--no-systemd` | 不安装 systemd 服务 |
| `--dry-run` | 预览操作，不修改系统安装目录 |
| `--force` | 覆盖已有的默认配置文件 |
| `-h`、`--help` | 显示帮助 |

## 安装后的检查

使用 systemd 安装后，检查服务状态：

```bash
systemctl status vohive --no-pager
```

查看实时日志：

```bash
journalctl -u vohive -f
```

默认访问地址：

```text
http://服务器IP:7575
```

默认 Web 账号和密码均为 `admin`。首次登录后应立即修改密码，并避免将管理端口直接暴露到不受信任的公网。

## 安装目录

| 内容 | 路径 |
| --- | --- |
| 主程序 | `/opt/vohive/bin/vohive` |
| 上一版本备份 | `/opt/vohive/bin/vohive.bak` |
| 配置文件 | `/opt/vohive/config/config.yaml` |
| 数据目录 | `/opt/vohive/data` |
| 日志目录 | `/opt/vohive/logs` |
| systemd 服务 | `/etc/systemd/system/vohive.service` |

## 升级与回滚

重新执行安装命令即可升级。安装脚本会在覆盖现有二进制前，将它备份为 `/opt/vohive/bin/vohive.bak`。如果 systemd 安装或启动失败，脚本会自动恢复上一版本并尝试重新启动服务。

已有配置默认会保留；只有显式传入 `--force` 时才会覆盖配置文件。

## 卸载

### 卸载程序并保留数据

默认卸载会停止并禁用 systemd 服务，删除服务文件、主程序和二进制备份，但保留配置、数据和日志：

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/uninstall.sh | bash
```

保留的目录为：

- `/opt/vohive/config`
- `/opt/vohive/data`
- `/opt/vohive/logs`

### 完整卸载

删除服务、程序、配置、数据、日志以及整个 `/opt/vohive` 目录：

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/uninstall.sh \
  | bash -s -- --purge
```

> [!CAUTION]
> `--purge` 会永久删除 VoHive 的配置、数据和日志，请先备份需要保留的内容。

### 完整卸载但保留配置

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/uninstall.sh \
  | bash -s -- --purge --keep-config
```

该命令会保留 `/opt/vohive/config`，删除程序、数据和日志。

### 通过代理获取卸载脚本

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/nkguo/vohive-release/main/uninstall.sh \
  | bash -s -- --purge
```

### 预览卸载操作

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/uninstall.sh \
  | bash -s -- --dry-run --purge
```

## Docker 部署

Docker 部署与脚本安装相互独立。下面以 `v1.5.5` 的离线镜像为例：

```bash
curl -fL \
  https://github.com/nkguo/vohive-release/releases/download/v1.5.5/docker_iniwex_vohive_1.5.5_latest.tar \
  -o docker_iniwex_vohive_1.5.5_latest.tar
docker load -i docker_iniwex_vohive_1.5.5_latest.tar
```

创建目录：

```bash
mkdir -p vohive/{config,data,logs}
cd vohive
```

创建 `config/config.yaml`：

```yaml
server:
  port: ":7575"

web:
  username: "admin"
  password: "admin123"
```

创建 `docker-compose.yml`：

```yaml
services:
  vohive:
    image: iniwex/vohive:latest
    pull_policy: never
    container_name: vohive
    restart: unless-stopped
    network_mode: host
    privileged: true
    volumes:
      - ./config:/app/config
      - ./data:/app/data
      - ./logs:/app/logs
    environment:
      - TZ=Asia/Shanghai
      - CONFIG_PATH=/app/config/config.yaml
    devices:
      - /dev:/dev
```

启动容器：

```bash
docker compose up -d
```

查看状态和日志：

```bash
docker compose ps
docker compose logs -f vohive
```

Docker 部署同样通过 `http://服务器IP:7575` 访问。由于程序需要直接访问模组设备，示例使用了 `privileged`、`/dev` 透传和主机网络；请仅在可信主机上运行。

## ModemManager 共存

VoHive 在 QMI 模式下会优先通过 `qmi-proxy` 打开控制口，因此可以与系统 `ModemManager` 共用 QMI 通道。

同时运行两个管理方时，不建议让两边同时管理拨号、APN 或数据连接。Docker 部署使用 AT 模式时，也需要关闭宿主机的 `ModemManager`，避免设备占用冲突。

## 可选的 USBNET 模式切换

只有确认模组当前模式不合适时，才需要执行以下操作：

```bash
sudo apt update
sudo apt install -y socat

echo 'AT+QCFG="usbnet",0;+CFUN=1,1' | sudo socat - /dev/ttyUSB2,crnl
```

- `AT+QCFG="usbnet",0`：切换到常见的 QMI 模式
- `AT+CFUN=1,1`：重启模组
- `/dev/ttyUSB2`：示例 AT 口，实际路径应根据设备调整

切换 USBNET 模式会导致模组重新枚举，远程操作前请确认不会因此失去设备连接。

## Bot 常用命令

| 命令 | 说明 |
| --- | --- |
| `/list` | 查看设备列表 |
| `/sms 设备ID` | 查看最近短信 |
| `/send 设备ID 号码 内容` | 发送短信 |
| `/rotate 设备ID` | 切换 IP |
| `/esim 设备ID` | 查看 eSIM profile |
| `/switch 设备ID 序号或ICCID` | 切换 eSIM profile |
| `/vocall 设备ID 号码` | 发起 VoWiFi 模拟呼叫测试 |

## 常见问题

### 下载时出现 403

先确认使用的是本 README 中的新安装命令。新版安装脚本不会访问 `api.github.com`；最新版二进制直接通过 `releases/latest/download` 下载。

如果直连 GitHub 的 Raw 或 Release 地址仍然返回 `403` 或连接超时，请使用“使用下载代理”中的完整命令，并确保下载脚本和 `VOHIVE_DOWNLOAD_PROXY` 同时配置。不要只给脚本地址加代理而遗漏环境变量，否则后续 Release 资产仍会直连 GitHub。

### 服务启动失败

```bash
systemctl status vohive --no-pager
journalctl -u vohive -n 200 --no-pager
```

重点检查配置格式、端口占用、模组设备权限，以及 `ModemManager` 是否占用了设备。

### 网页无法访问

确认服务正在运行并监听 `7575` 端口，同时检查服务器防火墙、安全组和路由设置。不要为了排障长期将管理端口暴露到公网。

### 普通卸载后目录仍然存在

这是默认的数据保护行为。普通卸载会保留配置、数据和日志；确认不再需要这些内容后，使用 `--purge` 完整卸载。

## VoWiFi 说明

- VoWiFi 能否使用取决于运营商、号码状态、设备配置和网络环境，并非只要联网即可使用
- 如果只需要短信、代理池或多模组管理，可以不启用 VoWiFi
- 程序禁止中国大陆运营商 SIM 卡发起 VoWiFi，请遵守当地法律法规

已知可用于 VoWiFi 测试的运营商包括：

- CTE UK
- CMLINK UK
- giffgaff UK
- VOXI UK
- Vodafone UK
- 3 UK
- Vodafone DE
- Telekom DE
- O2 DE
- T-Mobile US
- RedPocket US
- Lyca US
- AT&T US

未列出不代表一定不兼容，仅表示尚未验证。

## 程序截图

![VoHive 界面截图 1](https://cdn.nodeimage.com/i/rnGhjMfPlMatrdxQMPogawI3d5OGc1Fu.png)

![VoHive 界面截图 2](https://cdn.nodeimage.com/i/GGAj5ua1dK4vZihroXV0pUmT7COonPnQ.png)

![VoHive 界面截图 3](https://cdn.nodeimage.com/i/hX90MLQqjmgkaPkZt4Pz4uCM1lHmDBx4.png)

![VoHive 界面截图 4](https://cdn.nodeimage.com/i/jbbwBuP1Zu9iPpfZrSsXzftGo0et5i4F.png)

![VoHive 界面截图 5](https://cdn.nodeimage.com/i/P7BpZu8fF98622Q3VCZlafg4aBHVM8Qu.png)

![VoHive 界面截图 6](https://cdn.nodeimage.com/i/X5Ps5w9AHo1Qas6DDsnxYnbrfYcVhAfV.png)
