#!/usr/bin/env bash
set -euo pipefail

# 基于 sources/build_conf 下的配置生成 QPKG 产物和配置
# 构建过程全部在本脚本内完成，且仅使用 wget

repo="openlistteam/openlist"
release_base="https://github.com/$repo/releases/download"

conf_file="sources/build_conf"

ver=""
all_arch=""
edit_arr=""

if [[ -f "$conf_file" ]]; then
  ver=$(grep -E '^VERSION=' "$conf_file" | tail -n 1 | cut -d= -f2-)
  all_arch=$(grep -E '^ARCHS=' "$conf_file" | tail -n 1 | cut -d= -f2-)
  edit_arr=$(grep -E '^EDITION=' "$conf_file" | tail -n 1 | cut -d= -f2-)
fi

if [[ -z "$ver" && -f "VERSION" ]]; then
  ver=$(cat "VERSION")
fi

if [[ -z "$ver" ]]; then
  echo "version 不能为空"
  exit 1
fi

all_arch_default="amd64 arm64 arm-5 arm-6 arm-7 mips mipsle mips64 mips64le s390x riscv64 loong64 loong64-abi1.0 ppc64le 386"
edit_arr_default="normal lite"

[[ -z "$all_arch" ]] && all_arch="$all_arch_default"
[[ -z "$edit_arr" ]] && edit_arr="$edit_arr_default"

mkdir -p sources
cat > "$conf_file" <<EOF
VERSION=$ver
ARCHS=$all_arch
EDITION=$edit_arr
EOF

rm -rf sources/qpkg-template
mkdir -p sources
cp -r qpkg-template sources/qpkg-template

mkdir -p sources/qpkg-template/logo
wget -q -O sources/qpkg-template/logo/openlist_512.png https://github.com/OpenListTeam/OpenList-Resource/raw/main/logo/openlist_512.png || true
wget -q -O sources/qpkg-template/logo/openlist_256.png https://github.com/OpenListTeam/OpenList-Resource/raw/main/logo/openlist_256.png || true
wget -q -O sources/qpkg-template/logo/openlist_128.png https://github.com/OpenListTeam/OpenList-Resource/raw/main/logo/openlist_128.png || true

mkdir -p sources/binpkg
wget -q -O sources/md5.txt "$release_base/$ver/md5.txt"
wget -q -O sources/md5-lite.txt "$release_base/$ver/md5-lite.txt"

for arch in $all_arch; do
  for edit in $edit_arr; do
    if [[ "$edit" == "normal" ]]; then
      pkg="openlist-linux-${arch}.tar.gz"
      mdfile="sources/md5.txt"
    else
      pkg="openlist-linux-${arch}-lite.tar.gz"
      mdfile="sources/md5-lite.txt"
    fi

    wget -q -O "sources/binpkg/$pkg" "$release_base/$ver/$pkg"
    md5_infile=$(grep "$pkg" "$mdfile" | awk '{print $1}')
    md5_calc=$(md5sum "sources/binpkg/$pkg" | awk '{print $1}')
    if [[ "$md5_infile" != "$md5_calc" ]]; then
      echo "MD5校验失败：$pkg"
      exit 1
    fi
  done
done

mkdir -p qpkg-output release_batch
cp -r sources/qpkg-template release_batch/

for arch in $all_arch; do
  for edit in $edit_arr; do
    if [[ "$edit" == "normal" ]]; then
      pkg="openlist-linux-${arch}.tar.gz"
    else
      pkg="openlist-linux-${arch}-lite.tar.gz"
    fi

    QPKGDIR="openlist-${ver}-${arch}-${edit}"
    mkdir -p "$QPKGDIR/share/openlist"

    if [[ ! -f "sources/binpkg/$pkg" ]]; then
      echo "缺少 sources/binpkg/$pkg"
      exit 1
    fi

    tar -xf "sources/binpkg/$pkg" -C "$QPKGDIR/share/openlist"
    sed "s/__VERSION__/$ver/g" sources/qpkg-template/package.rst > "$QPKGDIR/package.rst"

    # 自动选择logo最大分辨率
    if [[ -f sources/qpkg-template/logo/openlist_512.png ]]; then
      cp sources/qpkg-template/logo/openlist_512.png "$QPKGDIR/package_icon.png"
    elif [[ -f sources/qpkg-template/logo/openlist_256.png ]]; then
      cp sources/qpkg-template/logo/openlist_256.png "$QPKGDIR/package_icon.png"
    elif [[ -f sources/qpkg-template/logo/openlist_128.png ]]; then
      cp sources/qpkg-template/logo/openlist_128.png "$QPKGDIR/package_icon.png"
    else
      touch "$QPKGDIR/package_icon.png"
    fi

    cp sources/qpkg-template/openlist.sh "$QPKGDIR/"
    chmod +x "$QPKGDIR/openlist.sh"

    tar -czf "qpkg-output/${QPKGDIR}.qpkg.tar.gz" -C "$QPKGDIR" .
    mkdir -p "release_batch/$QPKGDIR"
    cp -r "$QPKGDIR"/* "release_batch/$QPKGDIR/"
    cp "qpkg-output/${QPKGDIR}.qpkg.tar.gz" release_batch/
    rm -rf "$QPKGDIR"
  done
done
