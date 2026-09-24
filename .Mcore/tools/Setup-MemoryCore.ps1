param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Status', 'Setup', 'AddUser', 'AddAgent', 'UnlockVault', 'Login', 'Skills', 'Route', 'RecordTurn', 'SaveMemory', 'SaveDiary', 'SaveTopic', 'Recall', 'UpdateSession', 'Compact', 'Validate')]
    [string]$Action,
    [ValidateSet('Solo', 'Team')][string]$Mode,
    [string]$TeamName,
    [string]$UserId,
    [string]$UserName,
    [string]$AgentId,
    [string]$AgentName,
    [string]$GitHubLogin,
    [ValidateSet('User', 'Agent')][string]$Target = 'Agent',
    [ValidateSet('Facts', 'Preferences', 'Goals', 'Decisions', 'Questions')][string]$Category = 'Facts',
    [string]$Text,
    [string]$TopicId,
    [string]$Query,
    [string]$Summary,
    [string]$Instruction,
    [string]$Outcome,
    [ValidateSet('Completed', 'InProgress', 'Blocked')][string]$TurnStatus = 'Completed',
    [string]$EventId,
    [switch]$Primary
)

$ErrorActionPreference = 'Stop'
$coreRoot = Split-Path -Parent $PSScriptRoot
$statePath = Join-Path $coreRoot 'state.json'
$teamPath = Join-Path $coreRoot 'team.json'
$loginPath = Join-Path $coreRoot '.login.json'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Assert-Id([string]$value, [string]$label) {
    if ($value -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        throw "$label must use lowercase letters, digits, and internal hyphens."
    }
}

function Assert-Text([string]$value, [string]$label) {
    if ([string]::IsNullOrWhiteSpace($value)) { throw "$label is required." }
}

function Read-Json([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing MemoryCore file: $path" }
    return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Write-Json([string]$path, $data) {
    $temporary = "$path.tmp"
    $json = $data | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($temporary, $json + [Environment]::NewLine, $utf8)
    Move-Item -LiteralPath $temporary -Destination $path -Force
}

function Get-State {
    if (Test-Path -LiteralPath $teamPath) {
        $team = Read-Json $teamPath
        if ($team.schema_version -ne 3 -or $team.mode -ne 'Team' -or $team.state -ne 'ready' -or $null -eq $team.users) {
            throw 'Invalid .Mcore/team.json schema.'
        }
        return $team
    }
    if (-not (Test-Path -LiteralPath $statePath)) {
        return [pscustomobject]@{
            schema_version = 3
            state = 'needs_setup'
            mode = $null
            team_name = $null
            owner_github_id = $null
            revision = 0
            users = @()
        }
    }
    $data = Read-Json $statePath
    if ($data.schema_version -ne 3 -or $data.mode -ne 'Solo' -or $data.state -ne 'ready' -or $null -eq $data.users) {
        throw 'Invalid .Mcore/state.json schema. Do not overwrite it.'
    }
    return $data
}

function Save-State($data) {
    $data.revision = [int]$data.revision + 1
    if ($data.mode -eq 'Team') { Write-Json $teamPath $data }
    else { Write-Json $statePath $data }
}

function Get-GitHubAccount([string]$login) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'GitHub CLI (gh) is required in team mode. Install it and run gh auth login.'
    }
    $global:LASTEXITCODE = 0
    if ([string]::IsNullOrWhiteSpace($login)) {
        $raw = & gh api user --hostname github.com --jq '{id: .id, login: .login}' 2>$null
    } else {
        if ($login -notmatch '^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$') {
            throw 'Invalid GitHub login name.'
        }
        $raw = & gh api "users/$login" --hostname github.com --jq '{id: .id, login: .login}' 2>$null
    }
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($raw -join ''))) {
        throw 'GitHub account check failed. Confirm gh auth login and network access.'
    }
    $account = ($raw -join [Environment]::NewLine) | ConvertFrom-Json
    if ($null -eq $account.id -or [string]::IsNullOrWhiteSpace($account.login)) {
        throw 'GitHub returned an incomplete account identity.'
    }
    return $account
}

function Get-LocalIdentity {
    $principal = [Environment]::UserName
    try { $principal = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value } catch {}
    return ([Environment]::MachineName + '|' + $principal)
}

function New-AgentMetadata([string]$id, [string]$name) {
    return [pscustomobject]@{ id = $id; name = $name }
}

function New-UserMetadata([string]$id, [string]$name, $agent, $githubAccount, [string]$localIdentity) {
    $github = $null
    if ($null -ne $githubAccount) {
        $github = [pscustomobject]@{ id = [string]$githubAccount.id; login = [string]$githubAccount.login }
    }
    return [pscustomobject]@{
        id = $id
        name = $name
        github = $github
        local_identity = $localIdentity
        primary_agent_id = $agent.id
        agents = @($agent)
    }
}

function Get-UserRoot([string]$id) {
    Assert-Id $id 'UserId'
    return (Join-Path $coreRoot "users/$id")
}

function Get-AgentRoot([string]$userId, [string]$agentId) {
    Assert-Id $agentId 'AgentId'
    return (Join-Path (Get-UserRoot $userId) "agents/$agentId")
}

function New-AgentFiles([string]$userId, [string]$agentId) {
    $agentRoot = Get-AgentRoot $userId $agentId
    if (Test-Path -LiteralPath $agentRoot) { throw "Agent directory already exists: $agentRoot" }
    New-Item -ItemType Directory -Path $agentRoot -Force | Out-Null
    Write-Json (Join-Path $agentRoot 'identity.json') ([pscustomobject]@{ role = 'AI assistant'; style = '' })
    Write-Json (Join-Path $agentRoot 'memory.json') ([pscustomobject]@{
        summary = ''
        facts = @()
        preferences = @()
        decisions = @()
        questions = @()
    })
    Write-Json (Join-Path $agentRoot 'session.json') ([pscustomobject]@{ summary = ''; updated_at = $null })
    Write-Json (Join-Path $agentRoot 'diary.json') ([pscustomobject]@{ entries = @() })
    Write-Json (Join-Path $agentRoot 'topics.json') ([pscustomobject]@{ topics = @() })
    Write-Json (Join-Path $agentRoot 'compaction.json') ([pscustomobject]@{
        policy = 'Summarize only when needed; preserve confirmed meaning and uncertainty.'
        snapshot = $null
        last_compacted_at = $null
    })
}

function New-UserFiles([string]$userId, [string]$agentId) {
    $userRoot = Get-UserRoot $userId
    if (Test-Path -LiteralPath $userRoot) { throw "User directory already exists: $userRoot" }
    New-Item -ItemType Directory -Path $userRoot -Force | Out-Null
    Write-Json (Join-Path $userRoot 'profile.json') ([pscustomobject]@{
        facts = @()
        preferences = @()
        goals = @()
    })
    New-AgentFiles $userId $agentId
}

function Ensure-LocalUserFiles($user) {
    $userRoot = Get-UserRoot $user.id
    if (-not (Test-Path -LiteralPath $userRoot)) {
        New-UserFiles $user.id $user.primary_agent_id
    }
    foreach ($agent in @($user.agents)) {
        $agentRoot = Get-AgentRoot $user.id $agent.id
        if (-not (Test-Path -LiteralPath $agentRoot)) { New-AgentFiles $user.id $agent.id }
    }
}

function Require-Ready($data) {
    if ($data.state -ne 'ready') { throw 'MemoryCore needs setup. Follow setup-wizard.md first.' }
}

function Get-ActiveUser($data) {
    Require-Ready $data
    if ($data.mode -eq 'Team') {
        $account = Get-GitHubAccount ''
        foreach ($user in @($data.users)) {
            if ($null -ne $user.github -and [string]$user.github.id -eq [string]$account.id) {
                return $user
            }
        }
        throw 'This GitHub account is not registered. Ask the team owner to add it.'
    }
    if ($data.mode -eq 'Solo') {
        $localIdentity = Get-LocalIdentity
        foreach ($user in @($data.users)) {
            if ($user.local_identity -eq $localIdentity) { return $user }
        }
        throw 'This operating-system account is not the configured solo user.'
    }
    throw 'Unknown MemoryCore mode.'
}

function Get-Agent($user, [string]$id) {
    if ([string]::IsNullOrWhiteSpace($id) -and $Action -ne 'Login' -and (Test-Path -LiteralPath $loginPath)) {
        $receipt = Read-Json $loginPath
        if ($receipt.user_id -eq $user.id) { $id = $receipt.agent_id }
    }
    if ([string]::IsNullOrWhiteSpace($id)) { $id = $user.primary_agent_id }
    Assert-Id $id 'AgentId'
    foreach ($agent in @($user.agents)) {
        if ($agent.id -eq $id) { return $agent }
    }
    throw "Agent $id does not belong to the authenticated user."
}

function Require-Login($user, $agent) {
    if (-not (Test-Path -LiteralPath $loginPath)) { throw 'Run Login before using MemoryCore.' }
    $receipt = Read-Json $loginPath
    if ($receipt.user_id -ne $user.id) { throw 'Login belongs to another user. Run Login again.' }
    if ($null -ne $agent -and $receipt.agent_id -ne $agent.id) {
        throw 'Login belongs to another agent. Run Login with this AgentId.'
    }
    if ([DateTimeOffset]::Parse($receipt.at) -lt [DateTimeOffset]::UtcNow.AddHours(-12)) {
        throw 'MemoryCore login expired. Run Login again.'
    }
}

function New-Note([string]$value) {
    return [pscustomobject]@{ at = [DateTimeOffset]::Now.ToString('o'); text = $value }
}

function Add-RecallHit($hits, [string]$source, [string]$value, [string[]]$terms) {
    if ([string]::IsNullOrWhiteSpace($value)) { return }
    foreach ($term in $terms) {
        if ($value.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            [void]$hits.Add([pscustomobject]@{ source = $source; text = $value })
            return
        }
    }
}

. (Join-Path $PSScriptRoot 'ProjectVault.ps1')
. (Join-Path $PSScriptRoot 'Skills.ps1')
. (Join-Path $PSScriptRoot 'Restore-Cache.ps1')

function New-ProjectLogEvent($user, $agent, [string]$kind, $payload, [string]$id = '') {
    if ([string]::IsNullOrWhiteSpace($id)) {
        $id = [DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-' + [guid]::NewGuid().ToString('N')
    }
    return [pscustomobject]@{
        id = $id
        at = [DateTimeOffset]::UtcNow.ToString('o')
        author_github_id = [string]$user.github.id
        author_user_id = $user.id
        author_name = $user.name
        agent_id = $agent.id
        provider = [string]$env:MCORE_PROVIDER
        kind = $kind
        data = $payload
    }
}

if ($Action -eq 'Status') {
    $state = Get-State
    [pscustomobject]@{
        state = $state.state; mode = $state.mode; users = @($state.users).Count; revision = $state.revision
        vault_initialized = (Test-Path -LiteralPath $vaultPath)
        vault_unlocked_here = (Test-Path -LiteralPath $keyCachePath)
    } | ConvertTo-Json
    return
}

$lockPath = Join-Path $coreRoot '.lock'
$lockStream = $null
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    try {
        $lockStream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        break
    } catch [System.IO.IOException] {
        Start-Sleep -Milliseconds 100
    }
}
if ($null -eq $lockStream) { throw 'MemoryCore is busy; try again in a moment.' }

try {
    $state = Get-State
    switch ($Action) {
        'Status' {
            [pscustomobject]@{
                state = $state.state
                mode = $state.mode
                users = @($state.users).Count
                revision = $state.revision
                vault_initialized = (Test-Path -LiteralPath $vaultPath)
                vault_unlocked_here = (Test-Path -LiteralPath $keyCachePath)
            } | ConvertTo-Json
        }
        'Setup' {
            if ($state.state -eq 'ready') { throw 'MemoryCore is already configured.' }
            if ([string]::IsNullOrWhiteSpace($Mode)) { throw 'Mode Solo or Team is required.' }
            Assert-Id $UserId 'UserId'
            Assert-Id $AgentId 'AgentId'
            Assert-Text $UserName 'UserName'
            Assert-Text $AgentName 'AgentName'
            $null = & (Join-Path $PSScriptRoot 'Setup-Tools.ps1')
            $account = $null
            $localIdentity = $null
            if ($Mode -eq 'Team') { $account = Get-GitHubAccount '' }
            else { $localIdentity = Get-LocalIdentity }
            $agent = New-AgentMetadata $AgentId $AgentName
            $user = New-UserMetadata $UserId $UserName $agent $account $localIdentity
            New-UserFiles $UserId $AgentId
            $state.state = 'ready'
            $state.mode = $Mode
            $state.team_name = $TeamName
            if ($Mode -eq 'Team') { $state.owner_github_id = [string]$account.id }
            $state.users = @($user)
            Save-State $state
            Write-Output "Setup complete: $Mode mode, user $UserId, primary agent $AgentId."
        }
        'AddUser' {
            Require-Ready $state
            if ($state.mode -ne 'Team') { throw 'AddUser is only available in team mode.' }
            $operator = Get-GitHubAccount ''
            if ([string]$operator.id -ne [string]$state.owner_github_id) {
                throw 'Only the team owner can add users.'
            }
            Assert-Id $UserId 'UserId'
            Assert-Id $AgentId 'AgentId'
            Assert-Text $UserName 'UserName'
            Assert-Text $AgentName 'AgentName'
            Assert-Text $GitHubLogin 'GitHubLogin'
            $account = Get-GitHubAccount $GitHubLogin
            foreach ($existing in @($state.users)) {
                if ($existing.id -eq $UserId) { throw "Duplicate UserId: $UserId" }
                if ([string]$existing.github.id -eq [string]$account.id) {
                    throw 'This GitHub account is already registered.'
                }
            }
            $agent = New-AgentMetadata $AgentId $AgentName
            $user = New-UserMetadata $UserId $UserName $agent $account $null
            $state.users = @($state.users) + @($user)
            Save-State $state
            Write-Output "Added $UserId for GitHub account $($account.login)."
        }
        'AddAgent' {
            $user = Get-ActiveUser $state
            Require-Login $user $null
            Assert-Id $AgentId 'AgentId'
            Assert-Text $AgentName 'AgentName'
            foreach ($existing in @($user.agents)) {
                if ($existing.id -eq $AgentId) { throw "Duplicate AgentId: $AgentId" }
            }
            New-AgentFiles $user.id $AgentId
            $user.agents = @($user.agents) + @(New-AgentMetadata $AgentId $AgentName)
            if ($Primary) { $user.primary_agent_id = $AgentId }
            Save-State $state
            Write-Output "Added agent $AgentId for $($user.id)."
        }
        'UnlockVault' {
            Require-Ready $state
            if ($state.mode -ne 'Team') { throw 'Project vault is only used in team mode.' }
            $operator = Get-ActiveUser $state
            if (-not (Test-Path -LiteralPath $vaultPath) -and [string]$operator.github.id -ne [string]$state.owner_github_id) {
                throw 'Only the team owner can initialize the project vault.'
            }
            Unlock-ProjectVault
        }
        'Login' {
            $user = Get-ActiveUser $state
            $projectEvents = @()
            $allProjectEvents = @()
            if ($state.mode -eq 'Team') {
                $allProjectEvents = @(Read-ProjectEvents)
            }
            Ensure-LocalUserFiles $user
            $agent = Get-Agent $user $AgentId
            if ($state.mode -eq 'Team') { Restore-McoreCache $user $agent $allProjectEvents }
            if ($state.mode -eq 'Team') {
                $ownEvents = @($allProjectEvents | Where-Object {
                    $_.author_user_id -eq $user.id -and $_.agent_id -eq $agent.id
                } | Select-Object -Last 20)
                $recentEvents = @($allProjectEvents | Select-Object -Last 30)
                $projectEvents = @(($ownEvents + $recentEvents) |
                    Group-Object id | ForEach-Object { $_.Group[0] } | Sort-Object at)
            }
            $userRoot = Get-UserRoot $user.id
            $agentRoot = Get-AgentRoot $user.id $agent.id
            $sessionData = Read-Json (Join-Path $agentRoot 'session.json')
            if ($state.mode -eq 'Team') {
                $latestSharedSession = @($allProjectEvents | Where-Object {
                    $_.kind -eq 'session' -and $_.author_user_id -eq $user.id -and $_.agent_id -eq $agent.id
                } | Sort-Object at | Select-Object -Last 1)
                if ($latestSharedSession.Count -gt 0 -and (
                    [string]::IsNullOrWhiteSpace($sessionData.updated_at) -or
                    [DateTimeOffset]::Parse($latestSharedSession[0].at) -gt [DateTimeOffset]::Parse($sessionData.updated_at)
                )) {
                    $sessionData = [pscustomobject]@{
                        summary = $latestSharedSession[0].data.text
                        updated_at = $latestSharedSession[0].at
                    }
                }
            }
            Write-Json $loginPath ([pscustomobject]@{
                user_id = $user.id
                agent_id = $agent.id
                at = [DateTimeOffset]::UtcNow.ToString('o')
            })
            [pscustomobject]@{
                mode = $state.mode
                user_id = $user.id
                user_name = $user.name
                agent_id = $agent.id
                agent_name = $agent.name
                profile = Read-Json (Join-Path $userRoot 'profile.json')
                identity = Read-Json (Join-Path $agentRoot 'identity.json')
                memory = Read-Json (Join-Path $agentRoot 'memory.json')
                session = $sessionData
                project_events = $projectEvents
                available_skills = @(Get-McoreSkills $user.id)
            } | ConvertTo-Json -Depth 30
        }
        'Skills' {
            $user = Get-ActiveUser $state
            $agent = Get-Agent $user $AgentId
            Require-Login $user $agent
            ConvertTo-Json -InputObject @(Get-McoreSkills $user.id) -Depth 10
        }
        'Route' {
            Assert-Text $Instruction 'Instruction'
            $user = Get-ActiveUser $state
            $agent = Get-Agent $user $AgentId
            Require-Login $user $agent
            Get-McoreRoute $Instruction @(Get-McoreSkills $user.id) | ConvertTo-Json -Depth 10
        }
        'RecordTurn' {
            Assert-Text $Instruction 'Instruction'
            Assert-Text $Outcome 'Outcome'
            $user = Get-ActiveUser $state
            $agent = Get-Agent $user $AgentId
            Require-Login $user $agent
            $agentRoot = Get-AgentRoot $user.id $agent.id
            $memoryPath = Join-Path $agentRoot 'memory.json'
            $diaryPath = Join-Path $agentRoot 'diary.json'
            $memory = Read-Json $memoryPath
            $diary = Read-Json $diaryPath
            if ([string]::IsNullOrWhiteSpace($EventId)) {
                $EventId = [DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-' + [guid]::NewGuid().ToString('N')
            }
            if ($EventId -notmatch '^[A-Za-z0-9-]{1,128}$') { throw 'EventId may contain only letters, digits, and hyphens (maximum 128 characters).' }
            $entry = [pscustomobject]@{
                id = $EventId
                at = [DateTimeOffset]::Now.ToString('o')
                status = $TurnStatus
                provider = [string]$env:MCORE_PROVIDER
                instruction = $Instruction
                outcome = $Outcome
            }
            $existing = @($diary.entries | Where-Object { $_.id -eq $EventId })
            if ($existing.Count -eq 0) { $existing = @($memory.activity | Where-Object { $_.id -eq $EventId }) }
            if ($existing.Count -gt 0) {
                if ($existing[0].instruction -cne $Instruction -or $existing[0].outcome -cne $Outcome -or $existing[0].status -ne $TurnStatus) {
                    throw 'EventId already exists with different content. Use a new EventId for a new outcome.'
                }
                $entry = $existing[0]
            }
            if ($state.mode -eq 'Team') {
                Write-ProjectEvent (New-ProjectLogEvent $user $agent 'turn' $entry $EventId)
            }
            if ($null -eq $memory.PSObject.Properties['activity']) {
                $memory | Add-Member -NotePropertyName activity -NotePropertyValue @()
            }
            if (-not @($memory.activity | Where-Object { $_.id -eq $EventId }).Count -and ($existing.Count -eq 0 -or -not @($diary.entries | Where-Object { $_.id -eq $EventId }).Count)) {
                $memory.activity = @($memory.activity) + @($entry)
                $memory.activity = @($memory.activity | Select-Object -Last 100)
                Write-Json $memoryPath $memory
            }
            if (-not @($diary.entries | Where-Object { $_.id -eq $EventId }).Count) {
                $diary.entries = @($diary.entries) + @($entry)
                Write-Json $diaryPath $diary
            }
            Write-Output "Recorded turn $EventId in memory and diary for $($user.id)/$($agent.id)."
        }
        'SaveMemory' {
            Assert-Text $Text 'Text'
            $user = Get-ActiveUser $state
            $agent = Get-Agent $user $AgentId
            Require-Login $user $agent
            if ($Target -eq 'User') {
                if ($Category -notin @('Facts', 'Preferences', 'Goals')) {
                    throw 'User memory allows Facts, Preferences, or Goals.'
                }
                $path = Join-Path (Get-UserRoot $user.id) 'profile.json'
            } else {
                if ($Category -notin @('Facts', 'Preferences', 'Decisions', 'Questions')) {
                    throw 'Agent memory allows Facts, Preferences, Decisions, or Questions.'
                }
                $path = Join-Path (Get-AgentRoot $user.id $agent.id) 'memory.json'
            }
            $data = Read-Json $path
            $key = $Category.ToLowerInvariant()
            if ($state.mode -eq 'Team') {
                Write-ProjectEvent (New-ProjectLogEvent $user $agent 'memory' ([pscustomobject]@{ target = $Target; category = $Category; text = $Text }))
            }
            $data.$key = @($data.$key) + @(New-Note $Text)
            Write-Json $path $data
            Write-Output "Saved $Category for $($user.id)/$($agent.id)."
        }
        'SaveDiary' {
            Assert-Text $Text 'Text'
            $user = Get-ActiveUser $state
            $agent = Get-Agent $user $AgentId
            Require-Login $user $agent
            $path = Join-Path (Get-AgentRoot $user.id $agent.id) 'diary.json'
            $data = Read-Json $path
            if ($state.mode -eq 'Team') {
                Write-ProjectEvent (New-ProjectLogEvent $user $agent 'diary' ([pscustomobject]@{ text = $Text }))
            }
            $data.entries = @($data.entries) + @(New-Note $Text)
            Write-Json $path $data
            Write-Output "Saved diary for $($user.id)/$($agent.id)."
        }
        'SaveTopic' {
            Assert-Id $TopicId 'TopicId'
            Assert-Text $Text 'Text'
            $user = Get-ActiveUser $state
            $agent = Get-Agent $user $AgentId
            Require-Login $user $agent
            $path = Join-Path (Get-AgentRoot $user.id $agent.id) 'topics.json'
            $data = Read-Json $path
            $topic = $null
            foreach ($entry in @($data.topics)) {
                if ($entry.id -eq $TopicId) { $topic = $entry; break }
            }
            if ($null -eq $topic) {
                $topic = [pscustomobject]@{ id = $TopicId; entries = @() }
                $data.topics = @($data.topics) + @($topic)
            }
            if ($state.mode -eq 'Team') {
                Write-ProjectEvent (New-ProjectLogEvent $user $agent 'topic' ([pscustomobject]@{ topic_id = $TopicId; text = $Text }))
            }
            $topic.entries = @($topic.entries) + @(New-Note $Text)
            Write-Json $path $data
            Write-Output "Saved topic $TopicId for $($user.id)/$($agent.id)."
        }
        'Recall' {
            Assert-Text $Query 'Query'
            $user = Get-ActiveUser $state
            $agent = Get-Agent $user $AgentId
            Require-Login $user $agent
            $userRoot = Get-UserRoot $user.id
            $agentRoot = Get-AgentRoot $user.id $agent.id
            $profile = Read-Json (Join-Path $userRoot 'profile.json')
            $memory = Read-Json (Join-Path $agentRoot 'memory.json')
            $diary = Read-Json (Join-Path $agentRoot 'diary.json')
            $topics = Read-Json (Join-Path $agentRoot 'topics.json')
            $terms = @([regex]::Matches($Query.ToLowerInvariant(), '[\p{L}\p{N}]{2,}') | ForEach-Object { $_.Value } | Select-Object -Unique)
            if ($terms.Count -eq 0) { $terms = @($Query) }
            $hits = New-Object System.Collections.ArrayList
            $session = Read-Json (Join-Path $agentRoot 'session.json')
            Add-RecallHit $hits 'agent.session' $session.summary $terms
            foreach ($key in @('facts', 'preferences', 'goals')) {
                foreach ($entry in @($profile.$key)) {
                    Add-RecallHit $hits "profile.$key" $entry.text $terms
                }
            }
            Add-RecallHit $hits 'agent.memory.summary' $memory.summary $terms
            foreach ($key in @('facts', 'preferences', 'decisions', 'questions')) {
                foreach ($entry in @($memory.$key)) {
                    Add-RecallHit $hits "agent.memory.$key" $entry.text $terms
                }
            }
            foreach ($entry in @($diary.entries | Sort-Object at -Descending)) {
                Add-RecallHit $hits "agent.diary/$($entry.at)" $entry.text $terms
                Add-RecallHit $hits "agent.diary.instruction/$($entry.at)" $entry.instruction $terms
                Add-RecallHit $hits "agent.diary.outcome/$($entry.at)" $entry.outcome $terms
            }
            foreach ($topic in @($topics.topics)) {
                foreach ($entry in @($topic.entries)) {
                    Add-RecallHit $hits "agent.topics/$($topic.id)/$($entry.at)" $entry.text $terms
                }
            }
            if ($state.mode -eq 'Team') {
                foreach ($event in @(Read-ProjectEvents | Sort-Object at -Descending)) {
                    Add-RecallHit $hits "project.$($event.kind)/$($event.author_user_id)/$($event.at)" $event.data.text $terms
                    Add-RecallHit $hits "project.turn.instruction/$($event.author_user_id)/$($event.at)" $event.data.instruction $terms
                    Add-RecallHit $hits "project.turn.outcome/$($event.author_user_id)/$($event.at)" $event.data.outcome $terms
                }
            }
            [pscustomobject]@{
                user_id = $user.id
                agent_id = $agent.id
                query = $Query
                matches = @($hits | Select-Object -First 20)
            } | ConvertTo-Json -Depth 30
        }
        'UpdateSession' {
            Assert-Text $Text 'Text'
            $user = Get-ActiveUser $state
            $agent = Get-Agent $user $AgentId
            Require-Login $user $agent
            $path = Join-Path (Get-AgentRoot $user.id $agent.id) 'session.json'
            $data = Read-Json $path
            if ($state.mode -eq 'Team') {
                Write-ProjectEvent (New-ProjectLogEvent $user $agent 'session' ([pscustomobject]@{ text = $Text }))
            }
            $data.summary = $Text
            $data.updated_at = [DateTimeOffset]::Now.ToString('o')
            Write-Json $path $data
            Write-Output "Updated session for $($user.id)/$($agent.id)."
        }
        'Compact' {
            Assert-Text $Summary 'Summary'
            $user = Get-ActiveUser $state
            $agent = Get-Agent $user $AgentId
            Require-Login $user $agent
            $agentRoot = Get-AgentRoot $user.id $agent.id
            $memoryPath = Join-Path $agentRoot 'memory.json'
            $compactionPath = Join-Path $agentRoot 'compaction.json'
            $memory = Read-Json $memoryPath
            $compaction = Read-Json $compactionPath
            if ($state.mode -eq 'Team') {
                Write-ProjectEvent (New-ProjectLogEvent $user $agent 'compaction' ([pscustomobject]@{ text = $Summary }))
            }
            $compaction.snapshot = $memory
            $compaction.last_compacted_at = [DateTimeOffset]::Now.ToString('o')
            Write-Json $compactionPath $compaction
            $memory.summary = $Summary
            if ($null -ne $memory.PSObject.Properties['activity']) { $memory.activity = @($memory.activity | Select-Object -Last 20) }
            foreach ($key in @('facts', 'preferences', 'decisions', 'questions')) { $memory.$key = @() }
            Write-Json $memoryPath $memory
            Write-Output "Compacted active memory for $($user.id)/$($agent.id). One prior snapshot remains in compaction.json."
        }
        'Validate' {
            Require-Ready $state
            if ($state.mode -notin @('Solo', 'Team')) { throw 'Invalid mode.' }
            $seenUsers = @{}
            $seenGithub = @{}
            $activeGithubId = $null
            if ($state.mode -eq 'Team') { $activeGithubId = [string](Get-GitHubAccount '').id }
            foreach ($user in @($state.users)) {
                Assert-Id $user.id 'UserId'
                if ($seenUsers.ContainsKey($user.id)) { throw "Duplicate UserId: $($user.id)" }
                $seenUsers[$user.id] = $true
                if ($state.mode -eq 'Team') {
                    if ($null -eq $user.github) { throw "Missing GitHub account for $($user.id)" }
                    if ($seenGithub.ContainsKey([string]$user.github.id)) { throw 'Duplicate GitHub account ID.' }
                    $seenGithub[[string]$user.github.id] = $true
                }
                $checkCache = $state.mode -eq 'Solo' -or [string]$user.github.id -eq $activeGithubId
                $userRoot = Get-UserRoot $user.id
                if ($checkCache) { [void](Read-Json (Join-Path $userRoot 'profile.json')) }
                $seenAgents = @{}
                foreach ($agent in @($user.agents)) {
                    Assert-Id $agent.id 'AgentId'
                    if ($seenAgents.ContainsKey($agent.id)) { throw "Duplicate AgentId for $($user.id)" }
                    $seenAgents[$agent.id] = $true
                    if (-not $checkCache) { continue }
                    $agentRoot = Get-AgentRoot $user.id $agent.id
                    foreach ($file in @('identity.json', 'memory.json', 'session.json', 'diary.json', 'topics.json', 'compaction.json')) {
                        [void](Read-Json (Join-Path $agentRoot $file))
                    }
                    $memoryData = Read-Json (Join-Path $agentRoot 'memory.json')
                    $diaryData = Read-Json (Join-Path $agentRoot 'diary.json')
                    $memoryIds = @($memoryData.activity | Where-Object { $_.id } | ForEach-Object { $_.id })
                    $diaryIds = @($diaryData.entries | Where-Object { $_.id } | ForEach-Object { $_.id })
                    if (@($memoryIds | Where-Object { $_ -notin $diaryIds }).Count -gt 0) {
                        throw "Turn memory and diary differ for $($user.id)/$($agent.id). Retry RecordTurn with the same EventId."
                    }
                }
                if (-not $seenAgents.ContainsKey($user.primary_agent_id)) {
                    throw "Invalid primary agent for $($user.id)"
                }
            }
            if ($state.mode -eq 'Solo' -and @($state.users).Count -ne 1) { throw 'Solo mode must have one user.' }
            Write-Output "Valid MemoryCore: $($state.mode), $($seenUsers.Count) user(s)."
        }
    }
} finally {
    $lockStream.Dispose()
}
