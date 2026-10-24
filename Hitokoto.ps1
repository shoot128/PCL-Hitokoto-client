#requires -Version 5.1
<#
    PCL 一言主页助手（Hitokoto.ps1）
    ------------------------------------------------------------------
    作用：
      1. 调用官方 API 或自定义 API 获取一言；
      2. 把结果写入注册表变量，供 Custom.xaml 的 {variable:...} 读取；
      3. 把联网获取的句子追加到 Hitokoto\quotes.json；
      4. 断网时从离线库 / 服务器句库随机取一句；
      5. 在缓存、服务器句库和离线库中搜索句子，并把前 5 条写回主页；
      6. 支持从自己的服务器下载完整 JSON 句库到 Hitokoto\library.json；
      7. 写完后向 PCL 窗口发送 F5，让主页重新读取数据。

    注意：
      - 这是“按钮调用 PowerShell”的方案，因为 PCL 自定义主页
        本身不能直接发起 HTTP 请求或读取本地文件。
      - 首次执行时 PCL 会弹出命令确认，选择“继续且今后不再要求确认”。
      - 脚本和 Custom.xaml 都放在 PCL 数据文件夹（PCL\）下；
        Custom.xaml 通过相对路径 HitokotoRun.vbs 隐藏启动本脚本。
#>

[CmdletBinding()]
param(
    [ValidateSet('next', 'random', 'search', 'search-clipboard', 'clear', 'set-api', 'download-library')]
    [string]$Action = 'next',
    [string]$Query = '',
    [string]$ApiUrl = '',
    [string]$LibraryUrl = ''
)

$ErrorActionPreference = 'Stop'

$script:Root        = $PSScriptRoot
$script:DataDir     = Join-Path $script:Root 'Hitokoto'
$script:StoreFile   = Join-Path $script:DataDir 'quotes.json'
$script:OfflineFile = Join-Path $script:DataDir 'offline.json'
$script:LibraryFile = Join-Path $script:DataDir 'library.json'
$script:ConfigFile  = Join-Path $script:DataDir 'config.json'
$script:LogFile     = Join-Path $script:DataDir 'hitokoto.log'
$script:StateFile   = Join-Path $script:DataDir 'state.json'
$script:NoneText    = '（无）'
$script:DefaultApiUrl = 'https://v1.hitokoto.cn/'
$script:LibraryCountCache = $null

# 当 offline.json 丢失时使用的兜底数据。
$script:EmbeddedOffline = @(
    [pscustomobject]@{ id = 'offline-001'; text = '路漫漫其修远兮，吾将上下而求索。'; source = '《离骚》'; author = '屈原'; type = '诗词'; fetchedAt = '离线库' },
    [pscustomobject]@{ id = 'offline-002'; text = '长风破浪会有时，直挂云帆济沧海。'; source = '《行路难·其一》'; author = '李白'; type = '诗词'; fetchedAt = '离线库' },
    [pscustomobject]@{ id = 'offline-003'; text = '海上生明月，天涯共此时。'; source = '《望月怀远》'; author = '张九龄'; type = '诗词'; fetchedAt = '离线库' },
    [pscustomobject]@{ id = 'offline-004'; text = '会当凌绝顶，一览众山小。'; source = '《望岳》'; author = '杜甫'; type = '诗词'; fetchedAt = '离线库' },
    [pscustomobject]@{ id = 'offline-005'; text = '山重水复疑无路，柳暗花明又一村。'; source = '《游山西村》'; author = '陆游'; type = '诗词'; fetchedAt = '离线库' },
    [pscustomobject]@{ id = 'offline-006'; text = '千磨万击还坚劲，任尔东西南北风。'; source = '《竹石》'; author = '郑燮'; type = '诗词'; fetchedAt = '离线库' },
    [pscustomobject]@{ id = 'offline-007'; text = '博观而约取，厚积而薄发。'; source = '《稼说送张琥》'; author = '苏轼'; type = '文学'; fetchedAt = '离线库' },
    [pscustomobject]@{ id = 'offline-008'; text = '纸上得来终觉浅，绝知此事要躬行。'; source = '《冬夜读书示子聿》'; author = '陆游'; type = '诗词'; fetchedAt = '离线库' },
    [pscustomobject]@{ id = 'offline-009'; text = '天行健，君子以自强不息。'; source = '《周易》'; author = ''; type = '哲学'; fetchedAt = '离线库' },
    [pscustomobject]@{ id = 'offline-010'; text = '地势坤，君子以厚德载物。'; source = '《周易》'; author = ''; type = '哲学'; fetchedAt = '离线库' },
    [pscustomobject]@{ id = 'offline-011'; text = '不积跬步，无以至千里；不积小流，无以成江海。'; source = '《劝学》'; author = '荀子'; type = '文学'; fetchedAt = '离线库' },
    [pscustomobject]@{ id = 'offline-012'; text = '锲而不舍，金石可镂。'; source = '《劝学》'; author = '荀子'; type = '文学'; fetchedAt = '离线库' }
)

function Write-HitokotoLog {
    param([string]$Message)
    try {
        if (-not (Test-Path -LiteralPath $script:DataDir)) {
            New-Item -ItemType Directory -Path $script:DataDir -Force | Out-Null
        }
        $line = '[{0}] {1}' -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'), $Message
        Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8
    }
    catch {
        # 日志失败不应影响主流程。
    }
}

function Ensure-HitokotoDirs {
    if (-not (Test-Path -LiteralPath $script:DataDir)) {
        New-Item -ItemType Directory -Path $script:DataDir -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $script:StoreFile)) {
        Save-QuoteFile -Path $script:StoreFile -Quotes @()
    }
    if (-not (Test-Path -LiteralPath $script:ConfigFile)) {
        Save-Config -ApiUrl $script:DefaultApiUrl -LibraryUrl ''
    }
}

function Write-JsonFile {
    param(
        [string]$Path,
        $Object
    )
    $json = $Object | ConvertTo-Json -Depth 10
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $tmp = $Path + '.tmp'
    [System.IO.File]::WriteAllText($tmp, $json, $encoding)
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force
    }
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Save-QuoteFile {
    param(
        [string]$Path,
        [object[]]$Quotes
    )
    if ($null -eq $Quotes) { $Quotes = @() }
    $payload = [ordered]@{
        updatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        quotes    = @($Quotes)
    }
    Write-JsonFile -Path $Path -Object $payload
}

function Get-Config {
    $apiUrl = $script:DefaultApiUrl
    $libraryUrl = ''
    if (Test-Path -LiteralPath $script:ConfigFile) {
        try {
            $data = Get-Content -LiteralPath $script:ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -ne $data.PSObject.Properties['apiUrl'] -and -not [string]::IsNullOrWhiteSpace([string]$data.apiUrl)) {
                $apiUrl = [string]$data.apiUrl
            }
            if ($null -ne $data.PSObject.Properties['libraryUrl']) {
                $libraryUrl = [string]$data.libraryUrl
            }
        }
        catch {
            Write-HitokotoLog ('读取 config.json 失败：' + $_.Exception.Message)
        }
    }
    return [pscustomobject]@{ apiUrl = $apiUrl; libraryUrl = $libraryUrl }
}

function Save-Config {
    param(
        [string]$ApiUrl,
        [string]$LibraryUrl
    )
    $payload = [ordered]@{
        apiUrl     = $ApiUrl
        libraryUrl = $LibraryUrl
        updatedAt  = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
    Write-JsonFile -Path $script:ConfigFile -Object $payload
}

function Get-ApiUrl {
    $cfg = Get-Config
    $url = ([string]$cfg.apiUrl).Trim()
    if ([string]::IsNullOrWhiteSpace($url) -or -not ($url -match '^https?://')) {
        return $script:DefaultApiUrl
    }
    return $url
}

function Build-ApiUri {
    param([string]$BaseUrl)
    $uri = ([string]$BaseUrl).Trim()
    if ([string]::IsNullOrWhiteSpace($uri)) { $uri = $script:DefaultApiUrl }

    $params = @()
    if ($uri -match '(?i)([?&])encode=') {
        # 如果用户从浏览器复制了 encode=text 之类的地址，强制改成 JSON。
        $uri = [regex]::Replace($uri, '(?i)([?&])encode=[^&]*', '${1}encode=json')
    }
    else {
        $params += 'encode=json'
    }
    if ($uri -notmatch '(?i)(^|[?&])charset=') { $params += 'charset=utf-8' }
    if ($params.Count -eq 0) { return $uri }

    if ($uri.EndsWith('?') -or $uri.EndsWith('&')) {
        return $uri + ($params -join '&')
    }
    if ($uri.Contains('?')) {
        return $uri + '&' + ($params -join '&')
    }
    return $uri + '?' + ($params -join '&')
}

function Get-LibraryCount {
    if ($null -ne $script:LibraryCountCache) { return [int]$script:LibraryCountCache }
    $library = @(Read-QuoteFile -Path $script:LibraryFile -Origin 'library')
    $script:LibraryCountCache = $library.Count
    return [int]$script:LibraryCountCache
}

function Save-Library {
    param(
        [object[]]$Quotes,
        [string]$SourceUrl
    )
    if ($null -eq $Quotes) { $Quotes = @() }
    $payload = [ordered]@{
        updatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        source    = $SourceUrl
        count     = @($Quotes).Count
        quotes    = @($Quotes)
    }
    Write-JsonFile -Path $script:LibraryFile -Object $payload
    $script:LibraryCountCache = @($Quotes).Count
}

function Read-QuoteFile {
    param(
        [string]$Path,
        [string]$Origin
    )
    $result = New-Object System.Collections.ArrayList
    if (-not (Test-Path -LiteralPath $Path)) { return @() }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($raw)) { return @() }

        $data = $raw | ConvertFrom-Json
        $items = @()
        if ($data -is [System.Array]) {
            $items = @($data)
        }
        elseif ($null -ne $data -and $null -ne $data.PSObject.Properties['quotes']) {
            $items = @($data.quotes)
        }
        elseif ($null -ne $data) {
            $items = @($data)
        }

        foreach ($item in $items) {
            if ($null -eq $item) { continue }
            if ($null -eq $item.PSObject.Properties['text']) { continue }
            $text = [string]$item.text
            if ([string]::IsNullOrWhiteSpace($text)) { continue }

            [void]$result.Add([pscustomobject]@{
                id        = [string]$item.id
                text      = $text.Trim()
                source    = [string]$item.source
                author    = [string]$item.author
                type      = [string]$item.type
                typeCode  = [string]$item.typeCode
                createdAt = [string]$item.createdAt
                fetchedAt = [string]$item.fetchedAt
                origin    = $Origin
            })
        }
    }
    catch {
        Write-HitokotoLog ("读取 {0} 失败：{1}" -f $Path, $_.Exception.Message)
    }

    return @($result)
}

function Set-PclVariable {
    param(
        [string]$Name,
        [string]$Value
    )
    if ($null -eq $Value) { $Value = '' }

    # PCL 可能是 32 位或 64 位进程，因此 32/64 位注册表视图都写一遍。
    $views = @(
        [Microsoft.Win32.RegistryView]::Default,
        [Microsoft.Win32.RegistryView]::Registry32,
        [Microsoft.Win32.RegistryView]::Registry64
    )
    $subKeys = @(
        'Software\PCL',
        'Software\PCL2',
        'Software\PCLDebug',
        'Software\PCLCE'
    )

    foreach ($view in $views) {
        foreach ($subKey in $subKeys) {
            $baseKey = $null
            $key = $null
            try {
                $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::CurrentUser, $view)
                $key = $baseKey.CreateSubKey($subKey)
                $key.SetValue(('CustomEvent' + $Name), $Value, [Microsoft.Win32.RegistryValueKind]::String)
            }
            catch {
                # 32 位系统上 Registry64 会失败，忽略即可。
            }
            finally {
                if ($null -ne $key) { $key.Dispose() }
                if ($null -ne $baseKey) { $baseKey.Dispose() }
            }
        }
    }
}

function Format-QuoteMeta {
    param($Quote)
    $parts = @()
    if (-not [string]::IsNullOrWhiteSpace([string]$Quote.source)) { $parts += [string]$Quote.source }
    if (-not [string]::IsNullOrWhiteSpace([string]$Quote.author)) { $parts += [string]$Quote.author }
    if (-not [string]::IsNullOrWhiteSpace([string]$Quote.type))   { $parts += [string]$Quote.type }
    if ($parts.Count -eq 0) { return '—— 一言' }
    return '—— ' + ($parts -join ' / ')
}

function Get-CacheCount {
    $cache = @(Read-QuoteFile -Path $script:StoreFile -Origin 'online')
    return $cache.Count
}

function Get-QuoteInfo {
    param(
        $Quote,
        [string]$Mode
    )
    $parts = @()
    if (-not [string]::IsNullOrWhiteSpace([string]$Quote.type)) {
        $parts += ('类型：' + [string]$Quote.type)
    }
    $parts += ('缓存：' + (Get-CacheCount) + ' 条')
    $libraryCount = Get-LibraryCount
    if ($libraryCount -gt 0) { $parts += ('句库：' + $libraryCount + ' 条') }
    if (-not [string]::IsNullOrWhiteSpace($Mode)) { $parts += $Mode }
    if (-not [string]::IsNullOrWhiteSpace([string]$Quote.fetchedAt)) {
        $parts += ('获取：' + [string]$Quote.fetchedAt)
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$Quote.id)) {
        $parts += ('ID：' + [string]$Quote.id)
    }
    return ($parts -join ' · ')
}

function Set-PclQuoteVariables {
    param(
        $Quote,
        [string]$Status,
        [string]$Info
    )
    Set-PclVariable -Name 'HitokotoText'   -Value ([string]$Quote.text)
    Set-PclVariable -Name 'HitokotoMeta'   -Value (Format-QuoteMeta -Quote $Quote)
    Set-PclVariable -Name 'HitokotoStatus' -Value $Status
    Set-PclVariable -Name 'HitokotoInfo'   -Value $Info
}

function Get-OfflineQuotes {
    $fileQuotes = @(Read-QuoteFile -Path $script:OfflineFile -Origin 'offline')
    if ($fileQuotes.Count -gt 0) { return $fileQuotes }
    return @($script:EmbeddedOffline | ForEach-Object {
        [pscustomobject]@{
            id        = [string]$_.id
            text      = [string]$_.text
            source    = [string]$_.source
            author    = [string]$_.author
            type      = [string]$_.type
            typeCode  = [string]$_.typeCode
            createdAt = [string]$_.createdAt
            fetchedAt = [string]$_.fetchedAt
            origin    = 'offline'
        }
    })
}

function Get-AllQuotes {
    $cache = @(Read-QuoteFile -Path $script:StoreFile -Origin 'online')
    $library = @(Read-QuoteFile -Path $script:LibraryFile -Origin 'library')
    $offline = @(Get-OfflineQuotes)
    $seen = @{}
    $all = New-Object System.Collections.ArrayList

    foreach ($item in @($cache + $library + $offline)) {
        $key = [string]$item.text
        if ([string]::IsNullOrWhiteSpace($key)) { $key = [string]$item.id }
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            [void]$all.Add($item)
        }
    }
    return @($all)
}

function Save-OnlineQuote {
    param($Quote)
    $existing = @(Read-QuoteFile -Path $script:StoreFile -Origin 'online')
    $list = New-Object System.Collections.ArrayList
    [void]$list.Add($Quote)
    foreach ($item in $existing) { [void]$list.Add($item) }

    $seen = @{}
    $unique = New-Object System.Collections.ArrayList
    foreach ($item in $list) {
        $key = [string]$item.id
        if ([string]::IsNullOrWhiteSpace($key)) { $key = [string]$item.text }
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            [void]$unique.Add($item)
        }
    }

    $trimmed = @($unique | Select-Object -First 500)
    Save-QuoteFile -Path $script:StoreFile -Quotes $trimmed
}

function Get-TypeName {
    param([string]$Code)
    switch ($Code) {
        'a' { return '动画' }
        'b' { return '漫画' }
        'c' { return '游戏' }
        'd' { return '文学' }
        'e' { return '原创' }
        'f' { return '来自网络' }
        'g' { return '其他' }
        'h' { return '影视' }
        'i' { return '诗词' }
        'j' { return '网易云' }
        'k' { return '哲学' }
        'l' { return '抖机灵' }
        default { return '其他' }
    }
}

function Get-FirstString {
    param(
        $Item,
        [string[]]$Names
    )
    if ($null -eq $Item) { return '' }
    foreach ($name in $Names) {
        if ($null -ne $Item.PSObject.Properties[$name]) {
            $value = [string]$Item.$name
            if (-not [string]::IsNullOrWhiteSpace($value)) { return $value.Trim() }
        }
    }
    return ''
}

function Invoke-HitokotoApi {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    catch { }

    $apiUrl = Get-ApiUrl
    $uri = Build-ApiUri -BaseUrl $apiUrl
    $headers = @{
        'User-Agent'      = 'PCL-Hitokoto-Homepage/1.0'
        'Accept'          = 'application/json'
        'Accept-Encoding' = 'identity'
    }

    $response = Invoke-WebRequest -Uri $uri -Headers $headers -TimeoutSec 6 -UseBasicParsing
    if ($null -ne $response.RawContentStream) {
        $bytes = $response.RawContentStream.ToArray()
        $jsonText = [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    else {
        $jsonText = [string]$response.Content
    }

    $jsonText = $jsonText.TrimStart([char]0xFEFF)
    $data = $jsonText | ConvertFrom-Json
    $payload = $data

    if ($payload -is [System.Array]) {
        if ($payload.Count -eq 0) { throw 'API 返回了空数组' }
        $payload = $payload[0]
    }
    elseif ($null -ne $payload.PSObject.Properties['data'] -and $null -ne $payload.data) {
        if ($payload.data -is [System.Array]) {
            if ($payload.data.Count -eq 0) { throw 'API 的 data 为空' }
            $payload = $payload.data[0]
        }
        else {
            $payload = $payload.data
        }
    }

    $text = Get-FirstString -Item $payload -Names @('hitokoto', 'text', 'quote', 'content')
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw 'API 返回的句子为空'
    }

    $typeRaw = Get-FirstString -Item $payload -Names @('type', 'category')
    $typeName = $typeRaw
    if ($typeRaw.Length -eq 1) { $typeName = Get-TypeName $typeRaw }
    if ([string]::IsNullOrWhiteSpace($typeName)) { $typeName = '其他' }

    $createdAt = ''
    try {
        $createdRaw = Get-FirstString -Item $payload -Names @('created_at', 'createdAt')
        if (-not [string]::IsNullOrWhiteSpace($createdRaw)) {
            $createdAt = [DateTimeOffset]::FromUnixTimeSeconds([int64]$createdRaw).LocalDateTime.ToString('yyyy-MM-dd HH:mm:ss')
        }
    }
    catch { $createdAt = '' }

    return [pscustomobject]@{
        id        = (Get-FirstString -Item $payload -Names @('uuid', 'id'))
        text      = $text.Trim()
        source    = (Get-FirstString -Item $payload -Names @('from', 'source'))
        author    = (Get-FirstString -Item $payload -Names @('from_who', 'author'))
        type      = $typeName
        typeCode  = $typeRaw
        createdAt = $createdAt
        fetchedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        origin    = 'online'
    }
}

function Get-FallbackQuote {
    $pool = @(Get-AllQuotes)
    if ($pool.Count -eq 0) {
        return [pscustomobject]@{
            id        = 'offline-000'
            text      = '暂时没有可用的离线句子，请检查 Hitokoto\offline.json 是否存在。'
            source    = ''
            author    = ''
            type      = ''
            typeCode  = ''
            createdAt = ''
            fetchedAt = '离线库'
            origin    = 'offline'
        }
    }
    $index = Get-Random -Minimum 0 -Maximum $pool.Count
    return $pool[$index]
}

function Invoke-SetApi {
    param([string]$ApiUrl)
    $url = ([string]$ApiUrl).Trim()

    if ([string]::IsNullOrWhiteSpace($url)) {
        Set-PclVariable 'HitokotoApiStatus' '请输入 API 地址，例如 https://v1.hitokoto.cn/'
        return
    }
    if (-not ($url -match '^https?://')) {
        Set-PclVariable 'HitokotoApiStatus' 'API 地址必须以 http:// 或 https:// 开头。'
        return
    }
    if ($url -match '[\r\n"]') {
        Set-PclVariable 'HitokotoApiStatus' 'API 地址不能包含英文双引号或换行。'
        return
    }

    $cfg = Get-Config
    Save-Config -ApiUrl $url -LibraryUrl $cfg.libraryUrl
    Set-PclVariable 'HitokotoApiUrl' $url
    Set-PclVariable 'HitokotoApiStatus' 'API 地址已保存，正在测试……'

    try {
        $quote = Invoke-HitokotoApi
        try {
            Save-OnlineQuote -Quote $quote
        }
        catch {
            Write-HitokotoLog ('写入 quotes.json 失败：' + $_.Exception.Message)
        }
        Set-PclQuoteVariables -Quote $quote -Status '● 在线 · 自定义 API 测试成功' -Info (Get-QuoteInfo -Quote $quote -Mode '来源：自定义 API')
        Set-PclVariable 'HitokotoApiStatus' ('API 测试成功：' + $url)
        Write-HitokotoLog ('自定义 API 测试成功：' + $url)
    }
    catch {
        $message = $_.Exception.Message
        Set-PclVariable 'HitokotoApiStatus' ('API 已保存，但测试失败：' + $message)
        $fallback = Get-FallbackQuote
        Set-PclQuoteVariables -Quote $fallback -Status '● 离线 · 自定义 API 暂不可用，已显示本地句子' -Info (Get-QuoteInfo -Quote $fallback -Mode '来源：本地库')
        Write-HitokotoLog ('自定义 API 测试失败：' + $message)
    }
}

function Get-QuoteItemsFromData {
    param($Data)
    if ($null -eq $Data) { return @() }
    if ($Data -is [System.Array]) { return @($Data) }

    foreach ($key in @('quotes', 'data', 'results', 'items')) {
        if ($null -ne $Data.PSObject.Properties[$key] -and $null -ne $Data.$key) {
            $value = $Data.$key
            if ($value -is [System.Array]) { return @($value) }
            if ($null -ne $value.PSObject.Properties['quotes'] -and $null -ne $value.quotes) {
                return @($value.quotes)
            }
            if ($null -ne $value.PSObject.Properties['hitokoto']) {
                return @($value)
            }
            return @($value)
        }
    }

    if ($null -ne $Data.PSObject.Properties['hitokoto']) { return @($Data) }
    return @()
}

function Get-RemoteLibrary {
    param([string]$Url)
    $headers = @{
        'User-Agent'      = 'PCL-Hitokoto-Homepage/1.0'
        'Accept'          = 'application/json'
        'Accept-Encoding' = 'identity'
    }
    $response = Invoke-WebRequest -Uri $Url -Headers $headers -TimeoutSec 30 -UseBasicParsing
    if ($null -ne $response.RawContentStream) {
        $bytes = $response.RawContentStream.ToArray()
        $jsonText = [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    else {
        $jsonText = [string]$response.Content
    }

    $jsonText = $jsonText.TrimStart([char]0xFEFF)
    $data = $jsonText | ConvertFrom-Json
    $items = @(Get-QuoteItemsFromData -Data $data)
    $seen = @{}
    $normalized = New-Object System.Collections.ArrayList

    foreach ($item in $items) {
        if ($null -eq $item) { continue }
        $text = Get-FirstString -Item $item -Names @('text', 'hitokoto', 'content', 'quote')
        if ([string]::IsNullOrWhiteSpace($text)) { continue }

        $typeRaw = Get-FirstString -Item $item -Names @('type', 'category')
        $typeName = $typeRaw
        if ($typeRaw.Length -eq 1) { $typeName = Get-TypeName $typeRaw }
        if ([string]::IsNullOrWhiteSpace($typeName)) { $typeName = '其他' }

        $id = Get-FirstString -Item $item -Names @('id', 'uuid')
        $key = $id
        if ([string]::IsNullOrWhiteSpace($key)) { $key = $text }
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true

        $createdRaw = Get-FirstString -Item $item -Names @('created_at', 'createdAt')
        $createdAt = $createdRaw
        if ($createdRaw -match '^\d+$') {
            try {
                $createdAt = [DateTimeOffset]::FromUnixTimeSeconds([int64]$createdRaw).LocalDateTime.ToString('yyyy-MM-dd HH:mm:ss')
            }
            catch { $createdAt = '' }
        }

        [void]$normalized.Add([pscustomobject]@{
            id        = $id
            text      = $text.Trim()
            source    = (Get-FirstString -Item $item -Names @('source', 'from'))
            author    = (Get-FirstString -Item $item -Names @('author', 'from_who'))
            type      = $typeName
            typeCode  = $typeRaw
            createdAt = $createdAt
            fetchedAt = '服务器句库'
            origin    = 'library'
        })
    }

    if ($normalized.Count -eq 0) {
        throw '没有解析到有效句子；请确认返回的是 JSON 数组，或包含 quotes / data / results / items 字段。'
    }
    return @($normalized)
}

function Invoke-DownloadLibrary {
    param([string]$LibraryUrl)
    $url = ([string]$LibraryUrl).Trim()

    if ([string]::IsNullOrWhiteSpace($url)) {
        Set-PclVariable 'HitokotoLibraryStatus' '请先填写句库 JSON 地址。'
        return
    }
    if (-not ($url -match '^https?://')) {
        Set-PclVariable 'HitokotoLibraryStatus' '句库地址必须以 http:// 或 https:// 开头。'
        return
    }
    if ($url -match '[\r\n"]') {
        Set-PclVariable 'HitokotoLibraryStatus' '句库地址不能包含英文双引号或换行。'
        return
    }

    $cfg = Get-Config
    Save-Config -ApiUrl $cfg.apiUrl -LibraryUrl $url
    Set-PclVariable 'HitokotoLibraryUrl' $url
    Set-PclVariable 'HitokotoLibraryStatus' '正在从服务器下载句库……'

    try {
        $items = @(Get-RemoteLibrary -Url $url)
        Save-Library -Quotes $items -SourceUrl $url
        $hostName = ''
        try { $hostName = ([Uri]$url).Host } catch { }
        Set-PclVariable 'HitokotoLibraryStatus' ('已下载 ' + $items.Count + ' 条句库（来源：' + $hostName + '）。搜索会一并检索。')
        Set-PclVariable 'HitokotoLibraryCount' ([string]$items.Count)
        Write-HitokotoLog ('句库下载成功：' + $items.Count + ' 条，来源 ' + $url)
    }
    catch {
        $message = $_.Exception.Message
        Set-PclVariable 'HitokotoLibraryStatus' ('下载失败：' + $message)
        Write-HitokotoLog ('句库下载失败：' + $message)
    }
}

function Invoke-Next {
    $apiUrl = Get-ApiUrl
    Set-PclVariable 'HitokotoApiUrl' $apiUrl
    Set-PclVariable 'HitokotoApiStatus' ('正在通过 API 获取：' + $apiUrl)

    $cfg = Get-Config
    if (-not [string]::IsNullOrWhiteSpace($cfg.libraryUrl)) {
        Set-PclVariable 'HitokotoLibraryUrl' $cfg.libraryUrl
    }

    $lastUuid = ''
    $lastText = ''
    try {
        if (Test-Path -LiteralPath $script:StateFile) {
            $state = Get-Content -LiteralPath $script:StateFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $lastUuid = [string]$state.lastUuid
            $lastText = [string]$state.lastText
        }
    }
    catch { }

    $quote = $null
    $lastError = $null

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $candidate = Invoke-HitokotoApi
            $sameUuid = (-not [string]::IsNullOrWhiteSpace($lastUuid)) -and ($candidate.id -eq $lastUuid)
            $sameText = (-not [string]::IsNullOrWhiteSpace($lastText)) -and ($candidate.text -eq $lastText)
            if (($sameUuid -or $sameText) -and $attempt -lt 3) {
                Write-HitokotoLog ("第 {0} 次获取到与上次相同的句子，自动重试：{1}" -f $attempt, $candidate.id)
                Start-Sleep -Milliseconds 250
                continue
            }
            $quote = $candidate
            break
        }
        catch {
            $lastError = $_
            Write-HitokotoLog ("第 {0} 次联网获取失败：{1}" -f $attempt, $_.Exception.Message)
            Start-Sleep -Milliseconds 350
        }
    }

    if ($null -ne $quote) {
        try {
            Save-OnlineQuote -Quote $quote
        }
        catch {
            Write-HitokotoLog ("写入 quotes.json 失败：{0}" -f $_.Exception.Message)
        }
        try {
            $state = [ordered]@{
                lastUuid  = [string]$quote.id
                lastText  = [string]$quote.text
                updatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
            $json = $state | ConvertTo-Json -Depth 5
            [System.IO.File]::WriteAllText($script:StateFile, $json, (New-Object System.Text.UTF8Encoding($false)))
        }
        catch { }

        Set-PclQuoteVariables -Quote $quote -Status '● 在线 · 已从 API 获取' -Info (Get-QuoteInfo -Quote $quote -Mode ('来源：' + $apiUrl))
        Set-PclVariable 'HitokotoApiStatus' ('API 正常：' + $apiUrl)
        Write-HitokotoLog ("联网获取成功：{0} | {1}" -f $quote.id, $quote.text)
    }
    else {
        $fallback = Get-FallbackQuote
        $reason = '未知错误'
        if ($null -ne $lastError) { $reason = $lastError.Exception.Message }
        Set-PclQuoteVariables -Quote $fallback -Status '● 离线 · 网络请求失败，已自动使用本地一言库' -Info (Get-QuoteInfo -Quote $fallback -Mode '来源：离线库')
        Set-PclVariable 'HitokotoApiStatus' ('API 失败：' + $reason + '；已使用本地库。')
        Write-HitokotoLog ("联网获取失败，已降级到离线库。最后错误：{0}" -f $reason)
    }
}

function Invoke-Random {
    $pool = @(Get-AllQuotes)
    if ($pool.Count -eq 0) {
        $fallback = Get-FallbackQuote
        Set-PclQuoteVariables -Quote $fallback -Status '● 离线 · 本地库为空，已使用兜底句子' -Info (Get-QuoteInfo -Quote $fallback -Mode '来源：兜底')
        return
    }

    $index = Get-Random -Minimum 0 -Maximum $pool.Count
    $quote = $pool[$index]
    $origin = [string]$quote.origin
    if ($origin -eq 'offline') {
        $status = '● 离线 · 来自内置离线一言库'
        $mode = '来源：内置离线库'
    }
    elseif ($origin -eq 'library') {
        $status = '● 本地句库 · 未联网'
        $mode = '来源：服务器句库'
    }
    else {
        $status = '● 本地缓存 · 未联网'
        $mode = '来源：本地缓存'
    }
    Set-PclQuoteVariables -Quote $quote -Status $status -Info (Get-QuoteInfo -Quote $quote -Mode $mode)
    Write-HitokotoLog ("从本地库取一句：{0} | {1}" -f $quote.id, $quote.text)
}

function Clear-SearchResults {
    for ($i = 1; $i -le 5; $i++) {
        Set-PclVariable -Name ("HitokotoResult{0}Title" -f $i) -Value $script:NoneText
        Set-PclVariable -Name ("HitokotoResult{0}Info" -f $i) -Value '—'
    }
}

function Invoke-Search {
    param([string]$SearchQuery)

    $keyword = ''
    if ($null -ne $SearchQuery) { $keyword = $SearchQuery.Trim() }

    if ([string]::IsNullOrWhiteSpace($keyword)) {
        Clear-SearchResults
        Set-PclVariable -Name 'HitokotoSearchStatus' -Value '请输入关键词后再搜索。'
        return
    }

    $all = @(Get-AllQuotes)
    $matched = @()
    foreach ($item in $all) {
        $hit = $false
        foreach ($field in @('text', 'source', 'author', 'type')) {
            $value = [string]$item.$field
            if (-not [string]::IsNullOrWhiteSpace($value) -and
                $value.IndexOf($keyword, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $hit = $true
                break
            }
        }
        if ($hit) { $matched += $item }
    }

    $total = $matched.Count
    $offlineMatches = @($matched | Where-Object { [string]$_.origin -eq 'offline' })
    $libraryMatches = @($matched | Where-Object { [string]$_.origin -eq 'library' })
    $offlineCount = $offlineMatches.Count
    $libraryCount = $libraryMatches.Count
    $cacheCount = $total - $offlineCount - $libraryCount

    if ($total -eq 0) {
        Set-PclVariable -Name 'HitokotoSearchStatus' -Value ('搜索“{0}”：没有找到匹配的句子。试试更短的关键词，或先点“换一句”缓存更多一言。' -f $keyword)
    }
    else {
        Set-PclVariable -Name 'HitokotoSearchStatus' -Value ('搜索“{0}”：找到 {1} 条（缓存 {2} / 句库 {3} / 离线 {4}）。点击下方结果可复制。' -f $keyword, $total, $cacheCount, $libraryCount, $offlineCount)
    }

    for ($i = 1; $i -le 5; $i++) {
        if ($i -le $matched.Count) {
            $item = $matched[$i - 1]
            $title = ([string]$item.text).Replace("`r", ' ').Replace("`n", ' ').Trim()
            if ([string]::IsNullOrWhiteSpace($title)) { $title = $script:NoneText }
            $originLabel = '缓存'
            if ([string]$item.origin -eq 'offline') { $originLabel = '离线库' }
            elseif ([string]$item.origin -eq 'library') { $originLabel = '句库' }
            $info = '{0} · {1}' -f (Format-QuoteMeta -Quote $item), $originLabel
            Set-PclVariable -Name ("HitokotoResult{0}Title" -f $i) -Value $title
            Set-PclVariable -Name ("HitokotoResult{0}Info" -f $i) -Value $info
        }
        else {
            Set-PclVariable -Name ("HitokotoResult{0}Title" -f $i) -Value $script:NoneText
            Set-PclVariable -Name ("HitokotoResult{0}Info" -f $i) -Value '—'
        }
    }

    Write-HitokotoLog ('搜索“{0}”：匹配 {1} 条（缓存 {2} / 句库 {3} / 离线 {4}）' -f $keyword, $total, $cacheCount, $libraryCount, $offlineCount)
}

function Invoke-SearchClipboard {
    $text = ''
    try {
        $text = Get-Clipboard -Raw -ErrorAction Stop
    }
    catch {
        Write-HitokotoLog ("读取剪贴板失败：{0}" -f $_.Exception.Message)
    }

    if ([string]::IsNullOrWhiteSpace($text)) {
        Clear-SearchResults
        Set-PclVariable -Name 'HitokotoSearchStatus' -Value '剪贴板为空，请先点击“复制关键词”。'
        return
    }
    Invoke-Search -SearchQuery $text
}

function Invoke-PclRefresh {
    try {
        Add-Type -AssemblyName Microsoft.VisualBasic
        Add-Type -AssemblyName System.Windows.Forms

        $windows = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 })

        # 优先按进程名匹配 PCL，避免误把标题里带 PCL 的浏览器窗口当成目标。
        $pcl = $windows | Where-Object {
            $_.ProcessName -like '*Plain Craft Launcher*' -or $_.ProcessName -like '*PCL*'
        } | Select-Object -First 1

        if ($null -eq $pcl) {
            $pcl = $windows | Where-Object {
                $_.MainWindowTitle -like '*PCL*' -or $_.MainWindowTitle -like '*Plain Craft Launcher*'
            } | Select-Object -First 1
        }

        if ($null -eq $pcl) {
            Write-HitokotoLog '未找到 PCL 窗口，跳过自动刷新。'
            return
        }

        [Microsoft.VisualBasic.Interaction]::AppActivate($pcl.Id) | Out-Null
        Start-Sleep -Milliseconds 250
        [System.Windows.Forms.SendKeys]::SendWait('{F5}')
        Write-HitokotoLog ("已向 PCL 发送 F5（PID {0}）" -f $pcl.Id)
    }
    catch {
        Write-HitokotoLog ("自动刷新失败：{0}" -f $_.Exception.Message)
    }
}

# ----------------------------- 主流程 -----------------------------

try {
    Ensure-HitokotoDirs
    Write-HitokotoLog ("开始执行：Action={0}, Query={1}" -f $Action, $Query)

    switch ($Action) {
        'next'             { Invoke-Next }
        'random'           { Invoke-Random }
        'search'           { Invoke-Search -SearchQuery $Query }
        'search-clipboard' { Invoke-SearchClipboard }
        'clear' {
            Clear-SearchResults
            Set-PclVariable -Name 'HitokotoSearchStatus' -Value '已清空搜索结果。输入关键词后点击“搜索”。'
        }
        'set-api'          { Invoke-SetApi -ApiUrl $ApiUrl }
        'download-library' { Invoke-DownloadLibrary -LibraryUrl $LibraryUrl }
        default            { Invoke-Next }
    }

    Invoke-PclRefresh
    Write-HitokotoLog '执行完成。'
    exit 0
}
catch {
    $message = $_.Exception.Message
    Write-HitokotoLog ("执行失败：{0}`r`n{1}" -f $message, $_.ScriptStackTrace)
    try {
        Set-PclVariable -Name 'HitokotoStatus' -Value ("● 出错 · {0}" -f $message)
        Set-PclVariable -Name 'HitokotoInfo' -Value '详情见 PCL\Hitokoto\hitokoto.log；可点击“刷新显示”重试。'
        Invoke-PclRefresh
    }
    catch { }
    exit 1
}
