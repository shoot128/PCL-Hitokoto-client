# PCL Hitokoto 自定义主页 · 客户端

用于 PCL 2.99 / PCL CE 的一言（Hitokoto）自定义主页。支持联网获取、连续去重、离线降级、搜索句库、自定义 API，以及从自建服务端下载完整句库。

配套服务端：[PCL-Hitokoto-server](https://github.com/shoot128/PCL-Hitokoto-server)

## 功能

- 联网获取一言，连续获取到同一句时自动重试
- 网络失败时从本地缓存、服务器句库、内置离线库依次降级
- 本地搜索：正文、出处、作者、类型
- 自定义 API 地址，支持自建 Hitokoto 兼容实例
- 从服务端下载完整 JSON 句库，保存为 `Hitokoto\library.json`
- 隐藏启动 PowerShell，不闪控制台窗口
- 所有命令使用相对路径，整个 PCL 数据文件夹可以移动

## 文件

```text
Custom.xaml                  PCL 自定义主页
Hitokoto.ps1                 联网 / 缓存 / 搜索 / 句库下载
HitokotoRun.vbs              隐藏启动 PowerShell
Hitokoto/
  offline.json               内置离线库（12 条公版古诗文）
  config.example.json        API / 句库地址示例
  README.txt                 详细使用说明与排错
```

运行时自动生成、未纳入仓库的文件：

```text
Hitokoto/config.json         当前 API / 句库配置
Hitokoto/quotes.json         联网缓存
Hitokoto/state.json          上次获取记录
Hitokoto/library.json        从服务端下载的完整句库
Hitokoto/hitokoto.log        运行日志
```

## 安装

1. 打开 PCL 数据文件夹（PCL 启动器目录下的 `PCL` 文件夹）。
2. 把仓库根目录的以下内容复制到 **PCL 数据文件夹根目录**：
   - `Custom.xaml`
   - `Hitokoto.ps1`
   - `HitokotoRun.vbs`
   - `Hitokoto\` 整个文件夹
3. 不要放进 `PCL\client\` 之类的子目录；PCL 只从数据文件夹根目录读取 `Custom.xaml`。
4. 打开 PCL → 设置 → 个性化 → 主页 → 选择“读取本地文件”。
5. 回到主页，按 `F5` 或点击“刷新主页”。

首次点击“换一句”时，PCL 会询问是否允许执行命令；选择“继续且今后不再要求确认”。

## 配置服务端

在主页的“API 设置”卡片中填写：

```text
自定义 API：https://yiyan.overpass.top/api/hitokoto
```

在“句库下载”卡片中填写：

```text
句库地址：https://yiyan.overpass.top/hitokoto.json
```

也可以使用自己的服务端。客户端会自动在 API 地址后追加 `encode=json` 和 `charset=utf-8`，服务端忽略额外查询参数即可。

如需手动配置，复制：

```text
Hitokoto\config.example.json  →  Hitokoto\config.json
```

然后修改 `apiUrl` 和 `libraryUrl`。

## 卡片顺序

```text
一言 · Hitokoto
搜索一言库
关于
API 设置（支持自建实例）      默认折叠
句库下载（可选）              默认折叠
内置离线一言库                默认折叠
使用说明与已知限制            默认折叠
```

“关于”固定展开，不可折叠；一言和搜索为主内容，也不折叠。

## 运行条件

- Windows 10 / 11
- PCL 2.99 或 PCL CE
- Windows PowerShell 5.1+
- Windows Script Host（`wscript.exe`）未被禁用

脚本只访问你配置的 API / 句库地址，不上传本地文件。API Token 不保存在客户端。

## 许可证

客户端代码使用 **MIT License**，见 [LICENSE](LICENSE)。

服务端仓库中的官方句库属于 [hitokoto-osc/sentences-bundle](https://github.com/hitokoto-osc/sentences-bundle)，按 AGPL-3.0 使用；客户端本身不包含该句库。

## 相关

- 作者 GitHub：<https://github.com/shoot128>
- 作者 B 站：<https://space.bilibili.com/3493257902295506>
- 上游一言：<https://hitokoto.cn/>
