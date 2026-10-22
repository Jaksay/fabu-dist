# Fabu 安装包

Fabu 源码在私有仓库，这里只放安装包和安装脚本。版本见 Releases。

## 安装

```sh
curl -fsSLO https://raw.githubusercontent.com/Jaksay/fabu-dist/main/scripts/bootstrap.sh
sudo bash bootstrap.sh 1.0.0
```

## 手动安装

在 Releases 下载 `fabu-<版本>.tar.gz`，校验后解包：

```sh
sha256sum -c fabu-1.0.0.tar.gz.sha256
tar xzf fabu-1.0.0.tar.gz
cd fabu-1.0.0
sudo bash scripts/install.sh
```

## 环境要求

Linux，Bash 4.3+，`tar`、`flock`、`sqlite3`（默认备份用）、非 root 的 `deploy` 用户。
