# 投稿 / 推荐文案

## 先选版本

现在有两个版本，按投稿目标选择：

| 版本 | 形式 | 适合 |
| --- | --- | --- |
| **单文件联网版** | 一个 `Custom.xaml` | 只收单个 `Custom.xaml` / `homepage.xaml` 的集合；更新链接填服务器地址 |
| 完整版本地脚本版 | `Custom.xaml` + `Hitokoto.ps1` + `HitokotoRun.vbs` + `Hitokoto\` | 接受仓库、Release 压缩包或完整文件夹的目标 |

只收单个 `Custom.xaml` 时，投**单文件联网版**，主页更新链接填：

```text
https://yiyan.overpass.top/Custom.xaml
```

PCL 会自动请求 `https://yiyan.overpass.top/Custom.xaml.ini` 检查版本。服务端在返回 XAML 前把当前一言写进页面，所以 PCL 只下载这一个文件，不需要本地脚本。

单文件版保留展示、复制和打开链接；**本地搜索、自定义 API、完整句库下载只在完整版中提供**，投稿时不要把这些功能算到单文件版头上。

## 短版（Issue / 评论区）

> 推荐一个给 PCL 2.99 / PCL CE 用的一言主页：单文件版只需要一个 `Custom.xaml`，更新链接 <https://yiyan.overpass.top/Custom.xaml>，服务端每次把随机一言写进页面；完整版还支持连续去重、本地搜索、自定义 API 和从自建服务端下载句库。脚本只写 `HKCU` 和 `PCL\Hitokoto`，不申请管理员、不装服务/启动项、不上传文件；仓库提供 `SECURITY.md` 和 `SHA256SUMS.txt`。客户端：<https://github.com/shoot128/PCL-Hitokoto-client> 服务端：<https://github.com/shoot128/PCL-Hitokoto-server>

## 标准版

### 标题

一言 · Hitokoto —— 给 PCL 主页加一点随机性

### 正文

大家好，推荐一个自己做的 PCL 自定义主页：**一言 · Hitokoto**。

它面向 PCL 2.99 / PCL CE，默认从一言 API 获取句子；网络失败时会依次使用本地缓存、自建服务端句库和内置离线库，不会让主页空着。连续点到同一句会自动重试，也可以在本地搜索正文、出处、作者和类型，点击结果即可复制。喜欢折腾的话，还能填自己的 Hitokoto 兼容 API，或从服务端下载完整 JSON 句库。

**主要功能**

- 联网获取一言，连续获取到同一句时自动重试
- 断网自动降级：缓存 → 服务器句库 → 内置离线库
- 本地搜索，支持正文 / 出处 / 作者 / 类型，点击结果复制
- 自定义 API 地址，兼容 `hitokoto` / `text` / `quote` / `content` 等常见字段
- 从自建服务端下载完整句库，搜索时一并检索
- 通过 VBS 隐藏启动 PowerShell，不闪控制台窗口
- 全部使用相对路径，整个 PCL 数据文件夹可以移动

**安全边界**

- 不申请管理员权限，不创建服务、驱动、计划任务或开机启动项
- 只写 `HKCU\Software\PCL*` 和 `PCL\Hitokoto\`，不碰 `Program Files` / `System32`
- 只访问你填写的 API / 句库地址；没有上传、遥测或账号系统
- 不调用 `Invoke-Expression`，不下载后执行任何文件
- 剪贴板只在点击“从剪贴板搜索”时读取，日志不记录原文
- 提供 [`SECURITY.md`](SECURITY.md) 与 [`SHA256SUMS.txt`](SHA256SUMS.txt)，可自行核对哈希

VBS 使用 `-ExecutionPolicy Bypass`，是因为从浏览器下载的压缩包可能带有“来自 Internet”标记，默认策略会拦截；这不是安全边界，脚本本身是明文可读的，发布页也提供 SHA-256。

**单文件版安装**

1. 打开 PCL → 设置 → 个性化 → 主页。
2. 选择“联网下载”/“自定义主页地址”，填写 `https://yiyan.overpass.top/Custom.xaml`。
3. 回到主页按 `F5`。PCL 会自动请求 `Custom.xaml.ini` 并下载单个 `Custom.xaml`。

**完整版安装**

1. 下载 Release 压缩包，或克隆客户端仓库。
2. 把 `Custom.xaml`、`Hitokoto.ps1`、`HitokotoRun.vbs` 和 `Hitokoto\` 整个文件夹复制到 **PCL 数据文件夹根目录**。
3. 打开 PCL → 设置 → 个性化 → 主页 → 选择“读取本地文件”。
4. 回到主页按 `F5`，首次点击“换一句”时选择“继续且今后不再要求确认”。

注意：完整版中 PCL 只从数据文件夹根目录读取 `Custom.xaml`，不要放进 `PCL\client\` 之类的子目录。

**链接**

- 客户端：<https://github.com/shoot128/PCL-Hitokoto-client>
- 服务端：<https://github.com/shoot128/PCL-Hitokoto-server>
- 作者：<https://github.com/shoot128>
- 上游一言：<https://hitokoto.cn/>

**许可与数据来源**

客户端代码使用 MIT License；服务端与官方句库数据按 AGPL-3.0 使用。句库来自 [hitokoto-osc/sentences-bundle](https://github.com/hitokoto-osc/sentences-bundle)。主页方案与脚本由 DeepSeek 辅助编写。

## 给收录方的信息表

| 项目 | 内容 |
| --- | --- |
| 主页名称 | 一言 · Hitokoto |
| 作者 | 晓涵（[@shoot128](https://github.com/shoot128)） |
| 适配 | PCL 2.99 / PCL CE |
| 单文件版形式 | 一个 `Custom.xaml`（服务端动态生成） |
| 单文件版更新链接 | `https://yiyan.overpass.top/Custom.xaml` |
| 完整版形式 | `Custom.xaml` + `Hitokoto.ps1` + `HitokotoRun.vbs` + `Hitokoto\` |
| 是否纯 XAML | 单文件版是；完整版否，依赖本地 PowerShell |
| 是否需要管理员 | 否 |
| 是否写注册表 | 单文件版否；完整版是，仅 `HKCU` 下的 PCL 变量 |
| 是否创建服务 / 启动项 | 否 |
| 是否包含二进制 | 否 |
| 默认网络请求 | 单文件版：更新链接；完整版：`https://v1.hitokoto.cn/`（可改） |
| 离线可用 | 单文件版显示上次缓存；完整版内置 12 条兜底 + 本地缓存 |
| 客户端许可证 | MIT |
| 服务端许可证 | AGPL-3.0 |
| 是否支持搜索 / 自定义 API | 单文件版否；完整版是 |

## 投稿时不要这样写

- 不要说“PCL 官方收录”或“官方主页”；这是非官方项目。
- 不要说“完全不写注册表”；完整版会写 `HKCU` 下的 PCL 变量，这是 PCL 自定义主页读取数据的机制。
- 不要把完整版说成“单文件 XAML”；完整版必须带脚本和 `Hitokoto\` 文件夹。单文件版才是单文件。
- 不要把单文件版说成支持本地搜索、自定义 API 或句库下载；这些只在完整版中提供。
- 不要把 `-ExecutionPolicy Bypass` 藏起来；主动解释原因，并给出哈希校验方式，比回避更加可信。
