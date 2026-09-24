# Rebuild the authenticated member's derived cache from the shared event log.
function Restore-McoreCache($user, $agent, $events) {
    $profile = [pscustomobject]@{ facts = @(); preferences = @(); goals = @() }
    $memory = [pscustomobject]@{ summary = ''; facts = @(); preferences = @(); decisions = @(); questions = @(); activity = @() }
    $diary = [pscustomobject]@{ entries = @() }
    $topics = [pscustomobject]@{ topics = @() }
    $session = [pscustomobject]@{ summary = ''; updated_at = $null }
    $compaction = [pscustomobject]@{ policy = 'Preserve meaning and uncertainty.'; snapshot = $null; last_compacted_at = $null }
    foreach ($event in @($events | Sort-Object @{Expression = { [DateTimeOffset]$_.at }}, id)) {
        if ($event.author_user_id -ne $user.id) { continue }
        $note = [pscustomobject]@{ at = $event.at; text = $event.data.text }
        if ($event.kind -eq 'memory' -and $event.data.target -eq 'User') {
            $key = ([string]$event.data.category).ToLowerInvariant()
            if ($key -notin @('facts','preferences','goals')) { throw 'Invalid user memory category in project log.' }
            $profile.$key = @($profile.$key) + @($note)
        }
        if ($event.agent_id -ne $agent.id) { continue }
        switch ($event.kind) {
            'turn' {
                $memory.activity = @($memory.activity) + @($event.data)
                $diary.entries = @($diary.entries) + @($event.data)
            }
            'diary' { $diary.entries = @($diary.entries) + @($note) }
            'memory' {
                if ($event.data.target -eq 'Agent') {
                    $key = ([string]$event.data.category).ToLowerInvariant()
                    if ($key -notin @('facts','preferences','decisions','questions')) { throw 'Invalid agent memory category in project log.' }
                    $memory.$key = @($memory.$key) + @($note)
                }
            }
            'session' { $session.summary = $event.data.text; $session.updated_at = $event.at }
            'topic' {
                $topic = @($topics.topics | Where-Object { $_.id -eq $event.data.topic_id })
                if ($topic.Count -eq 0) {
                    $topics.topics += [pscustomobject]@{ id = $event.data.topic_id; entries = @($note) }
                } else { $topic[0].entries = @($topic[0].entries) + @($note) }
            }
            'compaction' {
                $compaction.snapshot = $memory | ConvertTo-Json -Depth 30 | ConvertFrom-Json
                $compaction.last_compacted_at = $event.at
                $memory.summary = $event.data.text
                foreach ($key in @('facts','preferences','decisions','questions')) { $memory.$key = @() }
                $memory.activity = @($memory.activity | Select-Object -Last 20)
            }
        }
    }
    $memory.activity = @($memory.activity | Select-Object -Last 100)
    $root = Get-AgentRoot $user.id $agent.id
    Write-Json (Join-Path (Get-UserRoot $user.id) 'profile.json') $profile
    foreach ($item in @(
        @{ name = 'memory'; value = $memory }, @{ name = 'diary'; value = $diary },
        @{ name = 'topics'; value = $topics }, @{ name = 'session'; value = $session },
        @{ name = 'compaction'; value = $compaction }
    )) { Write-Json (Join-Path $root ($item.name + '.json')) $item.value }
}
