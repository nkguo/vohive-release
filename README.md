<img src="/assets/images/logo.png" alt="VoHive" width="300" height="93">

# VoHive - 探索版

面向高通 4G/LTE/5G 模组的多设备管理、移动网络代理、短信通信、eSIM 和 VoWiFi 综合管理平台。

> [!IMPORTANT]
> 本仓库是基于 VoHive 进行二次开发的公开发行仓库，只用于发布安装与卸载脚本、使用文档和已构建的二进制或容器资产。
>
> **本项目仅供个人内部测试、学习和技术研究使用，严禁商业使用，也不得用于任何违法或违规场景。**

## 文档导航

- [项目说明](#项目说明)
- [特别鸣谢](#特别鸣谢)
- [免责声明](#免责声明)
- [核心功能](#核心功能)
- [支持环境](#支持环境)
- [脚本安装](#脚本安装)
- [Docker 部署](#docker-部署)
- [卸载](#卸载)
- [常见问题](#常见问题)

## 项目说明

VoHive 面向可运行 Linux 的蜂窝通信设备，将多模组发现与管理、SOCKS5/HTTP 代理、短信与 USSD、eSIM/eUICC、VoWiFi/IMS、通知转发和 Web 运维能力整合到一个服务中。

项目主要针对移远 EC20、EC21、EC25、EG25、EM20、EM500Q 等高通平台模组，也可根据设备暴露的控制接口适配其他兼容模组。实际支持能力取决于模组固件、USB 组合模式、Linux 内核驱动、SIM 卡、运营商和网络环境。

## 特别鸣谢

VoHive 最初由 [iniwex5](https://github.com/iniwex5) 创作和实现，本项目是在原版 VoHive 基础上进行的二次开发与持续维护。

特别感谢原作者在蜂窝模组管理、代理服务、短信、eSIM 和 VoWiFi 等方向上的探索与贡献。本项目的形成离不开原作提供的思路和基础。

为尊重原作者及相关权利，本项目不对外公开源代码，仅通过本仓库提供安装脚本、使用文档和编译后的发行资产。

本项目是独立维护的二次开发版本，不代表原作者官方立场，原作者也不对本项目后续修改、发布和使用承担责任。

## 免责声明

> [!WARNING]
> VoHive 仅供个人内部测试、学习和技术研究使用，严禁商业使用，也不得用于任何违法或违规场景。
>
> 使用者应遵守所在地法律法规，并自行承担因违规或不当使用产生的全部责任。使用本软件即表示接受本声明。

- 本仓库是发行资产仓库，不是 VoHive 应用程序的源代码仓库。
- VoHive 应用程序及其发行资产未采用 MIT、Apache-2.0、GPL 等开源许可证，公开可见或可下载不等于开放源代码，也不构成开源授权。
- 未经相应权利人明确授权，不得复制后再分发、出售、出租、再许可、修改后重新发布，或移除、篡改相关版权和归属信息。
- 原版 VoHive 的相关权利归原作者及相应权利人所有；二次开发内容、发行脚本和文档的相关权利归各自权利人所有。
- 项目使用的第三方组件、依赖和协议实现分别受其自身许可证及权利声明约束，本声明不会取代第三方许可证。

如需进行个人内部测试、学习和技术研究以外的使用或分发，请先取得相关权利人的明确授权。

## 核心功能


| 功能模块         | 主要能力                                                  |
| ------------ | ----------------------------------------------------- |
| 多模组管理        | 自动发现 USB 热插拔设备，统一管理多个模组，显示运营商、信号、网络、SIM 卡和运行状态        |
| 多后端控制        | 支持 AT、QMI 和 MBIM 设备形态，根据模组能力管理控制口、数据接口及运行策略           |
| 移动网络代理       | 内建 SOCKS5 和 HTTP 代理服务，支持多实例并发，并按设备网卡绑定蜂窝出口            |
| 前置代理策略       | 管理上游代理和基于国家或运营商的路由规则，为代理服务和 VoWiFi 提供出口策略             |
| 短信中心         | 多设备短信收发、投递状态、联系人会话、历史记录、SQLite 持久化和通知转发               |
| USSD 终端      | 发起、继续和取消 USSD 会话，处理余额查询等交互式运营商指令                      |
| eSIM 与 eUICC | 查看芯片和 EID、下载 Profile、启用、停用、重命名、删除及处理 eUICC 通知         |
| VoWiFi 与 IMS | 利用 SIM 硬件鉴权建立 VoWiFi/IMS 通信链路，支持状态诊断、重连及相关通信测试        |
| 通知中心         | 支持 Telegram、Email、PushPlus、Bark、飞书、QQ 和 Webhook 等通知渠道 |
| Web 管理与 API  | 提供仪表盘、设备、代理、短信、日志、通知和系统设置页面，以及 OpenAPI 接口文档           |
| 运维与安全        | 管理员认证、账号密码修改、实时日志、系统信息、配置持久化和 systemd 服务管理            |


部分功能对硬件和运营商有严格依赖，不支持的模组或网络不会因为软件中存在对应入口而自动获得相关能力。

## 技术实现

- 后端：Go、Gin、GORM、Viper
- 前端：Vue 3、Vite、Tailwind CSS、Element Plus
- 数据存储：SQLite
- 设备接口：AT、QMI、MBIM
- 部署方式：Linux 单二进制、systemd、Docker
- 发布架构：amd64、arm64、armv7

本节仅说明技术构成，不表示本仓库提供上述组件的应用程序源代码。

## 支持环境

### 操作系统

安装脚本仅支持 Linux，推荐使用：

- Debian 或 Ubuntu
- 树莓派系统
- 支持 systemd 的 NAS 或软路由系统

使用 `--no-systemd` 可以只安装二进制文件。Docker 部署不依赖安装脚本。

### CPU 架构

安装脚本会通过 `uname -m` 自动选择 Release 资产：


| 系统架构              | Release 资产                 |
| ----------------- | -------------------------- |
| `x86_64`/`amd64`  | `vohive_v<版本>_linux_amd64` |
| `aarch64`/`arm64` | `vohive_v<版本>_linux_arm64` |
| `armv7`/`armv7l`  | `vohive_v<版本>_linux_armv7` |


### 硬件

常见测试硬件包括：

- 移远 EC20、EC21、EC25、EG25 系列 4G 模组
- 移远 EM20、EM500Q 等 5G 模组
- 可运行 Debian 或 OpenWrt 的高通平台设备
- 其他提供兼容 AT、QMI 或 MBIM 接口的 USB 蜂窝模组

设备需要具备 SIM 卡槽，或者搭配带 SIM 卡槽的 USB 底板。eSIM、QMI、MBIM 和 VoWiFi 能力需以实际模组及固件支持情况为准。

## 脚本安装

### 安装最新版

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh | bash
```

无法稳定访问 GitHub 时，可通过代理安装：

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh \
  | VOHIVE_DOWNLOAD_PROXY=https://gh-proxy.com bash
```

### 指定版本

版本号可以带或不带 `v` 前缀：

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh \
  | bash -s -- --version 1.0.1
```

### 仅安装二进制

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh \
  | bash -s -- --no-systemd
```

安装后可手动启动：

```bash
/opt/vohive/bin/vohive -c /opt/vohive/config/config.yaml
```

### 预览安装操作

`--dry-run` 会完成资产下载检查，但不会写入系统安装目录或修改 systemd：

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh \
  | bash -s -- --dry-run
```

### 覆盖默认配置

重复安装默认不会覆盖已有的 `config.yaml`。如需重新生成最小配置，可传入 `--force`：

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh \
  | bash -s -- --force
```

> [!CAUTION]
> `--force` 会覆盖 `/opt/vohive/config/config.yaml`，执行前请备份现有配置。

### 参数说明


| 选项或变量 | 默认值 | 说明 |
| ----------------- | -------- | -------------- |
| `--version <X.Y.Z \| latest>` | `latest` | 指定要安装的版本，支持具体版本号或 `latest` |
| `--no-systemd` | 关闭 | 不安装 systemd 服务 |
| `--dry-run` | 关闭 | 预览操作，不修改系统安装目录 |
| `--force` | 关闭 | 覆盖已有的默认配置文件 |
| `VOHIVE_DOWNLOAD_PROXY` | 空 | Release 下载代理前缀，例如 `https://gh-proxy.com` |


## 安装后的检查

检查服务状态：

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

默认 Web 账号和密码均为 `admin`。首次登录后应立即修改用户名和密码，并避免将管理端口直接暴露到不受信任的公网。

## 安装目录


| 内容         | 路径                                   |
| ---------- | ------------------------------------ |
| 主程序        | `/opt/vohive/bin/vohive`             |
| 上一版本备份     | `/opt/vohive/bin/vohive.bak`         |
| 配置文件       | `/opt/vohive/config/config.yaml`     |
| 数据目录       | `/opt/vohive/data`                   |
| 日志目录       | `/opt/vohive/logs`                   |
| systemd 服务 | `/etc/systemd/system/vohive.service` |


## 升级与回滚

重新执行安装命令即可升级。安装脚本会在覆盖现有二进制前，将它备份为 `/opt/vohive/bin/vohive.bak`。如果 systemd 安装或启动失败，脚本会自动恢复上一版本并尝试重新启动服务。

已有配置默认会保留；只有显式传入 `--force` 时才会覆盖配置文件。

## Docker 部署

- **Docker Hub**：`docker.io/nkguo/vohive`
- **GHCR**：`ghcr.io/nkguo/vohive`

选择其中一个镜像源：

```bash
docker pull docker.io/nkguo/vohive:1.0.1
```

或者：

```bash
docker pull ghcr.io/nkguo/vohive:1.0.1
```

### 准备目录

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

### Docker Compose

创建 `docker-compose.yml`：

```yaml
services:
  vohive:
    image: docker.io/nkguo/vohive:1.0.1
    container_name: vohive
    restart: unless-stopped
    network_mode: host
    privileged: true
    volumes:
      - ./config:/app/config
      - ./data:/app/data
      - ./logs:/app/logs
    environment:
      TZ: Asia/Shanghai
      CONFIG_PATH: /app/config/config.yaml
    devices:
      - /dev:/dev
```

如果使用 GHCR，将 `image` 改为 `ghcr.io/nkguo/vohive:1.0.1`。

启动并查看状态：

```bash
docker compose up -d
docker compose ps
docker compose logs -f vohive
```

Docker 部署同样通过 `http://服务器IP:7575` 访问。程序需要直接访问蜂窝模组设备，因此示例使用了 `privileged`、`/dev` 透传和主机网络；请仅在可信主机上运行。

## 卸载

### 卸载程序并保留数据

默认卸载会停止并禁用 systemd 服务，删除服务文件、主程序和二进制备份，但保留配置、数据和日志：

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/uninstall.sh | bash
```

保留的目录包括：

- `/opt/vohive/config`
- `/opt/vohive/data`
- `/opt/vohive/logs`

### 完整卸载

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/uninstall.sh \
  | bash -s -- --purge
```

> [!CAUTION]
> `--purge` 会永久删除整个 `/opt/vohive`，包括配置、数据和日志。执行前请备份需要保留的内容。

### 完整卸载但保留配置

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/uninstall.sh \
  | bash -s -- --purge --keep-config
```

该命令保留 `/opt/vohive/config`，删除程序、数据和日志。

### 预览卸载操作

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/uninstall.sh \
  | bash -s -- --dry-run --purge
```

## ModemManager 共存

VoHive 在 QMI 模式下会优先通过 `qmi-proxy` 打开控制口，可与系统 `ModemManager` 共用 QMI 通道。

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


| 命令                      | 说明               |
| ----------------------- | ---------------- |
| `/list`                 | 查看设备列表           |
| `/sms 设备ID`             | 查看最近短信           |
| `/send 设备ID 号码 内容`      | 发送短信             |
| `/rotate 设备ID`          | 切换 IP            |
| `/esim 设备ID`            | 查看 eSIM Profile  |
| `/switch 设备ID 序号或ICCID` | 切换 eSIM Profile  |
| `/vocall 设备ID 号码`       | 发起 VoWiFi 模拟呼叫测试 |


不同通知渠道支持的命令可能不同，具体以当前版本界面和实际返回为准。

## 常见问题

### 下载时出现 403

如果 GitHub Raw 或 Release 地址返回 `403` 或连接超时，请检查当前网络、DNS、防火墙以及 GitHub 的可访问性。

### 服务启动失败

```bash
systemctl status vohive --no-pager
journalctl -u vohive -n 200 --no-pager
```

重点检查配置格式、端口占用、模组设备权限、USB 模式，以及 `ModemManager` 是否占用设备。

### 网页无法访问

确认服务正在运行并监听 `7575` 端口，同时检查服务器防火墙、安全组和路由设置。不要为了排障长期将管理端口暴露到公网。

### 普通卸载后目录仍然存在

这是默认的数据保护行为。普通卸载会保留配置、数据和日志；确认不再需要这些内容后，使用 `--purge` 完整卸载。

### 功能入口存在但操作失败

模组功能并不完全统一。请检查设备控制口、固件版本、驱动、SIM 状态、运营商限制和日志信息。eSIM、USSD、MBIM、QMI 和 VoWiFi 尤其依赖硬件及网络支持。

## VoWiFi 说明

- VoWiFi 能否使用取决于运营商、号码状态、SIM 鉴权、设备配置和网络环境，并非只要联网即可使用
- 如果只需要短信、代理或多模组管理，可以不启用 VoWiFi
- 程序禁止中国大陆运营商 SIM 卡发起 VoWiFi，请遵守当地法律法规

已知进行过 VoWiFi 测试的运营商包括：

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

未列出不代表一定不兼容，仅表示尚未验证。网络、套餐和运营商策略变化也可能影响已经测试过的号码。

## 程序截图

![VoHive 界面截图 1](https://cdn.nodeimage.com/i/rnGhjMfPlMatrdxQMPogawI3d5OGc1Fu.png)

![VoHive 界面截图 2](https://cdn.nodeimage.com/i/GGAj5ua1dK4vZihroXV0pUmT7COonPnQ.png)

![VoHive 界面截图 3](https://cdn.nodeimage.com/i/hX90MLQqjmgkaPkZt4Pz4uCM1lHmDBx4.png)

![VoHive 界面截图 4](https://cdn.nodeimage.com/i/jbbwBuP1Zu9iPpfZrSsXzftGo0et5i4F.png)

![VoHive 界面截图 5](https://cdn.nodeimage.com/i/P7BpZu8fF98622Q3VCZlafg4aBHVM8Qu.png)

![VoHive 界面截图 6](https://cdn.nodeimage.com/i/X5Ps5w9AHo1Qas6DDsnxYnbrfYcVhAfV.png)
