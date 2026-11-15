# PCL 一言主页 · 单文件联网版

这是给 PCL 2.99 / PCL CE 的**单文件**主页：PCL 只需要下载一个 `Custom.xaml`，不需要 `Hitokoto.ps1`、`HitokotoRun.vbs` 或 `Hitokoto\` 文件夹。使用服务器动态链接时，还可以在页面里直接搜索服务端句库。

## 更新链接

```text
https://yiyan.overpass.top/Custom.xaml
```

PCL 会自动请求同目录的：

```text
https://yiyan.overpass.top/Custom.xaml.ini
```

`Custom.xaml.ini` 每次返回新的时间戳，因此 PCL 每次启动都会重新下载 `Custom.xaml`，服务端会在返回前把当前一言写进页面。

## 工作方式

1. PCL 请求 `Custom.xaml.ini` 检查版本；
2. 版本变化后请求 `Custom.xaml`；
3. 服务端从在线句库随机取一条，把正文、出处、作者、句库数量、生成时间写入 XAML；
4. PCL 直接渲染这个 XAML，不执行任何本地脚本。

页面里的“换一句”会先把联网主页地址改回不带 `q` 的地址，再触发 PCL 的“刷新主页”，重新请求 `Custom.xaml`；有缓存时 PCL 会先显示缓存并在后台刷新，不需要重启 PCL。

这与 `wlasfjdskfj/pcl-homepage` 一类“服务端生成单文件 XAML”的联网主页思路相同。

## 搜索（仅动态链接）

动态链接下，页面里有一张“搜索一言库”卡片：

1. 输入关键词，点“搜索”；
2. 页面通过 PCL 自带的“修改设置”事件，把本机的 `UiCustomNet` 改成 `Custom.xaml?q=关键词`；
3. 再触发“刷新主页”，PCL 请求这个带 `q` 的地址；
4. 服务端按本次请求检索句库，把结果和状态直接渲染进返回的 XAML。

PCL CE 2.15.1 不会替换更新链接里的 `{identify}` / `{variable:...}` 标记，所以这里直接改设置，而不是依赖 URL 变量。`q` 只属于本次搜索生成的链接；搜索后本机地址会保留带 `q` 的链接，直到点“换一句”或“清空搜索”恢复，服务端不保存“上一位用户搜了什么”，每个 PCL 各自保存自己的地址，两个用户同时搜索时不会互相覆盖。响应带 `Cache-Control: private, no-store`，共享缓存不能把一个人的结果发给另一个人。

关键词里不要包含竖线 `|`（PCL 设置事件用它分隔参数）或井号 `#`（会被当成 URL 片段）；`&` 可以正常使用，服务端从原始查询串读取 `q`。

**静态快照不能搜索**：它没有服务端，只显示固定的“搜索需要动态版”提示。静态 `.ini` 也不会变化，所以静态链接既不会自动换句，也不能搜索。

## 和完整版的区别

单文件版保留：

- 显示一言、出处、作者、类型
- 复制当前一言
- 打开一言 API、项目仓库、服务端仓库、B 站空间
- 服务端搜索（仅动态链接；静态快照不能搜索）
- 断网时显示 PCL 上一次缓存的主页

单文件版不支持：

- 本地搜索（不依赖服务端的离线搜索）
- 自定义 API 地址
- 从服务端下载完整句库
- 连续去重

需要这些功能，请使用带 `Hitokoto.ps1` / `HitokotoRun.vbs` 的完整版。

## 仓库里的 `Custom.xaml`

本目录的 `Custom.xaml` 是**已经渲染好的静态快照**，用于预览或在服务端域名不可用时作为 GitHub 静态兜底。

静态兜底链接（已上传，当前可直接打开）：

```text
https://cdn.jsdelivr.net/gh/shoot128/PCL-Hitokoto-client@main/single/Custom.xaml
```

同目录的 `single/Custom.xaml.ini` 也已上传，所以 PCL 能正常走“版本检查 → 下载 Custom.xaml”的流程。但静态 `.ini` 不会变化，因此它不会自动换句；如果要每次启动/点击“换一句”都换，请使用上面的服务器动态链接。

GitHub Raw 原始地址（部分网络可能无法直连）：

```text
https://raw.githubusercontent.com/shoot128/PCL-Hitokoto-client/main/single/Custom.xaml
```

## 安全边界

- 不执行本地脚本
- 搜索时只通过 PCL 自带的“修改设置”事件改写本机的联网主页地址 `UiCustomNet`，不写注册表
- 不创建服务、计划任务或启动项
- 不申请管理员权限
- 只向更新链接指向的服务器发起 HTTPS 请求
- 服务端不建立账号，也不收集额外身份信息；Uvicorn / Nginx 访问日志会按运维需要保留请求 IP 和 User-Agent

## 许可

客户端页面使用 MIT License；句库来自 [hitokoto-osc/sentences-bundle](https://github.com/hitokoto-osc/sentences-bundle)，按 AGPL-3.0 使用。
