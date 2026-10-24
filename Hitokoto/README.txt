PCL 一言主页 · 使用说明
============================================================

一、文件与放置位置（全部使用相对路径）
------------------------------------------------------------
PCL 会自动在启动器根目录下生成 PCL 数据文件夹。请保持：

  PCL\Custom.xaml                 主页文件
  PCL\HitokotoRun.vbs             隐藏启动 PowerShell 的包装脚本
  PCL\Hitokoto.ps1                联网 / 缓存 / 搜索 / 句库下载助手
  PCL\Hitokoto\offline.json       内置离线一言库（12 条）
  PCL\Hitokoto\quotes.json        联网缓存（初始为空，脚本自动追加）
  PCL\Hitokoto\library.json       从自己服务器下载的完整句库（下载后生成）
  PCL\Hitokoto\config.json        API 地址与句库地址（脚本自动生成）
  PCL\Hitokoto\hitokoto.log       运行日志（脚本自动生成）
  PCL\Hitokoto\state.json         上次获取记录（脚本自动生成）

Custom.xaml 里的命令使用相对路径：

  wscript.exe //nologo "HitokotoRun.vbs" -Action ...

HitokotoRun.vbs 会在同目录以隐藏窗口启动：

  powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "Hitokoto.ps1" ...

这样点击按钮时不会闪出 PowerShell 控制台窗口。
PCL 2.99 执行“打开文件 / 执行命令”时，会把工作目录设置为
PCL 数据文件夹，所以不需要写 D:\... 之类的盘符。只要
Custom.xaml、HitokotoRun.vbs、Hitokoto.ps1 和 Hitokoto 文件夹
放在一起，整个启动器目录搬到别处也能继续用。

二、启用主页
------------------------------------------------------------
1. 打开 PCL；
2. 设置 → 个性化 → 主页；
3. 选择“读取本地文件”；
4. 回到主页，按 F5 或点“刷新主页”。

当前 Setup.ini 中 UiCustomType 已经是 1（本地文件），
正常情况下不需要再改设置。

三、第一次使用
------------------------------------------------------------
1. 点击“换一句”；
2. PCL 会弹出命令执行确认，选择“继续且今后不再要求确认”；
   如果之前已允许过旧版的 powershell 命令，换成 wscript
   启动后可能还会再询问一次，继续允许即可；
3. 脚本会联网获取一句，写入注册表变量，然后向 PCL 发送 F5；
4. 页面重新加载后显示新句子、出处、类型和缓存数量。

如果页面没有自动刷新，点击“刷新显示”即可。

四、功能说明
------------------------------------------------------------
1. 联网获取
   - 默认 API：https://v1.hitokoto.cn/
   - 成功时显示正文、出处、作者、类型、UUID、获取时间；
   - 连续获取到同一句时会自动重试，最多 3 次；
   - 支持自建一言实例（见第 6 节）。

2. 刷新 / 降级
   - “换一句”：联网获取下一条；
   - 网络失败或 API 超时：自动从本地缓存、服务器句库或
     内置离线库随机取一句，并在状态栏标记“离线”；
   - “从本地库随机一句”：完全不联网，从本地缓存、服务器
     句库和内置离线库中随机取一句。

3. 离线存储
   - 内置离线库：Hitokoto\offline.json（12 条公版古诗文）；
   - 联网获取的句子自动追加到 Hitokoto\quotes.json；
   - 从服务器下载的句库保存为 Hitokoto\library.json；
   - 联网缓存上限 500 条；服务器句库上限 5 万条，
     建议不超过 2 万条以保证搜索速度；
   - 断网时不影响内置离线库和已下载句库的使用。

4. 搜索
   - 在“正文 / 出处 / 作者 / 类型”中模糊匹配；
   - 英文忽略大小写；
   - 检索范围：联网缓存 + 服务器句库 + 内置离线库；
   - 最多显示 5 条结果，点击结果可复制该句；
   - 搜索无结果时会显示明确提示；
   - “复制关键词 → 从剪贴板搜索”用于关键词包含
     英文双引号的情况。

5. 关于
   - GitHub 仓库地址和 B 站地址都做成“打开网页”按钮，
     和“打开一言 API”等按钮排在同一行，点击后直接调用
     系统浏览器；
   - GitHub 当前地址：
     https://github.com/shoot128
   - B 站当前地址：
     https://space.bilibili.com/3493257902295506
   - 如需更换，修改对应按钮的 EventData 和按钮文本即可；
   - 已注明“由 DeepSeek 辅助制作”。

6. 自定义 API（支持自建实例）
   - 打开主页的“API 设置（支持自建实例）”卡片；
   - 在输入框中填入你的实例根地址，例如：
       https://v1.hitokoto.cn/
       https://你的服务器/api/hitokoto
   - 点“保存并测试”；
   - 脚本会：
       a. 校验地址必须以 http:// 或 https:// 开头；
       b. 自动补上 encode=json 和 charset=utf-8
          （如果地址里已经有这两个参数就不重复添加）；
       c. 保存到 Hitokoto\config.json；
       d. 立即请求一句测试，成功则更新主页；
   - 自定义 API 返回以下字段即可被识别：
       hitokoto / text / quote / content  → 正文
       from / source                      → 出处
       from_who / author                  → 作者
       type / category                    → 类型
       uuid / id                          → 标识
       也支持 { "data": { ... } } 或 { "data": [ ... ] } 包装。
   - 自建 HTTPS 实例需要有效证书；自签名证书请改用
     受信任证书或 http 内网地址。

7. 从自己的服务器下载完整句库
   - 打开“句库下载（可选）”卡片；
   - 填入 JSON 句库地址，例如：
       https://你的服务器/hitokoto/library.json
   - 点“下载完整句库”；
   - 支持以下 JSON 结构：
       [ {...}, {...} ]                     纯数组
       { "quotes": [ {...} ] }              quotes 包装
       { "data": [ {...} ] }                data 数组
       { "data": { "quotes": [ {...} ] } }  data 对象再包 quotes
       { "results": [ {...} ] }             results 包装
       { "items": [ {...} ] }               items 包装
   - 每条句子支持：
       text / hitokoto / content / quote    → 正文
       source / from                        → 出处
       author / from_who                    → 作者
       type / category                      → 类型
       id / uuid                            → 标识
   - 下载成功后保存到 Hitokoto\library.json，
     搜索和“从本地库随机一句”都会使用；
   - 再次下载会覆盖旧句库，不会覆盖联网缓存。

五、实现原理（为什么需要 VBS + PowerShell）
------------------------------------------------------------
PCL 2.99 的 Custom.xaml 是纯声明式 WPF XAML：
  - 不能直接发 HTTP 请求；
  - 不能直接读取本地文件；
  - 不能用 C# / VB 代码；
  - 只提供 MyCard、MyButton、MyListItem、MyImage、
    TextBox 等控件和“自定义事件”。

因此采用下面的链路：

  主页按钮
    → PCL 自定义事件“执行命令”
    → wscript.exe 隐藏启动 powershell -File Hitokoto.ps1 -Action ...
    → 脚本请求 API / 读取离线库 / 下载句库
    → 脚本把结果写入注册表变量
      HKCU\Software\PCL\CustomEventHitokotoText 等
    → 脚本向 PCL 窗口发送 F5
    → PCL 重新加载 Custom.xaml
    → {variable:HitokotoText:默认值} 读取新值并显示

脚本会同时写 PCL、PCL2、PCLDebug、PCLCE 四个注册表
子键，以及 32/64 位两个注册表视图，以兼容不同的 PCL
分支和位数。

六、排错
------------------------------------------------------------
1. 点击按钮没有任何反应
   - 确认 PCL 数据文件夹中存在 HitokotoRun.vbs 和 Hitokoto.ps1；
   - 确认 Custom.xaml、HitokotoRun.vbs、Hitokoto.ps1 在同一
     个 PCL 数据文件夹里（启动路径用的是相对路径）；
   - 确认系统没有禁用 Windows Script Host（wscript.exe）；
   - 检查安全软件是否拦截 PowerShell 或 VBS；
   - 确认 Hitokoto.ps1 保存为 UTF-8 with BOM；如果脚本里的
     中文变成乱码或报“字符串缺少终止符”，请用记事本另存为
     “UTF-8 带 BOM”后重试；
   - 手动运行下面的命令测试隐藏启动（在 PCL 数据文件夹中执行）：
     wscript.exe //nologo .\HitokotoRun.vbs -Action next
     然后查看 Hitokoto\hitokoto.log 是否新增记录；
   - 如果要直接看 PowerShell 报错，运行：
     powershell -NoProfile -ExecutionPolicy Bypass -File .\Hitokoto.ps1 -Action next

2. 有提示但没有新句子
   - 点击“刷新显示”；
   - 查看 Hitokoto\hitokoto.log；
   - 检查注册表 HKCU\Software\PCL 下是否有
     CustomEventHitokotoText / CustomEventHitokotoStatus。

3. 自定义 API 测试失败
   - 检查地址是否以 http:// 或 https:// 开头；
   - 浏览器直接访问“地址?encode=json”能否返回 JSON；
   - 自建 HTTPS 是否有有效证书；
   - 查看“API 设置”卡片里的状态文本和 hitokoto.log。

4. 句库下载失败
   - 确认地址返回的是 JSON，不是 HTML 页面；
   - 确认 JSON 顶层是数组，或包含 quotes / data /
     results / items 字段；
   - 确认每条句子至少有 text 或 hitokoto 字段；
   - 查看“句库下载”卡片里的状态文本和 hitokoto.log。

5. 搜索没有结果
   - 先点“换一句”缓存一些句子，或先下载句库；
   - 离线库本身有 12 条，可以搜索“李白”“诗词”“劝学”等；
   - 查看 HitokotoSearchStatus 变量和 hitokoto.log。

6. 页面加载失败
   - PCL 会弹出 XAML 错误信息；
   - 常见原因是引号、花括号或 & 符号被误改；
   - 恢复 Custom.xaml 后重试。

七、已知限制
------------------------------------------------------------
1. 必须依赖同目录的 HitokotoRun.vbs 和 Hitokoto.ps1；
   没有脚本时，只能浏览内置离线库，联网、搜索和句库下载
   不会更新。
2. 需要 Windows Script Host 和 Windows PowerShell 5.1 或
   更高版本。
3. “搜索”“保存并测试”“下载完整句库”会把输入框文本
   直接拼进命令行，因此输入内容不能包含英文双引号；
   搜索时如果含英文双引号，请用“复制关键词 →
   从剪贴板搜索”。
4. 搜索结果最多展示 5 条；联网缓存最多保留 500 条；
   服务器句库上限 5 万条，建议不超过 2 万条，避免搜索过慢。
5. 本页按 PCL 2.99 快照版的变量与事件机制编写。
   PCL 社区版（PCL CE）使用不同的自定义变量存储方式，
   未做兼容验证。
6. 一言正文版权归原作者所有；本主页仅用于学习与个人使用。
   离线库中的句子均为公版古诗文。
7. GitHub 与 B 站按钮直接打开当前配置的地址；
   如需更换，修改对应按钮的 EventData 和按钮文本即可。

八、测试注意事项
------------------------------------------------------------
- 联网测试：点击“换一句”，确认状态变为“在线”，
  且句子、出处、类型变化；
- 断网测试：断开网络后点击“换一句”，确认状态变为
  “离线”，且仍显示一句本地库内容；
- 搜索测试：搜索“李白”，应出现《行路难·其一》；
  搜索“不存在的词”，应显示无结果提示；
- API 测试：在“API 设置”里点“保存并测试”，确认
  API 状态变为“API 测试成功”；
- 句库测试：填入一个真实 JSON 句库地址，下载后
  搜索句库中的某个词，确认结果标签为“句库”；
- 复制测试：点击“复制这句话”，粘贴到记事本；
- 关于测试：点击“打开 项目仓库”“打开 作者B站空间”，
  确认浏览器被正常调起；
- 路径测试：把整个启动器目录搬到别处，只要
  Custom.xaml、HitokotoRun.vbs、Hitokoto.ps1、Hitokoto
  文件夹保持在一起，相对路径应继续可用；
- 隐藏启动测试：点击“换一句”，确认不再闪出 PowerShell
  控制台窗口，但 hitokoto.log 仍有新增记录。

九、安全与校验
------------------------------------------------------------
1. 权限边界
   - 不申请管理员权限，不创建服务、驱动、计划任务或启动项；
   - 只写 HKCU\Software\PCL* 和 PCL\Hitokoto\；
   - 只访问你填写的 API / 句库地址，不上传本地文件；
   - 不调用 Invoke-Expression，不下载后执行任何文件；
   - 剪贴板只在点击“从剪贴板搜索”时读取，日志不记录原文。

2. 输入限制
   - API / 句库地址只接受 http:// 或 https://；
   - 地址不能包含空格、英文双引号、账号密码、# 或控制字符；
   - API 响应上限 256 KiB，句库响应上限 16 MiB、最多 5 万条。

3. 校验哈希
   仓库根目录的 SHA256SUMS.txt 记录发布文件哈希。下载后执行：

     Get-FileHash .\Hitokoto.ps1 -Algorithm SHA256
     Get-FileHash .\HitokotoRun.vbs -Algorithm SHA256
     Get-FileHash .\Custom.xaml -Algorithm SHA256
     Get-FileHash .\Hitokoto\offline.json -Algorithm SHA256

   与 SHA256SUMS.txt 对应行比较；不一致时不要运行。

4. 残余风险
   - HitokotoRun.vbs 使用 -ExecutionPolicy Bypass，因为下载包可能
     带“来自 Internet”标记；脚本是明文可读的，但仍应核对哈希；
   - 自定义 API 返回的文字只显示/复制，不会执行，但要警惕诈骗内容；
   - 不要把长期 Token 放在 API URL 查询参数中，否则它会随地址
     写入 config.json，并显示在 API 设置输入框；
   - 本地 JSON 和日志未加密，同一用户下的其他程序可以读取。

更完整的说明见客户端根目录的 SECURITY.md。
