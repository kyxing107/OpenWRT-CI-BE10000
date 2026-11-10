#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY
#
# 定制版：仅拉取用户选定的第三方插件仓库（2026-11-10）
#   主题 1-7 全部 + 27 组 LianXia233 系列 + openclash / mosdns / lucky / openlist

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}
	local REPO_PATH="./package/$REPO_NAME"

	echo " "

	# 删除本地可能存在的不同名称的软件包
	for NAME in "${PKG_LIST[@]}"; do
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ./feeds/luci/ ./feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not fonud directory: $NAME"
		fi
	done

	# 克隆 GitHub 仓库
	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git" $REPO_PATH

	# 处理克隆的仓库
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find $REPO_PATH/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./package \;
		rm -rf $REPO_PATH
	fi
}

# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg（可选，从大杂烩中提取子包）" "额外同名包（可选）"

#===== 主题组 1-7 =====
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"
UPDATE_PACKAGE "fluent" "LazuliKao/luci-theme-fluent" "main"
UPDATE_PACKAGE "footstrap" "VizzleTF/luci-theme-footstrap" "main"
UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "master"
UPDATE_PACKAGE "kucat-config" "sirpdboy/luci-app-kucat-config" "master"
UPDATE_PACKAGE "shadcn" "eamonxg/luci-theme-shadcn" "main"
UPDATE_PACKAGE "vantage" "anothaDev/luci-theme-vantage" "main"

#===== openclash =====
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"

#===== mosdns =====
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"

#===== openlist（OpenList / Alist 分支）=====
UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"

#===== lucky（gdy666 官方版，仓库内含 lucky 核心 + luci-app-lucky + 中文包）=====
UPDATE_PACKAGE "lucky" "gdy666/luci-app-lucky" "main" "pkg" "luci-app-lucky luci-i18n-lucky-zh-cn"

#===== 27 组：LianXia233 系列（机型/模组专用，已拉取，默认不编入固件）=====
UPDATE_PACKAGE "airpi3000m-fancontrol" "LianXia233/luci-app-airpi3000m-fancontrol" "main"
UPDATE_PACKAGE "chfs" "LianXia233/luci-app-chfs" "main"
UPDATE_PACKAGE "fm350" "LianXia233/luci-app-fm350" "main"
UPDATE_PACKAGE "h5000m-netmode" "LianXia233/luci-app-h5000m-netmode" "main"
UPDATE_PACKAGE "mt5700" "LianXia233/luci-app-mt5700" "main"
UPDATE_PACKAGE "mt5700m" "LianXia233/luci-app-mt5700m" "main"
UPDATE_PACKAGE "netmonitor" "LianXia233/luci-app-netmonitor" "main"
UPDATE_PACKAGE "qmodem-generic" "LianXia233/luci-app-qmodem-generic" "main"

#===== 可选：openlist2 需要较新 Golang 时启用（默认关闭）=====
# 若编译报 "go: requires go >= 1.25" 之类错误，取消下面两行注释后重新编译。
# （会替换整个 golang feed，影响其他 Go 包，请确认后再启用）
#rm -rf feeds/packages/lang/golang
#git clone --depth=1 --single-branch --branch 26.x https://github.com/sbwml/packages_lang_golang.git feeds/packages/lang/golang

#引入私有扩展脚本
if [ -f "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh" ]; then
	source "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh"
fi
