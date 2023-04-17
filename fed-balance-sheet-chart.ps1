
function head () { $input | Select-Object -First 10 }
function tail () { $input | Select-Object -Last  10 }

# https://fred.stlouisfed.org/graph/fredgraph.csv?bgcolor=%23e1e9f0&chart_type=line&drp=0&fo=open%20sans&graph_bgcolor=%23ffffff&height=450&mode=fred&recession_bars=on&txtcolor=%23444444&ts=12&tts=12&width=1138&nt=0&thu=0&trc=0&show_legend=yes&show_axis_titles=yes&show_tooltip=yes&id=WLCFLL,WLODLL&scale=left,left&cosd=2002-12-18,2002-12-18&coed=2023-04-12,2023-04-12&line_color=%234572a7,%23aa4643&link_values=false,false&line_style=solid,solid&mark_type=none,none&mw=3,3&lw=2,2&ost=-99999,-99999&oet=99999,99999&mma=0,0&fml=a,a&fq=Weekly%2C%20As%20of%20Wednesday,Weekly%2C%20As%20of%20Wednesday&fam=avg,avg&fgst=lin,lin&fgsnd=2020-02-01,2020-02-01&line_index=1,2&transformation=lin,lin&vintage_date=2023-04-15,2023-04-15&revision_date=2023-04-15,2023-04-15&nd=2002-12-18,2002-12-18

$result = Invoke-RestMethod 'https://fred.stlouisfed.org/graph/fredgraph.csv?bgcolor=%23e1e9f0&chart_type=line&drp=0&fo=open%20sans&graph_bgcolor=%23ffffff&height=450&mode=fred&recession_bars=on&txtcolor=%23444444&ts=12&tts=12&width=1138&nt=0&thu=0&trc=0&show_legend=yes&show_axis_titles=yes&show_tooltip=yes&id=WLCFLL,WLODLL&scale=left,left&cosd=2002-12-18,2002-12-18&coed=2023-04-12,2023-04-12&line_color=%234572a7,%23aa4643&link_values=false,false&line_style=solid,solid&mark_type=none,none&mw=3,3&lw=2,2&ost=-99999,-99999&oet=99999,99999&mma=0,0&fml=a,a&fq=Weekly%2C%20As%20of%20Wednesday,Weekly%2C%20As%20of%20Wednesday&fam=avg,avg&fgst=lin,lin&fgsnd=2020-02-01,2020-02-01&line_index=1,2&transformation=lin,lin&vintage_date=2023-04-15,2023-04-15&revision_date=2023-04-15,2023-04-15&nd=2002-12-18,2002-12-18'

$data = $result | ConvertFrom-Csv

$data | Select-Object -Last 10

$data | Select-Object -First 10

# ----------------------------------------------------------------------

$result = Invoke-RestMethod 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=WSHOMCB,WLCFLL,H41RESPPAAENWW,WAOAL,WLFN,WLRRAL,WLODLL,WDTGAL,WCPIL,WCSL,WSHOBL,WSHONBNL&cosd=2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18'


# $result = Invoke-RestMethod 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=WALCL'


$result = Invoke-RestMethod 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=WSHOMCB,WLCFLL,H41RESPPAAENWW,WAOAL,WLFN,WLRRAL,WLODLL,WDTGAL,WCPIL,WCSL,WSHOBL,WSHONBNL&cosd=2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18,2002-12-18' -OutFile c:\temp\fred.zip

Expand-Archive -Path C:\temp\fred.zip -DestinationPath c:\temp\fred

ls c:\temp\fred

$result_weekly = Import-Csv C:\temp\fred\Weekly.csv

$result_wed = Import-Csv C:\temp\Weekly_As_of_Wednesday.csv

# ----------------------------------------------------------------------

function get-fred-data ($ids, $date)
{
    $result = Invoke-RestMethod ('https://fred.stlouisfed.org/graph/fredgraph.csv?id={0}&cosd={1}' -f ($ids -join ','), (@($date) * $ids.Count -join ','))

    $result | ConvertFrom-Csv
}

# ----------------------------------------------------------------------

# $assets = 'WSHOBL WSHONBNL WSHONBIIL WSHOICL' -split ' '

# $liabilities = 'WLFN WLRRAL WDTGAL' -split ' '

# $data = get-fred-data ($assets + $liabilities) '2020-01-01'

# $data = get-fred-data ($assets + $liabilities) '2000-01-01'
# ----------------------------------------------------------------------
# $descriptions = @{
#     WSHOBL    = 'Bills'
#     WSHONBNL  = 'Notes and bonds, nominal'
#     WSHONBIIL = 'Notes and bonds, inflation-indexed'
#     WSHOICL   = 'Inflation compensation'

#     WSHOMCB   = 'Mortgage-backed securities'

#     WLCFLL = 'Loans'

#     WLFN   = 'Federal Reserve Notes, net of F.R. Bank holdings'
#     WLRRAL = 'Reverse repurchase agreements'
#     WDTGAL = 'U.S. Treasury, General Account'
# }
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
    WLCFLL    = 'Loans'  
    
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

$descriptions = $asset_descriptions + $liability_descriptions

$assets      = $asset_descriptions.Keys
$liabilities = $liability_descriptions.Keys

$ids = $assets + $liabilities

$batch_1 = $ids | Select-Object -Skip  0 | Select-Object -First 12
$batch_2 = $ids | Select-Object -Skip 12 | Select-Object -First 12

$data_1 = get-fred-data $batch_1 '2000-01-01'
$data_2 = get-fred-data $batch_2 '2000-01-01'


# $row = $data_1[0]

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


# $other.psobject.Properties | ForEach-Object -Begin { $tbl = @{} } -Process { $tbl."$($_.Name)" = $_.Value } -End { $tbl }

# $tbl = @{}

# $other.psobject.Properties | ForEach-Object { $tbl.($_.Name) = $_.Value }

# $other.psobject.Properties | ForEach-Object { $tbl.($_.Name) = $_.Value }

# $other.psobject.Properties | ForEach-Object { $tbl[$_.Name] = $_.Value }

# $data = get-fred-data ($assets + $liabilities) '2000-01-01'
# $data = get-fred-data ($assets + $liabilities) '2020-01-01'

# ----------------------------------------------------------------------

# $items = $data

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

$i = 0

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


# function abc ()
# {
#     # $i = $i + 1

#     $global:i++
# }

$datasets_assets      = create-datasets $assets       1
$datasets_liabilities = create-datasets $liabilities -1


# $i = 0

foreach ($name in $assets)
{
    $colors[$i++ % $colors.Count]
}

foreach ($name in $liabilities)
{
    $colors[$i++ % $colors.Count]
}

# assets      23
# liabilities 10
# capital      3

$json = @{
    chart = @{
        type = 'bar'
        # type = 'line'
        data = @{            
            labels = $items.ForEach({ $_.DATE })
            datasets = $datasets_assets + $datasets_liabilities
        }
        options = @{
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

Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)
