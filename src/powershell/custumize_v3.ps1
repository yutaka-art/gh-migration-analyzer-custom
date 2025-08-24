# ==== customize_v3.ps1 ====
param(
  [Parameter(Mandatory = $true)][string]$Org = "octocat"
)

if (-not $env:GH_PAT) { throw "環境変数 GH_PAT が未設定です。" }

$Headers = @{
  Authorization = "bearer $env:GH_PAT"
  "User-Agent"  = "gh-migration-script"
}

# --- GraphQL: Repositories (Projects/Packagesは除外。Discussions/Releasesは取得) ---
$RepoQuery = @'
query($org:String!, $cursor:String){
  organization(login:$org){
    repositories(first:100, after:$cursor, orderBy:{field:NAME, direction:ASC}){
      totalCount
      pageInfo { hasNextPage endCursor }
      nodes{
        name
        pushedAt
        isArchived
        hasWikiEnabled
        diskUsage
        issues { totalCount }
        pullRequests { totalCount }
        discussions { totalCount }
        releases   { totalCount }
      }
    }
  }
}
'@

# --- GraphQL: Org (Members と ProjectsV2 件数) ---
$OrgQuery = @'
query($org:String!){
  organization(login:$org){
    membersWithRole(first:1){ totalCount }
    projectsV2(first:1){ totalCount }
  }
}
'@

function Invoke-GHGQL($Query, $Vars) {
  $Body = @{ query = $Query; variables = $Vars } | ConvertTo-Json -Depth 6
  $Resp = Invoke-RestMethod "https://api.github.com/graphql" -Method POST -Headers $Headers -ContentType "application/json" -Body $Body
  if ($Resp.errors) {
    $Resp.errors | ConvertTo-Json -Depth 10 | Write-Host
    throw "GraphQL エラー"
  }
  return $Resp
}

# --- 取得（全Repo分ページング） ---
$AllRepos   = @()
$cursor     = $null
$grandTotal = $null

do {
  $r = Invoke-GHGQL $RepoQuery @{ org = $Org; cursor = $cursor }
  if (-not $grandTotal) { $grandTotal = $r.data.organization.repositories.totalCount }
  $AllRepos += $r.data.organization.repositories.nodes
  $page   = $r.data.organization.repositories.pageInfo
  $cursor = $page.endCursor
} while ($page.hasNextPage)

# --- 集計（gitHub.jsの列と順序に完全一致） ---
$metrics      = @()
$mostPrCount  = -1; $mostPrRepo  = ""
$mostIsCount  = -1; $mostIsRepo  = ""

foreach ($repo in $AllRepos) {
  $metrics += [pscustomobject]@{
    'Repository Name'          = $repo.name
    'Last Push Date'           = $repo.pushedAt
    'Is Archived?'             = $repo.isArchived
    'Number Of Pull Requests'  = $repo.pullRequests.totalCount
    'Number of Issues'         = $repo.issues.totalCount
    'Number of Projects'       = 0                               # Classic廃止のため0固定
    'Number of Discussions'    = $repo.discussions.totalCount
    'Number of Packages'       = 0                               # Repo別は安定取得不可のため0固定
    'Number of Releases'       = $repo.releases.totalCount
    'Wiki Enabled'             = $repo.hasWikiEnabled
    'Size (KiB)'               = $repo.diskUsage
  }

  if ($repo.pullRequests.totalCount -gt $mostPrCount) {
    $mostPrCount = $repo.pullRequests.totalCount
    $mostPrRepo  = $repo.name
  }
  if ($repo.issues.totalCount -gt $mostIsCount) {
    $mostIsCount = $repo.issues.totalCount
    $mostIsRepo  = $repo.name
  }
}

$sumPR  = ($AllRepos | Measure-Object -Property { $_.pullRequests.totalCount } -Sum).Sum
$sumIss = ($AllRepos | Measure-Object -Property { $_.issues.totalCount } -Sum).Sum
$avgPR  = if ($AllRepos.Count) { [math]::Round($sumPR  / $AllRepos.Count) } else { 0 }
$avgIss = if ($AllRepos.Count) { [math]::Round($sumIss / $AllRepos.Count) } else { 0 }

# --- Org情報（Members と ProjectsV2 件数） ---
$orgInfo     = Invoke-GHGQL $OrgQuery @{ org = $Org }
$numMembers  = $orgInfo.data.organization.membersWithRole.totalCount
$numProjects = $orgInfo.data.organization.projectsV2.totalCount

# --- 出力 ---
$dir = Join-Path $PWD "$Org-metrics"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

$repoCsv = Join-Path $dir "repo-metrics.csv"
$orgCsv  = Join-Path $dir "org-metrics.csv"

$metrics | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $repoCsv

# gitHub.js の org-metrics と同じ列・表現（Mostは "RepoName (Count)"）
$orgRecord = [pscustomobject]@{
  'Number of Members'       = $numMembers
  'Number of Projects'      = $numProjects
  'Number of Repositories'  = $AllRepos.Count
  'Repo with Most Pull Requests' = "$mostPrRepo ($mostPrCount)"
  'Average Pull Requests'   = $avgPR
  'Repo with Most Issues'   = "$mostIsRepo ($mostIsCount)"
  'Average Issues'          = $avgIss
}
$orgRecord | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $orgCsv

Write-Host "Exported:`n  $repoCsv`n  $orgCsv"
