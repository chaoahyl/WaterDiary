# 数据逻辑测试

不构建、安装或启动 iOS App。测试脚本直接读取 `Models/WaterModels.swift` 和 `Stores/WaterStore.swift`，临时去掉 Combine 导入和观察标记，用 Swift Foundation 执行 39 项检查。临时文件和独立的 UserDefaults 测试数据会在结束后清理。

安装了 Swift 的环境：

```powershell
python Tests/run_model_tests.py
```

使用已有的 Ubuntu WSL Swift 工具链：

```powershell
python Tests/run_model_tests.py --wsl Ubuntu
```

覆盖新增、输入范围、未来时间校验、修改、移动日期、删除、每日统计、目标快照、重新加载、连续达标、跨天、夏令时和损坏数据保护。Combine 通知与页面交互需要后续真机验证。

## 工具链头文件路径的可选处理

部分 KXBuild Linux 工具链将头文件目录命名为 `*_org`。仅在确认自己的工具链存在这些目录且运行测试遇到对应缺失头文件错误时，才需要补充引用。先进入自己的 WSL 环境，切换到克隆后的项目根目录，并将 `SWIFT_RUNTIME_HEADERS` 设为实际工具链的 `usr/lib/swift` 目录。下面的命令在 Bash 中执行，不依赖固定用户名或工具链版本：

```bash
# 先设置 SWIFT_RUNTIME_HEADERS 为自己的工具链头文件目录。
: "${SWIFT_RUNTIME_HEADERS:?请先设置当前 Swift 工具链的 usr/lib/swift 路径}"
headers_dir="$(mktemp -d /tmp/waterdiary-swift-headers.XXXXXX)"
for original in "$SWIFT_RUNTIME_HEADERS"/*_org; do
    [ -d "$original" ] || continue
    name="$(basename "$original" _org)"
    ln -s "$original" "$headers_dir/$name"
done
python3 Tests/run_model_tests.py --swift-arg=-Xcc --swift-arg="-I$headers_dir"
```

此方法只创建临时目录别名，不修改工具链原文件。临时目录位于 `/tmp`，可按本机策略清理；没有对应错误时无需执行。

## Swift 类型检查

全部生产 Swift 文件可执行 iOS 15 目标的 `swiftc -typecheck` 检查，不生成 App。进入已安装 KXBuild 工具链的 Bash 环境，切换到项目根目录，设置自己的 `KXBUILD_ROOT` 后执行：

```bash
# 先设置 KXBUILD_ROOT 为自己的 KXBuild 安装目录，并确保 swiftc 在 PATH 中。
: "${KXBUILD_ROOT:?请先设置 KXBuild 安装目录}"
find WaterDiary -name '*.swift' -print0 | xargs -0 swiftc \
    -typecheck -parse-as-library -swift-version 5 \
    -target arm64-apple-ios15.0 \
    -sdk "$KXBUILD_ROOT/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk" \
    -module-cache-path /tmp/waterdiary-ios-typecheck \
    -load-plugin-executable "$KXBUILD_ROOT/bin/SwiftUIMacros-tool#SwiftUIMacros"
```

SDK 与宏插件的位置按实际 KXBuild 安装版本调整。这些命令是操作示例，不能代替各使用者在自己环境中的检查结果。
