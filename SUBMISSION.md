# 主页投稿推荐词 · 单文件版

> 适用：只接受单个 `Custom.xaml` / `homepage.xaml` 的主页集合。
> 本版本不需要 PowerShell、VBS、注册表或额外文件夹，PCL 只下载一个 XAML。

## 一句话推荐

推荐一个给 PCL 2.99 / PCL CE 的单文件主页：**一言 · Hitokoto**。PCL 只需要下载一个 `Custom.xaml`，更新链接填 `https://yiyan.overpass.top/Custom.xaml`；页面由服务端把一句一言写进 XAML，打开就是完整页面，不执行本地脚本、不写注册表、不申请管理员。断网时 PCL 会保留上次缓存。

## 标准推荐

### 标题

一言 · Hitokoto：给 PCL 主页留一句随机的话

### 正文

这是一个面向 PCL 2.99 / PCL CE 的自定义主页。它最大的特点是**单文件**：PCL 只需要下载一个 `Custom.xaml`，不需要同目录脚本，也不需要额外文件夹。

打开后页面会显示一条一言，以及出处、作者和类型；点“换一句”会让 PCL 重新请求主页，服务端从官方句库随机取一条并写进新的 XAML。也可以一键复制当前句子，或打开一言 API、项目仓库和作者空间。

句子来自官方开源句库 `hitokoto-osc/sentences-bundle`，当前共 10526 条；服务端在返回 XAML 前完成取句和 XML 转义，PCL 只负责渲染。

### 主要特点

- **只下载一个文件**：`Custom.xaml`，不是压缩包，不需要 PowerShell / VBS
- **联网换句**：服务端从官方句库随机取一条，写进 XAML 后返回
- **点击“换一句”立即刷新**：触发 PCL 的“刷新主页”，重新下载并换一句
- **可复制当前句子**：一键复制正文
- **断网有兜底**：PCL 显示上一次成功下载的页面，不会白屏
- **无本地脚本**：不写注册表、不创建服务/启动项、不申请管理员
- **关于卡片固定展开**，使用说明默认折叠，打开时页面比较干净

### 安装

1. 打开 PCL → 设置 → 个性化 → 主页。
2. 选择“联网下载”/“自定义主页地址”。
3. 填写更新链接：

```text
https://yiyan.overpass.top/Custom.xaml
```

4. 回到主页按 `F5`，PCL 会自动请求 `Custom.xaml.ini` 并下载 `Custom.xaml`。
5. 点“换一句”即可重新请求并换一句。

不需要复制 `Hitokoto.ps1`、`HitokotoRun.vbs` 或 `Hitokoto\` 文件夹。

### 安全边界

- XAML 中没有 `EventType="执行命令"`，不执行本地程序
- 不读写注册表，不创建服务、计划任务或开机启动项
- 不申请管理员权限
- 只向更新链接指向的服务器发起 HTTPS 请求
- 没有文件上传、遥测或账号系统
- 服务端不建立用户账号；Uvicorn / Nginx 访问日志会按运维需要保留请求 IP 和 User-Agent

### 链接

- 动态更新链接（推荐，域名/证书就绪后使用）：<https://yiyan.overpass.top/Custom.xaml>
- 静态预览（当前可打开，不会自动换句）：<https://cdn.jsdelivr.net/gh/shoot128/PCL-Hitokoto-client@main/single/Custom.xaml>
- 客户端仓库：<https://github.com/shoot128/PCL-Hitokoto-client>
- 服务端仓库：<https://github.com/shoot128/PCL-Hitokoto-server>
- 作者：<https://github.com/shoot128>
- 上游一言：<https://hitokoto.cn/>

### 许可与数据来源

客户端页面使用 MIT License；服务端与官方句库数据按 AGPL-3.0 使用。句库来自 [hitokoto-osc/sentences-bundle](https://github.com/hitokoto-osc/sentences-bundle)。主页方案与页面由 DeepSeek 辅助制作。

## 给收录方的信息表

| 项目 | 内容 |
| --- | --- |
| 主页名称 | 一言 · Hitokoto |
| 作者 | 晓涵（[@shoot128](https://github.com/shoot128)） |
| 适配 | PCL 2.99 / PCL CE |
| 形式 | 单个 `Custom.xaml`（服务端生成） |
| 更新链接 | `https://yiyan.overpass.top/Custom.xaml` |
| 静态预览 | `https://cdn.jsdelivr.net/gh/shoot128/PCL-Hitokoto-client@main/single/Custom.xaml` |
| 是否纯 XAML | 是，不需要本地脚本 |
| 是否需要管理员 | 否 |
| 是否写注册表 | 否 |
| 是否创建服务 / 启动项 | 否 |
| 是否包含二进制 | 否 |
| 默认网络请求 | 更新链接（HTTPS） |
| 离线可用 | PCL 显示上次缓存的主页 |
| 是否支持搜索 / 自定义 API / 句库下载 | 否，单文件版只保留展示、复制和打开链接 |
| 页面许可证 | MIT |
| 句库许可证 | AGPL-3.0 |

## 给维护者的备注

- 如果集合只收单个 `Custom.xaml`：更新链接返回的就是一个完整 XAML，不是压缩包，也不会跳转到脚本。
- PCL 会自动请求 `<更新链接>.ini` 做版本检查；这是 PCL 自带的更新机制，不是要求投稿两个文件。
- 如果要求“现在点开就能看到”：请用上面的静态预览链接。它是已渲染好的单文件快照，不会自动换句；动态链接需要域名和证书就绪。
- 静态版和动态版都是单文件，区别只在句子是否随请求变化。

## 投稿时不要这样写

- 不要写成“完全离线 / 不联网”：它会请求更新链接。
- 不要写“支持本地搜索、自定义 API、完整句库下载”：这些功能不在单文件版里。
- 不要写“PCL 官方收录 / 官方主页”：这是非官方项目。
- 不要把 `.ini` 说成第二个投稿文件：它只是 PCL 的版本检查地址。
- 不要隐瞒静态预览不会自动换句；动态链接才是每次请求重新取句。
