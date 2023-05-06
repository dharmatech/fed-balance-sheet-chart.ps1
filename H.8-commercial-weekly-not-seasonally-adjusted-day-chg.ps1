
# Replace Loans line item with components

Param($date)

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

function get-fred-data-chg-day ($ids, $date)
{
    $result = Invoke-RestMethod (
        'https://fred.stlouisfed.org/graph/fredgraph.csv?id={0}&cosd={1}&coed={1}&transformation={2}' -f 
            ($ids -join ','), 
            (@($date) * $ids.Count -join ','),
            (@('chg') * $ids.Count -join ',')
    )

    $result | ConvertFrom-Csv
}
# ----------------------------------------------------------------------
if ($date -eq $null)
{
    # $recent = get-fred-data @('WALCL') (Get-Date (Get-Date).AddDays(-30) -Format 'yyyy-MM-dd')

    $recent = get-fred-data @('TLAACBW027NBOG') (Get-Date (Get-Date).AddDays(-30) -Format 'yyyy-MM-dd')
   
    $date = ($recent | Select-Object -Last 1).DATE
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

# $data_1 = get-fred-data $assets_ids             $date
# $data_2 = get-fred-data $assets_weekly_ids      $date
# $data_3 = get-fred-data $liabilities_ids        $date
# $data_4 = get-fred-data $liabilities_weekly_ids $date

$data_1 = get-fred-data-chg-day $assets_ids             $date
$data_2 = get-fred-data-chg-day $assets_weekly_ids      $date
$data_3 = get-fred-data-chg-day $liabilities_ids        $date
$data_4 = get-fred-data-chg-day $liabilities_weekly_ids $date

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
    $row.H8B3092NCBD_CHG = $row.H8B3092NCBD_CHG / 1000
    $row.H8B3053NCBD_CHG = $row.H8B3053NCBD_CHG / 1000
    $row.H8B3094NCBD_CHG = $row.H8B3094NCBD_CHG / 1000   
    $row.H8B3095NCBD_CHG = $row.H8B3095NCBD_CHG / 1000   
         
}



Write-Host 'done' -ForegroundColor Yellow
# ----------------------------------------------------------------------

$data = $data_1

$assets_data = $data | Select-Object *

$assets_data.'LTDACBW027NBOG_CHG' = $null
$assets_data.'ODSACBW027NBOG_CHG' = $null
$assets_data.'NDFACBW027NBOG_CHG' = $null
$assets_data.'H8B3094NCBD_CHG'    = $null
$assets_data.'H8B3095NCBD_CHG'    = $null

$liabilities_data = $data | Select-Object *

$liabilities_data.'TMBACBW027NBOG_CHG' = $null
$liabilities_data.'TNMACBW027NBOG_CHG' = $null
$liabilities_data.'OMBACBW027NBOG_CHG' = $null
$liabilities_data.'ONMACBW027NBOG_CHG' = $null
$liabilities_data.'TOTCINSA_CHG'       = $null
$liabilities_data.'RHEACBW027NBOG_CHG' = $null
$liabilities_data.'CRLACBW027NBOG_CHG' = $null
$liabilities_data.'CCLACBW027NBOG_CHG' = $null
$liabilities_data.'ALLACBW027NBOG_CHG' = $null
$liabilities_data.'CASACBW027NBOG_CHG' = $null
$liabilities_data.'LCBACBW027NBOG_CHG' = $null
$liabilities_data.'CLDACBW027NBOG_CHG' = $null
$liabilities_data.'SBFACBW027NBOG_CHG' = $null
$liabilities_data.'SMPACBW027NBOG_CHG' = $null
$liabilities_data.'SNFACBW027NBOG_CHG' = $null
$liabilities_data.'AOCACBW027NBOG_CHG' = $null
$liabilities_data.'CARACBW027NBOG_CHG' = $null
$liabilities_data.'LNFACBW027NBOG_CHG' = $null
$liabilities_data.'OLNACBW027NBOG_CHG' = $null
$liabilities_data.'H8B3092NCBD_CHG'    = $null
$liabilities_data.'H8B3053NCBD_CHG'    = $null




function chart-day-change ()
{
    $labels = $assets_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object {
        $series = $_.Name -replace '_CHG', '' 

        $result = $descriptions[$series]

        if ($result -eq $null)
        {
            $series
        }
        else
        {
            # $result

            '{0} : {1}' -f $series, $result
        }
    }

    # $labels = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { 
    # $labels = $assets_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object {         
    #     $series = $_.Name -replace '_CHG', '' 
    
    #     # $result = $label_table[$series]
    #     $result = $label_table_abbreviated[$series]
    
    #     if ($result -eq $null)
    #     {
    #         $series
    #     }
    #     else
    #     {
    #         $result
    #     }
    # }
    
    $json = @{
        chart = @{
            # type = 'bar'
            type = 'horizontalBar'
            data = @{      
                        
                labels = $labels
                
                datasets = @(
                    @{
                        # data = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object Value

                        # data = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) }

                        label = 'Assets'
                        # data = $assets_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) }
                        data = $assets_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1, 2) }

                        
                    }
                    @{
                        # data = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object Value

                        # data = $data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) }

                        label = 'Liabilities'
                        # data = $liabilities_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1000, 2) }
                        data = $liabilities_data.psobject.Members | Where-Object MemberType -EQ NoteProperty | Where-Object Name -NE DATE | ForEach-Object { [math]::Round($_.Value / 1, 2) }
                    }

                )
            }
            options = @{
                # title = @{ display = $true; text = ('Federal Reserve Balance Sheet : {0} change {1} (billions USD)' -f $side, $data.DATE) }

                title = @{ display = $true; text = ('Assets and Liabilities of Commercial Banks in the United States : Not Seasonally Adjusted : {0} (billions USD)' -f $data.DATE) }
                # legend = @{ position = 'left' }
                
                scales = @{ 
                    # xAxes = @(@{ stacked = $true })
                    # yAxes = @(@{ stacked = $true })

                    # yAxes = @(
                    #     @{
                    #         ticks = @{
                    #             min = $y_min
                    #             max = $y_max
                    #         }
                    #     }
                    # )
                }
            }
        }
    } | ConvertTo-Json -Depth 100
    
    $result = Invoke-RestMethod -Method Post -Uri 'https://quickchart.io/chart/create' -Body $json -ContentType 'application/json'
            
    $id = ([System.Uri] $result.url).Segments[-1]
    
    Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)
}

chart-day-change
# ----------------------------------------------------------------------
exit
# ----------------------------------------------------------------------
