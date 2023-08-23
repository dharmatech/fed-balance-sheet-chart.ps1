#!/bin/sh

cd /var/www/dharmatech.dev/data/fed-balance-sheet-chart.ps1

# pwsh ./treasury-gov-tga-chart-table-iii-a-public-debt-transactions.ps1 -display_chart_url -save_iframe

pwsh ./fed-balance-sheet-chart-detail.ps1 -date '2020-01-01' -display_chart_url -save_iframe

mv fed-balance-sheet-chart-detail.html ../reports

# tmux new-session -d -x 300 bash -c 'script -q -c ./to-report.sh'
