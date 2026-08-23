# Rollback

1. 直接安装旧版本：

```bash
curl -fsSL https://raw.githubusercontent.com/nkguo/vohive-release/main/install.sh | bash -s -- --version 1.2.2
```

2. 若升级失败且 `.bak` 存在，可手动恢复：

```bash
sudo cp /opt/vohive/bin/vohive.bak /opt/vohive/bin/vohive
sudo systemctl restart vohive
```
