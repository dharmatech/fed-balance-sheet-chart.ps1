
# Replace Loans line item with components

Param($date = '2020-01-01')

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

    TMBACBW027NBOG = 'TSY and Agency : MBS'
    TNMACBW027NBOG = 'TSY and Agency : Non-MBS'
    OMBACBW027NBOG = 'Other : MBS'
    ONMACBW027NBOG = 'Other : Non-MBS'

    TOTCINSA = 'Commercial and industrial loans'

    RHEACBW027NBOG = 'Revolving home equity loans'
    CRLACBW027NBOG = 'Closed-end residential loans'

    # CLDACBW027NBOG = 'Construction and land development loans'        # weekly
    # SBFACBW027NBOG = 'Secured by farmland'                            # weekly
    # SMPACBW027NBOG = 'Secured by multifamily properties'              # weekly
    # SNFACBW027NBOG = 'Secured by nonfarm nonresidential properties'   # weekly

    CCLACBW027NBOG = 'Credit cards and other revolving plans'

    # possibly incorrect links:
    # AOCACBW027NBOG = 'Automobile loans'                               # weekly
    # CARACBW027NBOG = 'All other consumer loans'

    # AOCACBW027NBOG = 'All Other Consumer Loans'                       # weekly                 
    # CARACBW027NBOG = 'Automobile Loans'                               # weekly

    # LNFACBW027NBOG = 'Loans to nondepository financial institutions'  # weekly
    # OLNACBW027NBOG = 'All loans not elsewhere classified'             # weekly
    ALLACBW027NBOG = 'LESS: Allowance for loan and lease losses'
    CASACBW027NBOG = 'Cash Assets'
    # H8B3092NCBD    = 'Total federal funds sold and reverse RPs'       # weekly
    LCBACBW027NBOG = 'Loans to commercial banks'
    # H8B3053NCBD    = 'Other assets including trading assets'          # weekly
}

$asset_weekly_descriptions = [ordered] @{
    
    CLDACBW027NBOG = 'Construction and land development loans'        # weekly
    SBFACBW027NBOG = 'Secured by farmland'                            # weekly
    SMPACBW027NBOG = 'Secured by multifamily properties'              # weekly
    SNFACBW027NBOG = 'Secured by nonfarm nonresidential properties'   # weekly

    AOCACBW027NBOG = 'All Other Consumer Loans'                       # weekly                 
    CARACBW027NBOG = 'Automobile Loans'                               # weekly

    LNFACBW027NBOG = 'Loans to nondepository financial institutions'  # weekly
    OLNACBW027NBOG = 'All loans not elsewhere classified'             # weekly

    H8B3092NCBD    = 'Total federal funds sold and reverse RPs'       # weekly

    H8B3053NCBD    = 'Other assets including trading assets'          # weekly
}

$liability_descriptions = [ordered] @{

    LTDACBW027NBOG  = 'Large time deposits'
    ODSACBW027NBOG  = 'Other deposits'
    # H8B3094NCBD     = 'Borrowings'                                            # weekly
    NDFACBW027NBOG  = 'Net due to related foreign offices'
    # H8B3095NCBD     = 'Other liabilities including trading liabilities'       # weekly
}

$liability_weekly_descriptions = [ordered] @{
    H8B3094NCBD     = 'Borrowings'                                            # weekly
    H8B3095NCBD     = 'Other liabilities including trading liabilities'       # weekly
}

# $weekly_descriptions = @{

# }

# $descriptions = $asset_descriptions + $asset_weekly_descriptions + $liability_descriptions + $weekly_descriptions

$descriptions = $asset_descriptions + $asset_weekly_descriptions + $liability_descriptions + $liability_weekly_descriptions

$assets             = $asset_descriptions.Keys
$assets_weekly      = $asset_weekly_descriptions.Keys
$liabilities        = $liability_descriptions.Keys
$liabilities_weekly = $liability_weekly_descriptions.Keys

# $ids = $assets + $liabilities

# FRED appears to only allow up to 12 ids to be requested via the CSV URL approach

# $batch_1 = $ids | Select-Object -Skip  0 | Select-Object -First 12
# $batch_2 = $ids | Select-Object -Skip 12 | Select-Object -First 12


$assets_ids             = $assets               | Select-Object -Skip  0 | Select-Object -First 12
$assets_weekly_ids      = $assets_weekly        | Select-Object -Skip  0 | Select-Object -First 12
$liabilities_ids        = $liabilities          | Select-Object -Skip  0 | Select-Object -First 12
$liabilities_weekly_ids = $liabilities_weekly   | Select-Object -Skip  0 | Select-Object -First 12

# $batch_3 = $weekly | Select-Object -Skip 0 | Select-Object -First 12

# $date = '2000-01-01'
# $date = '2020-01-01'

# $data_1 = get-fred-data $batch_1 '2000-01-01'
# $data_2 = get-fred-data $batch_2 '2000-01-01'

# $data_1 = get-fred-data $batch_1 $date
# $data_2 = get-fred-data $batch_2 $date

$data_1 = get-fred-data $assets_ids             $date
$data_2 = get-fred-data $assets_weekly_ids      $date
$data_3 = get-fred-data $liabilities_ids        $date
$data_4 = get-fred-data $liabilities_weekly_ids $date

# $data_weekly = get-fred-data $weekly $date

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
    $other = $data_3 | Where-Object DATE -EQ $row.DATE

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
    $other = $data_4 | Where-Object DATE -EQ $row.DATE

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
    $row.H8B3092NCBD = $row.H8B3092NCBD / 1000
    $row.H8B3053NCBD = $row.H8B3053NCBD / 1000
    $row.H8B3094NCBD = $row.H8B3094NCBD / 1000
    $row.H8B3095NCBD = $row.H8B3095NCBD / 1000         
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

$datasets_assets                = create-datasets $assets              1
$datasets_assets_weekly         = create-datasets $assets_weekly       1
$datasets_liabilities           = create-datasets $liabilities        -1
$datasets_liabilities_weekly    = create-datasets $liabilities_weekly -1

# $datasets_weekly      = create-datasets $weekly       1

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
            # datasets = $datasets_assets + $datasets_liabilities + $datasets_weekly
            datasets = $datasets_assets + $datasets_assets_weekly + $datasets_liabilities + $datasets_liabilities_weekly
        }
        options = @{
            title = @{ display = $true; text = 'Assets and Liabilities of Commercial Banks in the United States : Not Seasonally Adjusted (billions USD)' }
            legend = @{ position = 'left' }
            scales = @{ 
                xAxes = @(@{ stacked = $true })
                yAxes = @(@{ stacked = $true })
                # yAxes = @(@{ stacked = $true; ticks = @{ beginAtZero = $false } })
            }
        }
    }
} | ConvertTo-Json -Depth 100

$result = Invoke-RestMethod -Method Post -Uri 'https://quickchart.io/chart/create' -Body $json -ContentType 'application/json'

# Start-Process $result.url

$id = ([System.Uri] $result.url).Segments[-1]

Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)
# ----------------------------------------------------------------------
exit
# ----------------------------------------------------------------------
. .\fed-balance-sheet-chart-detail.ps1 -date '2020-01-01'
. .\fed-balance-sheet-chart-detail.ps1 -date '2023-01-01'
. .\fed-balance-sheet-chart-detail.ps1 -date '2023-03-01'