
# Replace Loans line item with components

Param($date = '2020-01-01', [switch]$display_chart_url, [switch]$save_iframe)

# ----------------------------------------------------------------------
function head () { $input | Select-Object -First 10 }
function tail () { $input | Select-Object -Last  10 }
# ----------------------------------------------------------------------
function get-fred-data ($ids, $date)
{
    $result = Invoke-RestMethod ('https://fred.stlouisfed.org/graph/fredgraph.csv?id={0}&cosd={1}' -f ($ids -join ','), (@($date) * $ids.Count -join ','))

    $result | ConvertFrom-Csv
}

function get-fred-data-chg ($ids, $date)
{
    $result = Invoke-RestMethod (
        'https://fred.stlouisfed.org/graph/fredgraph.csv?id={0}&cosd={1}&transformation={2}' -f 
            ($ids -join ','), 
            (@($date) * $ids.Count -join ','),
            (@('chg') * $ids.Count -join ',')
    )

    $result | ConvertFrom-Csv
}

# ----------------------------------------------------------------------
$asset_descriptions = [ordered] @{
  # WGCAL     = 'Gold Certificate Account'
  # WOSDRL    = 'Special Drawing Rights Certificate Account'
  # WACL      = 'Coin'

    WSHOBL    = 'Bills'
    WSHONBNL  = 'Notes and bonds, nominal'
    WSHONBIIL = 'Notes and bonds, inflation-indexed'
    WSHOICL   = 'Inflation compensation'
    WSHOFADSL = 'Federal Agency Debt Securities'

    WSHOMCB   = 'Mortgage-backed securities'
    WUPSHO    = 'Unamortized Premiums on Securities Held Outright'
    WUDSHO    = 'Unamortized Discounts on Securities Held Outright' # Negative value
    WORAL     = 'Repurchase Agreements'
    
    # WLCFLL    = 'Loans'  
    # Loans line items
    WLCFLPCL = 'Primary Credit'
    #H41RESPPALDKNWW = 'Bank Term Funding Program'
    WLCFOCEL = 'Other Credit Extensions'
    
    SWPT      = 'Central Bank Liquidity Swaps'
    WFCDA     = 'Foreign Currency Denominated Assets'
    WAOAL     = 'Other Assets'
}

$liability_descriptions = [ordered] @{

    WLFN   = 'Federal Reserve Notes, net of F.R. Bank holdings'
    WLRRAL = 'Reverse repurchase agreements'

    # Deposits
    
    TERMT  = 'Term deposits held by depository institutions'
    WLODLL = 'Other Deposits Held by Depository Institutions'
    WDTGAL = 'U.S. Treasury, General Account'
    WDFOL  = 'Foreign Official'
    WLODL  = 'Other'
    H41RESH4ENWW = 'Treasury Contribution to Credit Facilities'

    # Capital
}

$weekly_descriptions = @{
    H41RESPPALDKNWW = 'Bank Term Funding Program'
}

$descriptions = $asset_descriptions + $liability_descriptions + $weekly_descriptions

$assets      = $asset_descriptions.Keys
$liabilities = $liability_descriptions.Keys
$weekly      = $weekly_descriptions.Keys

$ids = $assets + $liabilities

# FRED appears to only allow up to 12 ids to be requested via the CSV URL approach

$batch_1 = $ids | Select-Object -Skip  0 | Select-Object -First 12
$batch_2 = $ids | Select-Object -Skip 12 | Select-Object -First 12

# $batch_3 = $weekly | Select-Object -Skip 0 | Select-Object -First 12

# $date = '2000-01-01'
# $date = '2020-01-01'

# $data_1 = get-fred-data $batch_1 '2000-01-01'
# $data_2 = get-fred-data $batch_2 '2000-01-01'

$data_1 = get-fred-data $batch_1 $date
$data_2 = get-fred-data $batch_2 $date

$data_weekly = get-fred-data $weekly $date

# $data_1 = get-fred-data-chg $batch_1 $date
# $data_2 = get-fred-data-chg $batch_2 $date


Write-Host 'Adding columns to table...' -ForegroundColor Yellow -NoNewline

foreach ($row in $data_1)
{
    $other = $data_2 | Where-Object DATE -EQ $row.DATE

    $tbl = [ordered]@{}
    
    foreach ($prop in $other.psobject.Properties)
    {
        $tbl[$prop.Name] = $prop.Value
    }

    $tbl.Remove('DATE')

    $row | Add-Member -NotePropertyMembers $tbl
}

foreach ($row in $data_1)
{
    $other = $data_weekly | Where-Object DATE -EQ $row.DATE

    $tbl = [ordered]@{}
    
    foreach ($prop in $other.psobject.Properties)
    {
        $tbl[$prop.Name] = $prop.Value
    }

    $tbl.Remove('DATE')

    $row | Add-Member -NotePropertyMembers $tbl
}

Write-Host 'done' -ForegroundColor Yellow
# ----------------------------------------------------------------------

$items = $data_1

$colors = @(
    "#4E79A7"
    "#F28E2B"
    "#E15759"
    "#76B7B2"
    "#59A14F"
    "#EDC948"
    "#B07AA1"
    "#FF9DA7"
    "#9C755F"
    "#BAB0AC"
  # "#FFFFFF"
  # "#000000"

    # "#c47c5e"
    # "#522426"

    # '#00429d'
    # '#3761ab'
    # '#5681b9'
    # '#73a2c6'
    # '#93c4d2'
    # '#b9e5dd'
    # '#ffffe0'
    # '#ffd3bf'
    # '#ffa59e'
    # '#f4777f'
    # '#dd4c65'
    # '#be214d'
    # '#93003a'

)

# $i = 0

$Global:i = 0

function create-datasets ($names, [int]$sign)
{
    foreach ($name in $names)
    {
        @{ 
            label = '{0} : {1}' -f $name, $descriptions.$name
            
            data = $items.ForEach({ $sign * $_.$name }) 

            backgroundColor = $colors[$Global:i++ % $colors.Count]
        }
    }
}

$datasets_assets      = create-datasets $assets       1
$datasets_liabilities = create-datasets $liabilities -1
$datasets_weekly      = create-datasets $weekly       1

# assets      23
# liabilities 10
# capital      3
# ----------------------------------------------------------------------
$json = @{
    chart = @{
        type = 'bar'
        # type = 'line'
        data = @{            
            labels = $items.ForEach({ $_.DATE })
            datasets = $datasets_assets + $datasets_liabilities + $datasets_weekly
        }
        options = @{
            title = @{ display = $true; text = 'Federal Reserve Balance Sheet (millions USD)' }
            legend = @{ position = 'left' }
            scales = @{ 
                xAxes = @(@{ stacked = $true })
                yAxes = @(@{ stacked = $true })
            }
        }
    }
} | ConvertTo-Json -Depth 100

$result = Invoke-RestMethod -Method Post -Uri 'https://quickchart.io/chart/create' -Body $json -ContentType 'application/json'

# Start-Process $result.url

$id = ([System.Uri] $result.url).Segments[-1]

if ($display_chart_url)
{
    Write-Host

    Write-Host ('https://quickchart.io/chart-maker/view/{0}' -f $id) -ForegroundColor Yellow
}
else
{
    Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)
}
# ----------------------------------------------------------------------
$html_template = @"
<!DOCTYPE html>
<html>
    <head>
        <title>{0}</title>
    </head>
    <body>
        <div style="padding-bottom: 56.25%; position: relative; display:block; width: 100%;">
            <iframe width="100%" height="100%" src="https://quickchart.io/chart-maker/view/{1}" frameborder="0" style="position: absolute; top:0; left: 0"></iframe>
        </div>
    </body>
</html>
"@

if ($save_iframe)
{
    $html_template -f 'Federal Reserve Balance Sheet (millions USD)', $id > fed-balance-sheet-chart-detail.html
}
# ----------------------------------------------------------------------
exit
# ----------------------------------------------------------------------
. .\fed-balance-sheet-chart-detail.ps1 -date '2020-01-01'
. .\fed-balance-sheet-chart-detail.ps1 -date '2023-01-01'
. .\fed-balance-sheet-chart-detail.ps1 -date '2023-03-01'