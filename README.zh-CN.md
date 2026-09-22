# Hinge

[English](README.md) · **简体中文**

> 本仓库是 [Noveum/hinge](https://github.com/Noveum/hinge) 的 Fork。项目归属、下载和问题反馈请以上游仓库为准。

让 MacBook 桌面随着屏幕开合轻轻弯曲。合上屏幕时，桌面会柔和地折叠并逐渐模糊；重新打开后，一切恢复原状。

## 实现原理

Hinge 按传感器更新频率读取屏幕开合角度；在 Mac 能提供相应精度时，角度精确到百分之一度，并转换成连续动画。慢慢转动，画面就缓慢弯曲；快速转动，动画也会随之加快。读取之间会进行少量平滑处理。

ScreenCaptureKit 提供实时桌面画面，Metal 以 60fps 添加透视和渐进模糊。所有内容都只保存在 Mac 内存中，不会录制或上传。

## 安装

需要配有受支持屏幕角度传感器的 Apple 芯片 MacBook，以及 macOS 14 或更高版本。并非所有 MacBook 都带有这种传感器；如果设备不支持，Hinge 会给出提示。

可以从[上游项目网站下载 Hinge](https://hinge.noveum.ai/download)，打开 DMG 后将 Hinge 拖入 Applications。该原型尚未经过 Apple 公证，macOS 可能要求你在“隐私与安全性”中手动批准。

也可以自行构建：

```sh
git clone https://github.com/Noveum/hinge.git
cd hinge
make build
open build/Hinge.app
```

授予屏幕录制权限；如果系统提示，请重新打开 Hinge，然后启用效果。应用下次启动时会恢复启用状态。默认起始角度为 100°，也可以调整到舒适角度后点击 **Set open position**，Hinge 会记住这个位置。

Hinge 支持英文、简体中文、繁体中文、日文、韩文、德文、法文、西班牙文、意大利文、巴西葡萄牙文、俄文、荷兰文、土耳其文、波兰文、阿拉伯文、越南文和印地文。可以在 **Settings > Controls > Language** 中切换语言。

## 建议与贡献

欢迎通过[上游 Issue](https://github.com/Noveum/hinge/issues)提交功能建议，或直接发起 Pull Request。开发检查与环境配置见 [CHECKS.md](CHECKS.md)。

## 翻译

翻译文件位于 `Resources/Localizations/<language>.lproj/Localizable.strings`，每种语言一个文件。首次启动时，Hinge 会选择最匹配的系统语言；此后会保留用户选择，直到在设置中修改。

维护翻译时，请保持所有文件中的英文键完全一致，并保留 `%@`、`%lld` 等格式占位符。Make 和 Xcode 都会直接将这些文件打包进应用。
