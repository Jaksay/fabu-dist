#!/usr/bin/env bash
set -Eeuo pipefail

repo=${FABU_REPO:-Jaksay/fabu-dist}

usage() {
    cat >&2 <<'TEXT'
用法: sudo bash bootstrap.sh <版本> [--sha256 <哈希>] [--verify-only]

  <版本>         形如 1.0.0，对应发布标签 v1.0.0
  --sha256       期望的安装包哈希；给定时必须完全匹配
  --verify-only  只下载并校验，不执行安装

环境变量:
  FABU_REPO      默认 Jaksay/fabu-dist
  FABU_BASE_URL  覆盖下载基地址（镜像或离线测试用）
TEXT
    exit 2
}

version=''
expected=''
verify_only=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --sha256)
            [[ $# -ge 2 ]] || usage
            expected=$2
            shift 2
            ;;
        --verify-only) verify_only=1; shift ;;
        -h|--help) usage ;;
        *)
            [[ -z $version ]] || usage
            version=$1
            shift
            ;;
    esac
done

[[ -n $version ]] || usage
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    echo '错误: 版本号应形如 1.0.0（不接受 latest）' >&2
    exit 2
}

tag=v$version
file=fabu-$version.tar.gz
base=${FABU_BASE_URL:-https://github.com/$repo/releases/download/$tag}

if command -v curl >/dev/null 2>&1; then
    fetch() { curl -fsSL "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
    fetch() { wget -q -O "$2" "$1"; }
else
    echo '错误: 需要 curl 或 wget 下载安装包' >&2
    exit 1
fi

if [[ $verify_only == 0 && $EUID != 0 ]]; then
    echo '错误: 安装需要 root，请用 sudo 运行；只校验可用 --verify-only' >&2
    exit 1
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "下载 $base/$file"
fetch "$base/$file" "$work/$file"
fetch "$base/$file.sha256" "$work/$file.sha256"

published=$(awk '{print $1}' "$work/$file.sha256")
actual=$(sha256sum "$work/$file" | awk '{print $1}')

if [[ -z $published ]]; then
    echo '错误: 校验文件为空' >&2
    exit 1
fi
if [[ $actual != "$published" ]]; then
    echo '错误: 安装包校验失败' >&2
    echo "  发布哈希: $published" >&2
    echo "  实际哈希: $actual" >&2
    exit 1
fi
if [[ -n $expected && $actual != "$expected" ]]; then
    echo '错误: 与 --sha256 指定的哈希不一致' >&2
    echo "  指定哈希: $expected" >&2
    echo "  实际哈希: $actual" >&2
    exit 1
fi

echo "校验通过: $actual"
if [[ $verify_only == 1 ]]; then
    exit 0
fi

tar -xzf "$work/$file" -C "$work"
echo '开始安装 ...'
bash "$work/fabu-$version/scripts/install.sh"
