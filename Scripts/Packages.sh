#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY
#
# 定制版：仅拉取用户选定的第三方插件仓库
# 2026-11-12 全量重新选择：
#   1 argon、9 vantage、12 openclash、21 openlist2、26 netwizard、50 lucky、
#   51-53 LED/风扇/灯光控制，另新增 AdGuard Home 与 PassWall
# 2026-11-12 追加：应用户要求去掉 ShadowsocksR Plus+，改用 PassWall（全量清单第 13 项）

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

#===== 主题（1 argon、9 vantage）=====
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"
UPDATE_PACKAGE "vantage" "anothaDev/luci-theme-vantage" "main"

#===== openclash（12）=====
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"

#===== openlist2（21，OpenList / Alist 分支）=====
UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"

#===== netwizard（26，网络向导）=====
UPDATE_PACKAGE "netwizard" "sirpdboy/luci-app-netwizard" "main"

#===== lucky（50，gdy666 官方版：核心 + LuCI + 中文包）=====
UPDATE_PACKAGE "lucky" "gdy666/luci-app-lucky" "main" "pkg" "luci-app-lucky luci-i18n-lucky-zh-cn"

#===== AdGuard Home（新增：kenzok78 适配版，针对 ImmortalWrt 24.10+/25.12 重构）=====
# 仓库根目录本身就是 package（根目录含 Makefile），克隆到 ./package/luci-app-adguardhome 即可。
# UPDATE_PACKAGE 会先清掉 feeds 里的同名官方包，正好避免与官方 adguardhome 冲突。
UPDATE_PACKAGE "adguardhome" "kenzok78/luci-app-adguardhome" "main"

#===== PassWall（替换原 ShadowsocksR Plus+；沿用上游 VIKINGYFY/OpenWRT-CI 的官方写法）=====
# 上游 Scripts/Packages.sh 第 62 行即：
#   UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
# 仓库根目录只有 luci-app-passwall/ 一个子包，用 pkg 模式提取到 ./package/ 即可。
# 代理核心（xray-core / sing-box / chinadns-ng / shadowsocks-rust / hysteria / dns2socks 等）
#   由目标源码树 feeds.conf.default 的 immortalwrt/packages 提供（已逐个验证存在），
#   故无需额外 clone Openwrt-Passwall/openwrt-passwall-packages，与上游保持一致。
# Makefile 原生定义 Nftables_Transparent_Proxy（default y if PACKAGE_firewall4），
#   适配目标 6.18 内核 + nftables；相比 SSR Plus+ 整仓 30+ 包，这里只引入 1 个 LuCI 包。
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"

#===== 灯光控制 RGB（53）=====
# 仓库内含 rgbcontrol（C 守护进程）与 luci-app-rgbcontrol（Lua CBI），
# 用 pkg 模式可一次把两个子目录都提取到 ./package/。
UPDATE_PACKAGE "rgbcontrol" "RuijieNetworksCommunity/luci-app-rgbcontrol" "master" "pkg" "luci-app-rgbcontrol"

#===== LED 配置（51）与风扇控制（52）=====
# 内核模块（kmod-leds-gpio / kmod-leds-pwm / kmod-hwmon-pwmfan / kmod-gpio-pwm）
# 由 6.18 源码树直接编译；fancontrol / luci-app-fancontrol 目标源码树已自带。
# 三项均无需额外拉取第三方仓库，只需在 Config/GENERAL.txt 里写 =y。

#===== 可选：openlist2 需要较新 Golang 时启用（默认关闭）=====
# 若编译报 "go: requires go >= 1.25" 之类错误，取消下面两行注释后重新编译。
# （会替换整个 golang feed，影响其他 Go 包，请确认后再启用）
#rm -rf feeds/packages/lang/golang
#git clone --depth=1 --single-branch --branch 26.x https://github.com/sbwml/packages_lang_golang.git feeds/packages/lang/golang

#引入私有扩展脚本
if [ -f "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh" ]; then
	source "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh"
fi
