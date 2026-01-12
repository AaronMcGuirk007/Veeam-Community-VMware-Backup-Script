Connect-VIServer `
  -Server   '192.168.1.1' `  # Replace with vCenter or ESXi Host IP
  -User     'veeam@bindncrypt.com' `
  -Password 'yourpasswordhere'

(
  Get-VM |
    Where-Object { $_.Name -notlike 'vCLS-*' } |
    Select-Object -ExpandProperty Name |
    ForEach-Object { "`"$_`"" }
) -join ', ' |
  Out-File -FilePath 'C:\Path\To\Export\output.txt'

