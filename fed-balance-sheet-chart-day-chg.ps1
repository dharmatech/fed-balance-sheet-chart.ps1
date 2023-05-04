
# https://fred.stlouisfed.org/release/tables?rid=20&eid=1194154&od=#

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

    WLDACLC = 'Deferred availability cash items'
    WLAD = 'Other Liabilities and Accrued Dividends'
}

$capital_descriptions = [ordered] @{

}

$descriptions = $asset_descriptions + $liability_descriptions

$assets      = $asset_descriptions.Keys
$liabilities = $liability_descriptions.Keys

$ids = $assets + $liabilities

# FRED appears to only allow up to 12 ids to be requested via the CSV URL approach

$batch_1 = $ids | Select-Object -Skip  0 | Select-Object -First 12
$batch_2 = $ids | Select-Object -Skip 12 | Select-Object -First 12


# ----------------------------------------------------------------------
# Chart assets
# ----------------------------------------------------------------------

$date = '2023-04-26'

$batch_1 = $assets | Select-Object -Skip  0 | Select-Object -First 12
$batch_2 = $assets | Select-Object -Skip 12 | Select-Object -First 12

$data_1 = get-fred-data-chg $batch_1 $date
$data_2 = get-fred-data-chg $batch_2 $date

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


# $data = get-fred-data-chg $assets $date

$data = $data_1

$assets_data = $data_1

$label_table = @{
    WLCFLL = 'Loans'
    WORAL = 'Repurchase agreements'
    WSHOMCB = 'MBS'

    WLRRAL = 'RRP'
    WLODLL = 'Other deposits held by depository institutions'
    WDTGAL = 'TGA'

}

$label_table_abbreviated = @{
    WLCFLL  = 'Loans'
    WORAL   = 'Repo agreements'
    WSHOMCB = 'MBS'

    WLRRAL  = 'RRP'
    WLODLL  = 'Other deposits'
    WDTGAL  = 'TGA'
}


$labels = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { 
    $series = $_.Name -replace '_CHG', '' 

    $result = $label_table[$series]

    if ($result -eq $null)
    {
        $series
    }
    else
    {
        $result
    }
}



$json = @{
    chart = @{
        type = 'bar'
        data = @{      

            # labels = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object Name

            labels = $labels
            
            datasets = @(
                @{
                    data = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object Value
                }
            )
        }
        options = @{
            title = @{ display = $true; text = ('Federal Reserve Balance Sheet : Assets {0} (millions USD)' -f $data.DATE) }
            # legend = @{ position = 'left' }
            # scales = @{ 
            #     xAxes = @(@{ stacked = $true })
            #     yAxes = @(@{ stacked = $true })
            # }
        }
    }
} | ConvertTo-Json -Depth 100

$result = Invoke-RestMethod -Method Post -Uri 'https://quickchart.io/chart/create' -Body $json -ContentType 'application/json'

# Start-Process $result.url

$id = ([System.Uri] $result.url).Segments[-1]

Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)


$data = $assets_data

$data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) } | Measure-Object -Maximum

$data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) } | Measure-Object -Minimum


$assets_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) } | Measure-Object -Minimum
$assets_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) } | Measure-Object -Maximum


$liabilities_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) } | Measure-Object -Minimum
$liabilities_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) } | Measure-Object -Maximum


@(
$assets_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE
$liabilities_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE
).Count

$values = @(
    $assets_data.psobject.Members
    $liabilities_data.psobject.Members
    ) | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) }

$min = ($values | Measure-Object -Minimum).Minimum
$max = ($values | Measure-Object -Maximum).Maximum


function chart-day-change ($data, $side, $y_min, $y_max)
{
    $labels = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { 
        $series = $_.Name -replace '_CHG', '' 
    
        # $result = $label_table[$series]
        $result = $label_table_abbreviated[$series]
    
        if ($result -eq $null)
        {
            $series
        }
        else
        {
            $result
        }
    }
    
    $json = @{
        chart = @{
            type = 'bar'
            # type = 'horizontalBar'
            data = @{      
                        
                labels = $labels
                
                datasets = @(
                    @{
                        # data = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object Value

                        data = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) }
                    }
                )
            }
            options = @{
                title = @{ display = $true; text = ('Federal Reserve Balance Sheet : {0} change {1} (billions USD)' -f $side, $data.DATE) }
                # legend = @{ position = 'left' }
                
                scales = @{ 
                    # xAxes = @(@{ stacked = $true })
                    # yAxes = @(@{ stacked = $true })

                    yAxes = @(
                        @{
                            ticks = @{
                                min = $y_min
                                max = $y_max
                            }
                        }
                    )
                }
            }
        }
    } | ConvertTo-Json -Depth 100
    
    $result = Invoke-RestMethod -Method Post -Uri 'https://quickchart.io/chart/create' -Body $json -ContentType 'application/json'
            
    $id = ([System.Uri] $result.url).Segments[-1]
    
    Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)
}


# chart-day-change $assets_data      'Assets'      -40000 40000
# chart-day-change $liabilities_data 'Liabilities' -40000 40000

chart-day-change $assets_data      'Assets'      $min $max
chart-day-change $liabilities_data 'Liabilities' $min $max

chart-day-change $assets_data      'Assets'      -40 40
chart-day-change $liabilities_data 'Liabilities' -40 40

# ----------------------------------------------------------------------
# Chart liabilities
# ----------------------------------------------------------------------

$date = '2023-04-26'

$data = get-fred-data-chg $liabilities $date

$liabilities_data = get-fred-data-chg $liabilities $date


$data


$data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ft *

# MemberType IsSettable IsGettable Value    TypeNameOfValue Name             IsInstance
# ---------- ---------- ---------- -----    --------------- ----             ----------
# NoteProperty       True       True 685.0    System.String   WLFN_CHG               True
# NoteProperty       True       True -27538.0 System.String   WLRRAL_CHG             True
# NoteProperty       True       True 0.0      System.String   TERMT_CHG              True
# NoteProperty       True       True -32791.0 System.String   WLODLL_CHG             True
# NoteProperty       True       True 31114.0  System.String   WDTGAL_CHG             True
# NoteProperty       True       True 0.0      System.String   WDFOL_CHG              True
# NoteProperty       True       True 3455.0   System.String   WLODL_CHG              True
# NoteProperty       True       True 0.0      System.String   H41RESH4ENWW_CHG       True
# NoteProperty       True       True 125.0    System.String   WLDACLC_CHG            True
# NoteProperty       True       True -5548.0  System.String   WLAD_CHG               True

$data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [ordered]@{ x = $_.Name; y = $_.Value } }


$items = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [ordered]@{ x = $_.Name; y = $_.Value } }

$data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object Name

$data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object Value


# ----------------------------------------------------------------------
$json = @{
    chart = @{
        type = 'bar'
        data = @{      

            labels = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object Name
            
            datasets = @(
                @{
                    data = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object Value
                }
            )
        }
        options = @{
            # title = @{ display = $true; text = 'Federal Reserve Balance Sheet (millions USD)' }
            # legend = @{ position = 'left' }
            # scales = @{ 
            #     xAxes = @(@{ stacked = $true })
            #     yAxes = @(@{ stacked = $true })
            # }
        }
    }
} | ConvertTo-Json -Depth 100

$result = Invoke-RestMethod -Method Post -Uri 'https://quickchart.io/chart/create' -Body $json -ContentType 'application/json'

# Start-Process $result.url

$id = ([System.Uri] $result.url).Segments[-1]

Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)
# ----------------------------------------------------------------------





# $date = '2000-01-01'
# $date = '2020-01-01'
# $date = '2022-01-01'

# $data_1 = get-fred-data $batch_1 '2000-01-01'
# $data_2 = get-fred-data $batch_2 '2000-01-01'

# $data_1 = get-fred-data $batch_1 $date
# $data_2 = get-fred-data $batch_2 $date

$data_1 = get-fred-data-chg $batch_1 $date
$data_2 = get-fred-data-chg $batch_2 $date


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

$i = 0

# function create-datasets ($names, [int]$sign)
# {
#     foreach ($name in $names)
#     {
#         @{ 
#             label = '{0} : {1}' -f $name, $descriptions.$name
            
#             data = $items.ForEach({ $sign * $_.($name + '_CHG') }) 

#             backgroundColor = $colors[$Global:i++ % $colors.Count]
#         }
#     }
# }

function create-datasets ($names, [int]$sign, $prefix)
{
    foreach ($name in $names)
    {
        @{ 
            label = '{2} : {0} : {1}' -f $name, $descriptions.$name, $prefix
            
            data = $items.ForEach({ $sign * $_.($name + '_CHG') }) 

            backgroundColor = $colors[$Global:i++ % $colors.Count]
        }
    }
}

$datasets_assets      = create-datasets $assets       1 'AST'
$datasets_liabilities = create-datasets $liabilities -1 'LIA'

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
            datasets = $datasets_assets + $datasets_liabilities
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

Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)
