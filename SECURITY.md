# 安全说明

本文件说明 `Hitokoto.ps1`、`HitokotoRun.vbs` 与 `Custom.xaml` 的权限边界、网络行为、数据落盘位置和已知残余风险。适用于 PCL-Hitokoto-client v1.1 及后续安全修订。

## 单文件联网版

`single/Custom.xaml` 是另一个版本，安全边界更窄：

- PCL 只从 `https://yiyan.overpass.top/Custom.xaml` 下载一个 XAML 文件；
- 不执行 PowerShell / VBS，不读写注册表，不创建文件、服务或启动项；
- 页面里的“换一句”只触发 PCL 的“刷新主页”，不会执行本地命令；
- 一言正文由服务端在响应时写入；服务端能看到请求 IP 和 User-Agent，与访问普通网页相同；
- 断网时 PCL 显示上次缓存的 XAML，不会自动执行任何补偿脚本。

下面的脚本权限说明只适用于完整版。

## 一句话概括

脚本只做四件事：

1. 向你配置的 API / 句库地址发起 HTTP GET；
2. 把结果写入 `PCL\Hitokoto\*.json`；
3. 把要显示的文本写入 `HKCU\Software\PCL*\CustomEvent*`；
4. 向 PCL 窗口发送一次 F5。

它不申请管理员权限，不安装服务、驱动或启动项，不执行下载内容，不上传本地文件。

## 权限与系统改动

| 项目 | 实际行为 |
| --- | --- |
| 管理员 / UAC | 不请求，不以管理员身份运行 |
| 服务 / 驱动 / 计划任务 | 不创建 |
| 开机启动 / 注册表 Run 项 | 不创建 |
| 进程 | `HitokotoRun.vbs` 隐藏启动 `powershell.exe`；脚本只枚举窗口、激活 PCL、发送 F5 |
| 注册表 | 只写 `HKCU` 下的 `Software\PCL`、`PCL2`、`PCLDebug`、`PCLCE`，值为 `CustomEvent*` |
| 文件 | 只读写 `PCL\Hitokoto\` 下的 JSON / 日志；写入时先在目标旁生成 `.tmp` 再替换 |
| 网络 | 只访问你填写的 API / 句库地址；默认 `https://v1.hitokoto.cn/` |
| 上传 | 没有 POST / PUT / 文件上传代码 |
| 剪贴板 | 只有点击“从剪贴板搜索”时才读取 |
| 自启动 / 常驻 | 没有；每次点击执行一次后退出 |

## 网络安全控制

- 只接受 `http://` 与 `https://`，拒绝空格、引号、尖括号、管道、井号、控制字符和 URL 中的账号密码。
- API 请求超时 6 秒，句库请求超时 30 秒，最多跟随 3 次重定向。
- API 响应上限 256 KiB；句库响应上限 16 MiB、最多 50,000 条；单条正文最多 2,000 字符。
- 不调用 `Invoke-Expression`、`Start-Process`，不下载后执行任何文件。
- `Add-Type` 只加载系统自带的 `Microsoft.VisualBasic` 与 `System.Windows.Forms`，用于激活窗口和发送 F5，不编译或加载外部程序集。
- 优先使用 HTTPS。`http://` 只建议用于本机或可信内网；HTTP 内容可能被中间人篡改。

## 数据与隐私

- 没有遥测、统计或账号系统。
- 日志记录动作、结果、句子 ID / 正文和错误信息；**不记录剪贴板原文**，搜索日志只记录关键词长度。
- 成功日志和状态栏中的地址会去掉查询参数，避免把 `?token=...` 写进日志。
- 但 `Hitokoto\config.json` 会保存完整的 API 地址，API 设置输入框也会显示它。**不要把长期 Token 放在 URL 查询参数里**；客户端不提供单独的 Token 存储。
- 剪贴板搜索只在用户点击按钮时发生；搜索状态显示“剪贴板内容”，不回显原文。
- 写入 `HKCU` 的 PCL 变量不是 secret store，同一用户下的其他程序可以读取。

## 完整性校验

发布页提供 `SHA256SUMS.txt`。下载后先核对，再运行：

```powershell
Get-FileHash .\Hitokoto.ps1 -Algorithm SHA256
Get-FileHash .\HitokotoRun.vbs -Algorithm SHA256
Get-FileHash .\Custom.xaml -Algorithm SHA256
Get-FileHash .\Hitokoto\offline.json -Algorithm SHA256
```

把输出与 `SHA256SUMS.txt` 中的对应行比较。哈希不一致时不要运行，先重新下载。

## 关于代码签名

当前发布**没有**使用 Authenticode 代码签名证书。自签名证书只能让主动安装了该证书的机器识别发布者，不能建立公共信任，所以本项目采用“明文源码 + GitHub 仓库对照 + SHA-256 清单”的方式。若后续获得受信任的代码签名证书，会在 Release 中同时提供签名文件和验证命令。

## 已知残余风险

1. 如果 `Hitokoto.ps1` 被替换成恶意版本，哈希校验只能帮你发现，不能阻止。请从仓库或 Release 重新获取。
2. 自定义 API 可以返回任意文本；客户端只显示和复制，不执行。但仍要警惕伪装成“一言”的诈骗或诱导内容。
3. `HitokotoRun.vbs` 使用 `-ExecutionPolicy Bypass`，因为从浏览器下载的压缩包可能带有“来自 Internet”标记，默认策略会拦截。这不是安全边界，真正的保障是源码可读 + 哈希校验。
4. PCL 与 Windows PowerShell 本身属于信任基础；如果它们被篡改，脚本无法自证安全。
5. 剪贴板可能含有密码等敏感内容。只在你确认要搜索时点击；状态栏不会回显关键词，但搜索结果可能包含与关键词相同的文字。
6. 自动刷新只匹配 PCL 进程名，并在标题兜底唯一时才会激活窗口；如果你同时开了多个 PCL，可能刷新到另一个实例。
7. 本地 JSON 和日志没有加密，同一用户下的恶意程序可以读取。
8. 本项目不提供匿名性；请求会暴露你的 IP 给所配置的 API / 句库服务器。

## 报告问题

发现安全问题请开 GitHub Issue，并附上版本、`SHA256SUMS.txt` 对应哈希和复现步骤。不要在 Issue 里粘贴 Token、Cookie 或完整剪贴板内容。
