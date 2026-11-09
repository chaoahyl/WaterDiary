# WaterDiary

原生 SwiftUI 饮水日记，最低支持 iOS 15。

支持首页快捷记录、自定义水量、记录编辑与删除、每日目标、饮水历史、最近 7 天统计和跨天刷新。饮水数据保存在使用者设备的本地 `UserDefaults` 中。

## 开发环境与个人配置

工程使用 [KXBuild](https://kxbuild.net/) 开发。阅读源码和运行 Foundation 数据逻辑测试不需要填写作者的账号；构建、签名和真机运行时，使用者需要自行准备工具许可及适用的签名材料。

### 1. 安装工具

按 KXBuild 官网说明安装工具，并完成自己的许可配置。根目录的 `buildServer.json` 由编辑器插件生成，包含本机路径，已排除在 Git 之外；克隆项目后由自己的编辑器环境重新生成，不要复制作者的文件。

### 2. 配置应用标识与开发者团队

将示例复制为本机配置文件：

```powershell
Copy-Item Config/signing.example.json Config/signing.local.json
```

修改 `Config/signing.local.json` 中的 `com.example.waterdiary` 和 `YOUR_TEAM_ID`，分别填写自己可用的 Bundle ID 和 Apple Developer Team ID。Debug、Release 两组配置都需要替换，并与自己的描述文件匹配。

可以先只读预览，再通过 KXBuild 应用配置：

```powershell
kxbuild project settings dump WaterDiary.xcodeproj --ops Config/signing.local.json --json
kxbuild project settings apply WaterDiary.xcodeproj --ops Config/signing.local.json --json
```

`dump --ops` 不写入工程，`apply` 会更新本地工程文件。不要手动编辑 `project.pbxproj`。原项目标识 `so.phonegame.waterdiary` 不是登录凭据，但不能当成使用者自己的签名授权。

### 3. 准备自己的签名材料

在本机创建 `keychain/`，放入自己导出的 `.p12` 证书和匹配 Bundle ID 的 `.mobileprovision` 描述文件。将密码示例复制到该目录：

```powershell
New-Item -ItemType Directory -Path keychain -Force
Copy-Item Config/password.properties.example keychain/password.properties
```

编辑 `keychain/password.properties`，填写自己的证书文件名及密码。不要在仓库、Issue、截图或日志中公开这些内容。`keychain/`、本机签名配置、独立证书、私钥和常见环境配置均已加入忽略规则。

修改 Bundle ID 和 Team ID 后，`project.pbxproj` 可能出现本地差异；提交前检查差异，不要将自己的签名信息混入源码贡献。`.gitignore` 不会隐藏已受版本控制的工程文件中的修改。

### 4. 构建与真机运行

个人配置完成后，可自行执行：

```powershell
kxbuild build WaterDiary.xcodeproj --json --no-ipa
kxbuild run WaterDiary.xcodeproj --json
```

真机运行还需要使用者自己的已信任设备与适用的开发签名。以上为运行说明，不表示文档整理时执行过构建。

## 公开仓库内容

源码、工程和测试可以提交。教程文稿和配图（`Docs/`）发布在博客上，不放进仓库；`keychain/`、`build/` 和生成的编辑器配置也只留在本机。

首次提交及后续提交前都应检查暂存内容。忽略规则只防止未跟踪文件被误加入，不能清除已经提交到历史中的内容。

## 代码组织

`WaterDiaryApp.swift` 仅负责启动；`ContentView.swift` 负责首页 / 我的底部导航、共享数据对象和前后台日期刷新。

| 目录 | 职责 |
| --- | --- |
| `WaterDiary/Models` | 饮水记录、归档结构、每日统计数据 |
| `WaterDiary/Stores` | 数据读写、输入校验、目标、跨天与历史统计 |
| `WaterDiary/Theme` | 共用颜色与背景样式 |
| `WaterDiary/Views/Home` | 首页布局、记录操作和弹窗状态 |
| `WaterDiary/Views/Profile` | 我的页面 |
| `WaterDiary/Views/History` | 历史列表与单日明细 |
| `WaterDiary/Views/Editors` | 饮水记录和偏好编辑弹窗 |
| `WaterDiary/Views/Components` | 进度卡、周统计图和记录行 |

`Models`、`Stores`、`Theme`、`Views` 通过 `kxbuild project add-folder` 注册为 WaterDiary target 的同步目录，新增 Swift 文件会自动纳入项目。测试代码留在 target 之外。

本地数据继续使用 `waterDiary.archive.v1`，文件拆分不改变数据格式或已有记录。数据模型与存储保持独立于页面，展示组件通过数据和操作回调接入首页。

## 验证

不构建 App；Swift 类型检查和 39 项数据逻辑测试的运行方式见 [Tests/README.md](Tests/README.md)。
