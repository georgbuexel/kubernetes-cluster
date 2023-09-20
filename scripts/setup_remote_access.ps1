Install-RemoteAccess -VpnType RoutingOnly;
Set-Service -Name RemoteAccess -StartupType 'Automatic';
Start-Service RemoteAccess;
