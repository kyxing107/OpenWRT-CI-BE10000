# 小米万兆路由器 · ImmortalWrt 定制编译（OpenWRT-CI）

> **自动编译已关闭**：本仓库不会每天自动重编，也不会自动清理/删除固件。只有你手动点 **Run workflow** 才会编译。

基于 [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI) 定制，用 GitHub Actions 云编译 **小米万兆路由器（`xiaomi_be10000`）** 的 ImmortalWrt 固件。仓库地址：<https://github.com/kyxing107/OpenWRT-CI-BE10000>。

---

## 一页速览

| 项目 | 值 |
| --- | --- |
| 目标设备 | 小米万兆路由器 **BE10000 零售版**（`xiaomi_be10000`） |
| ⚠️ 不要选 | `xiaomi_be7000`、`xiaomi_be10000-es`（工程样机）——刷错会变砖 |
| 平台 | `qualcommbe` / `ipq95xx` |
| 源码 | `VIKINGYFY/immortalwrt`，分支 `owrt` |
| 编译入口 | [`QCB-ALL.yml`](.github/workflows/QCB-ALL.yml) → [`WRT-CORE.yml`](.github/workflows/WRT-CORE.yml) |
| 管理地址 | `192.168.10.1`（U-Boot 界面是 `192.168.1.1`，别混） |
| 主机名 / 主题 | `OWRT` / `vantage` |
| WiFi | `OWRT` / `12345678`，首次登录无密码 |
| 首次刷机文件 | `xiaomi_be10000-squashfs-factory-*.ubi` |
| 后续升级文件 | `xiaomi_be10000-squashfs-sysupgrade-*.bin` |
| 编译耗时 | 首次约 3～6 小时；命中缓存后 1～2 小时 |

---

## 1. 编译一次固件（3 步）

1. 打开 [`Actions → QCB-ALL`](https://github.com/kyxing107/OpenWRT-CI-BE10000/actions/workflows/QCB-ALL.yml)，点 **Run workflow**。
2. 参数保持默认：**`TEST` 不勾选**（勾选就只生成 `.config`、不产固件），**`PACKAGE` 留空**，分支选 `main`。
3. 等待约 3～6 小时，完成后到 [Releases](https://github.com/kyxing107/OpenWRT-CI-BE10000/releases) 下载。

> **只用 `QCB-ALL` 这一个工作流。** 仓库里其余 `AIROHA-ALL` / `MTK-ALL` / `OWRT-ALL` / `QCA-ALL` 是上游保留的其他平台入口，与本设备无关，不要点。

**可选：先验证配置再正式编译。** 跑 [`WRT-TEST`](https://github.com/kyxing107/OpenWRT-CI-BE10000/actions/workflows/WRT-TEST.yml)，`CONFIG` 选 `IPQ95XX`、`SOURCE` 选 `VIKINGYFY/immortalwrt`、`BRANCH` 填 `owrt`、`TEST` 保持 `true`。它只生成 `.config` 并上传为 `Config-IPQ95XX-*.txt`，用来确认插件仓库拉取和配置语法正常，不产出固件。

**首次使用建议做一次设置（保险）**：打开 [Settings → Actions → General](https://github.com/kyxing107/OpenWRT-CI-BE10000/settings/actions)，把 **Workflow permissions** 设为 **Read and write permissions**。各工作流内已声明 `permissions: write-all`，正常够用；万一编译末尾发布 Release 报 `403`，回来改这里即可。

---

## 2. 下载与识别固件

Release 标签形如 `IPQ95XX-VIKINGYFY-owrt-YY.MM.DD-HH.MM.SS`。一次编译产出的是**一个平台包**，内含多个机型的十几个文件，**只需挑出这两个**：

```text
qualcommbe-ipq95xx-xiaomi_be10000-squashfs-factory-*.ubi      ← 首次刷机（U-Boot Web 界面）
qualcommbe-ipq95xx-xiaomi_be10000-squashfs-sysupgrade-*.bin   ← 后续升级（LuCI 里刷）
```

建议同时下载 `Config-IPQ95XX-*.txt`，它记录了这次编译的完整 `.config`，便于日后复现或排查。

---

## 3. 首次刷机（务必先做完再动手）

刷机**不是**在小米官方固件里直接升级，需要先换不死 U-Boot 和大分区表：

1. 用 XMiR-Patcher 之类工具，按当前官方固件版本解锁 SSH。
2. **备份原厂分区**，尤其 `mtd2`（MIBIB 分区表）、`mtd18`（APPSBL / U-Boot）和无线校准数据。备份文件请存到电脑，别只留在路由器上。
3. 写入高通版不死 U-Boot 与大分区表（写入前后用 `md5sum` / `mtd verify` 校验）：
   ```bash
   mtd write /tmp/mibib.bin /dev/mtd2
   mtd write /tmp/uboot.bin /dev/mtd18
   ```
4. 断电、按住 Reset 通电约 20 秒，灯变橙常亮后访问 `http://192.168.1.1` 进入 U-Boot Web 界面，刷 **factory 的 `.ubi`**。
5. 进系统后管理地址是 **`192.168.10.1`**。

> ⚠️ 刷第三方固件会失去保修；MLO、NFC 一碰连网、米家管理等原厂特性通常不可用；刷错机型固件或写错分区有变砖风险。分区操作前务必确认机型与分区编号。

---

## 4. 定制项说明

### 4.1 相对上游改了什么

| 文件 | 改动 |
| --- | --- |
| `Config/IPQ95XX.txt` | 原文件一次编译 6 个机型，精简为**只保留 `xiaomi_be10000`** |
| `.github/workflows/QCB-ALL.yml` | 矩阵由 `[IPQ53XX, IPQ95XX]` 改为 `[IPQ95XX]`，只跑本设备平台 |
| `Config/GENERAL.txt` | 移除上游默认 9 个插件，改为自选插件（2026-11-12 全量重选）；保留全部内核/组件通用配置 |
| `Scripts/Packages.sh` | 裁剪为只拉取自选第三方仓库（2026-11-12 重选后共 9 行），含新增的 AdGuard Home 与 PassWall |
| `.github/workflows/*.yml` | **关闭全部自动编译**：删除 `Auto-Clean` 每日定时、`Cache-Clean` 每周定时，以及 5 个平台工作流的 `workflow_run` 联动 |
| 其余文件 | 与上游 `main` 一致，未改动 |

### 4.2 改默认参数

编辑 [`QCB-ALL.yml`](.github/workflows/QCB-ALL.yml) 的 `with:` 段，改完提交即生效：

| 参数 | 含义 | 当前值 |
| --- | --- | --- |
| `WRT_IP` | 管理地址 | `192.168.10.1` |
| `WRT_NAME` | 主机名 | `OWRT` |
| `WRT_THEME` | 默认主题 | `vantage` |
| `WRT_SSID` / `WRT_WORD` | WiFi 名称 / 密码 | `OWRT` / `12345678` |
| `WRT_CONFIG` | 配置文件 | `IPQ95XX` |
| `WRT_SOURCE` / `WRT_BRANCH` | 源码仓库 / 分支 | `VIKINGYFY/immortalwrt` / `owrt` |

> `WRT_PW` 只是 Release 说明里的提示文字，改它不会设置登录密码；首次登录无密码，请进系统后自行设置。

### 4.3 插件清单（2026-11-12 全量重新选择）

用户本次选定：`1, 9, 12, 21, 26, 50-53` + 新增 `AdGuard Home`、`PassWall`（原选 `ShadowsocksR Plus+` 已于同日改为 PassWall）。全量逐项清单见工作区文档《插件清单-全量-2026-11-12.md》。

**已拉取并编入固件：**

| 组 | 内容 | 仓库 / 分支 |
| --- | --- | --- |
| 主题（2 套） | `argon`、`vantage`(+`luci-app-vantage`) | `sbwml/luci-theme-argon` @ `openwrt-25.12`；`anothaDev/luci-theme-vantage` @ `main`（整仓 clone） |
| openclash | `luci-app-openclash` | `vernesong/OpenClash` @ `dev`（pkg） |
| openlist | `openlist2` 核心 + LuCI | `sbwml/luci-app-openlist2` @ `main` |
| netwizard | `luci-app-netwizard` | `sirpdboy/luci-app-netwizard` @ `main` |
| lucky | 核心 `lucky` + 界面 `luci-app-lucky` | `gdy666/luci-app-lucky` @ `main`（**整仓 clone**，中文界面由 LuCI 语言配置自动生成） |
| **AdGuard Home**（新增） | `luci-app-adguardhome` | `kenzok78/luci-app-adguardhome` @ `main`（针对 ImmortalWrt 24.10+/25.12 重构版） |
| **PassWall**（新增） | `luci-app-passwall` | `Openwrt-Passwall/openwrt-passwall` @ `main`（`pkg` 模式，见下方说明） |
| 灯光控制 RGB | `rgbcontrol` + `luci-app-rgbcontrol` | `RuijieNetworksCommunity/luci-app-rgbcontrol` @ `master`（**整仓 clone**） |

**无需拉取仓库、只需 `=y`：**

- LED 配置 / 风扇控制的内核模块 `kmod-leds-gpio`、`kmod-leds-pwm`、`kmod-hwmon-pwmfan`、`kmod-gpio-pwm`，由 6.18 源码树编译。
- `fancontrol` / `luci-app-fancontrol` / `luci-i18n-fancontrol-zh-cn` 目标源码树已自带。
- `luci-app-vantage` / `luci-theme-vantage` 由 `Settings.sh` 按 `WRT_THEME` 自动注入（**没有** `luci-app-vantage-config` 这个包，勿手写）。

**关于 PassWall 的三点：**

1. 拉取写法**沿用上游作者**：`UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"`（见上游 `Scripts/Packages.sh` 第 62 行）。仓库根目录只有 `luci-app-passwall/` 一个子包，用 `pkg` 模式提取即可，不必整仓 clone。
2. **代理核心不用额外拉仓库**：`xray-core`、`sing-box`、`chinadns-ng`、`shadowsocks-rust`、`hysteria`、`dns2socks`、`ipt2socks`、`microsocks` 等由目标源码树 `feeds.conf.default` 的 `immortalwrt/packages` 提供（已逐个验证存在），上游作者也未额外拉 `openwrt-passwall-packages`。相比 SSR Plus+ 整仓 30+ 包，这里只引入 1 个 LuCI 包，编译更快。
3. 其 Makefile 原生定义 `Nftables_Transparent_Proxy`（`default y if PACKAGE_firewall4`），`GENERAL.txt` 已显式写 `CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y`，走 nftables 而非 iptables，适配 6.18 内核。

**2026-11-12 二轮修复（WRT-TEST 验证后）：** 首轮 `WRT-TEST` 生成的 `.config` 显示 `lucky` / `rgbcontrol` 的核心包在、但界面包 `luci-app-lucky` / `luci-app-rgbcontrol` **完全没注册**。根因是这两行用了 `pkg` 模式：仓库名恰好等于界面子包名，`cp -rf` 目标目录已存在导致子包被嵌套复制回原处，随后 `rm -rf $REPO_PATH` 把它一起删掉。现改为**整仓 clone**（去掉 `pkg` 参数），构建系统递归扫描到两个子包的 Makefile，与 `vantage` 行同款写法。同时删掉 3 行从未生效的死配置（`luci-app-vantage-config`、两个手写中文包）。详见工作区文档《WRT-TEST验证结果诊断-2026-11-12.md》。

**运行时注意：** AdGuard Home、OpenClash、PassWall 都会接管 DNS 与流量分流，三者同时启用时建议只让一个负责 53 端口（例如 AdGuardHome 设为 dnsmasq 上游、不劫持 53），并协调 OpenClash / PassWall 的 DNS 分流与透明代理规则，避免互相抢占。此为配置问题，不影响编译。

**LED / 风扇 / 灯光的已知限制：** 目标 6.18 设备树 `ipq9570-be10000.dts` 只有 `gpio-leds`，没有 `pwm-rgb` / `pwm-fan` / `pwmchip` 节点。本次按用户选择**只编软件、不打 DTS 补丁**，因此系统 LED 可用，RGB 氛围灯与 PWM 风扇暂不生效，需后续单独打设备树补丁（有变砖风险）。详见工作区文档《固件驱动提取与集成报告.md》。

**未拉取**：ShadowsocksR Plus+（`fw876/helloworld`）、passwall2、aurora、fluent、footstrap、kucat、shadcn、mosdns、momo、nikki、viking 自用包、diskman、easytier、qmodem、qbittorrent、quickfile、ddns-go、netspeedtest、partexp、timecontrol、natmapt、LianXia233 系列等。

### 4.4 临时加 / 减插件

运行 `QCB-ALL` 时在 `PACKAGE` 输入框填配置行，多个用 `\n` 分隔，例如：

```text
CONFIG_PACKAGE_luci-app-diskman=y
CONFIG_PACKAGE_luci-app-openclash=n
```

临时参数优先级高于 `Config/GENERAL.txt`，只影响这一次编译，不改仓库文件。

---

## 5. 自动编译已关闭

上游的自动链是：`Auto-Clean`（每天 UTC 21:21 / 北京时间 5:21 定时）→ 跑完触发所有平台 `workflow_run` → 全平台自动重编。本仓库已把**定时**和**联动**都移除，9 个工作流现在只支持手动触发（`WRT-CORE` 是 `workflow_call` 公共核心）。

| 想要 | 做法 |
| --- | --- |
| 编译一次 | 手动 `QCB-ALL → Run workflow`（见第 1 节） |
| 恢复每日自动编译 | 从上游取回 `Auto-Clean.yml` 的 `schedule` 段，以及各平台工作流的 `workflow_run` 段 |
| 清理旧 Release / 缓存 | 手动运行 `Auto-Clean` / `Cache-Clean` |

> 🚫 **不要手动运行 `Auto-Clean`**：它的 `delete_releases: true` + `releases_keep_latest: 0` + `delete_tags: true` 会删光所有 Release（**含你刚编译好的固件**）和历史运行记录。要清理请手动在网页上逐个删。

---

## 6. 常见问题与排错

| 现象 | 处理 |
| --- | --- |
| 编译末尾发布 Release 报 `403` | 到 `Settings → Actions → General` 把 Workflow permissions 设为 **Read and write** 后重跑 |
| `openlist2` 报 Golang 版本过低 | 打开 `Scripts/Packages.sh` 末尾注释的两行（替换为 `sbwml/packages_lang_golang` 26.x）后重编 |
| `lucky` 核心下载失败 | 该包从 GitHub Releases 拉预编译二进制，确认 runner 能访问；必要时先去掉 `CONFIG_PACKAGE_lucky=y` 编译一次 |
| `openclash` dev 分支不稳定导致失败 | 把 `Scripts/Packages.sh` 里该行分支改为 `master` |
| **PassWall 报缺 chinadns-ng / dns2socks / microsocks / luci-compat 等依赖** | 这些包由 `immortalwrt/packages` feed 提供，确认 `Update Feeds` 步骤未被跳过、`./scripts/feeds install -a` 正常执行；若仍缺失，可额外 clone `Openwrt-Passwall/openwrt-passwall-packages` 到 `./package/` 后再编 |
| **PassWall 透明代理在 6.18 上不生效** | 确认 `GENERAL.txt` 里 `CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y` 存在（走 nftables），不要启用 `Iptables_Transparent_Proxy` |
| **AdGuard Home 与官方 adguardhome 包冲突** | `UPDATE_PACKAGE "adguardhome"` 会自动清掉 feeds 中的同名官方包；若仍报重复定义，检查 `./package/` 下是否残留旧的 `adguardhome` 目录 |
| **AdGuard Home 与 OpenClash 抢 53 端口** | 运行时把 AdGuardHome 设为 dnsmasq 上游（不劫持 53），并协调 OpenClash 的 DNS 分流；这不是编译错误 |
| 主题固件偏大 | 在 `Config/GENERAL.txt` 删掉不需要的 `CONFIG_PACKAGE_luci-theme-*=y`（`vantage` 由 `WRT_THEME` 自动加入，建议保留） |
| 接近 6 小时超时 | 已通过「单平台 + 单机型」精简规避；**PassWall 的 `INCLUDE_*` 选项会连带编译多个代理核心**，仍超时可先临时去掉 `CONFIG_PACKAGE_luci-app-passwall=y` 编一次，或启用 Actions 缓存 |
| 想长期私有定制 | 新建 `Config/PRIVATE.txt` / `Scripts/PRIVATE.sh`，会被自动加载；**不要写入 token 或密码** |
| 编译日志里找不到某插件 | 确认 `Scripts/Packages.sh` 已拉取该仓库，且 `Config/GENERAL.txt` 里对应 `CONFIG_PACKAGE_xxx=y` 存在 |
| **`.config` 里核心包在、界面 `luci-app-*` 不在** | 多为「一仓多包」仓库误用 `pkg` 模式且 `REPO_NAME` 与界面子包同名（`cp` 目标已存在→嵌套复制→被 `rm -rf` 删掉）。改用整仓 clone（把 `pkg` 参数换成 `""`），并用 `WRT-TEST` 生成的 `.config` 核对接口包是否 `=y` |

---

## 7. 仓库文件结构

```text
.github/workflows/
  QCB-ALL.yml      ← 本设备编译入口（唯一需要手动运行的）
  WRT-CORE.yml     ← 公共编译核心，被 QCB-ALL 调用
  WRT-TEST.yml     ← 可选：只生成 .config 做验证
  Auto-Clean.yml   ← 上游清理任务（定时已移除，别手动跑）
  Cache-Clean.yml  ← 缓存清理（定时已移除）
  AIROHA-ALL / MTK-ALL / OWRT-ALL / QCA-ALL.yml  ← 其他平台，保留但用不到
.github/scripts/   ← CI 辅助脚本（Rust/i2c/构建主机准备）
Config/
  IPQ95XX.txt      ← 本设备机型与平台配置
  GENERAL.txt      ← 通用内核/组件 + 插件开关
  *.txt            ← 其他平台的配置（保留，用不到）
Scripts/
  Packages.sh      ← 第三方插件仓库拉取清单
  Settings.sh / Handles.sh  ← 默认参数注入与收尾处理
```

---

## 8. 复现与备份

每次 Release 里的 `Config-IPQ95XX-*.txt` 就是当次编译的完整 `.config`。想固定某次结果，把该文件连同 `Config/GENERAL.txt`、`Scripts/Packages.sh` 一起留存即可。仓库本身可随时 Fork / Clone 作为备份。

---

## 许可证与致谢

沿用上游 [MIT License](LICENSE)。核心工作流、ImmortalWrt 源码与插件均来自 [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI)、[VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt) 及各插件作者，感谢他们的工作。
