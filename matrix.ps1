# matrix.ps1 — PowerShell wrapper that forwards to WSL
# Install: copy to a directory in your PATH, or add Matrix dir to PATH

$args_str = ($args | ForEach-Object { "`"$_`"" }) -join " "
wsl -e bash -lc "matrix $args_str"
