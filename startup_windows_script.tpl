<powershell>
@"
while (!(Test-Path "C:\Windows\Temp\boot-finished")){
   echo "Waiting for cloud-init..."
   sleep 1
}
while (!(Test-Path "C:\Windows\Temp\restart_node.ps1")){
   echo "Waiting for restart_node script..."
   sleep 1
}
while (!(Test-Path "C:\Windows\Temp\wait_for_restart.ps1")){
   echo "Waiting for wait_for_restart script..."
   sleep 1
}
while (!(Test-Path "C:\Windows\Temp\setup_remote_access.ps1")){
   echo "Waiting for setup_remote_access script..."
   sleep 1
}
while (!(Test-Path "C:\Windows\Temp\start_kube_services.ps1")){
   echo "Waiting for start_kube_services script..."
   sleep 1
}
"@ | Out-File C:\Windows\Temp\wait_for_cloud_init.ps1 -Encoding ascii;

mkdir  -force "C:\k";

#Create a new rule and allow all traffic In and out:
New-NetFireWallRule -DisplayName "Allow All Traffic" -Direction OutBound -Action Allow;
New-NetFireWallRule -DisplayName "Allow All Traffic" -Direction InBound -Action Allow;

# Install SSH
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0;
Set-Service -Name sshd -StartupType Automatic;
Start-Service sshd;

# Put KeyFile and restrict access
$key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0YlYQ6TcFvUxOhVlRERYEdl5XaoPIjdQ0cLOk40tBt2vpAx0ms3v20GakgI5YcqGEnEF+tRoVpUIllorurRUkMUifwOeRaJkCSsZQ91tNa3/vM3etEJKPI1WuaDeP+B+CDRq6W897DSHvQCHzfZbwdR8BnVnL18KmPvVo5rZDYEZgl6aXPTv+mrJ1qXdbo7HQCqnJwVwSd+lV2drMgEWt66rHmLrs/ozg+Dxgowc4r8i5MGi2mV5WK60wnl+qYg7UPOEZkRNcnjl289cciQKcBYqmtKiH07g93LHn/0mr8PZzrtFURqMgB0DAcmh4pjt6/L9QegJ1R+c3KQ5SK+U9 ubuntu@node";
Out-File -Encoding ASCII -InputObject $key -FilePath C:\ProgramData\ssh\administrators_authorized_keys;
icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F";

# Replace line in sshd config
$file = "C:\ProgramData\ssh\sshd_config";
$oldLine = "#PubkeyAuthentication yes";
$newLine = "PubkeyAuthentication yes";
$oldContent = Get-Content -Path $file;
$newContent = $oldContent -replace [regex]::Escape($oldLine), $newLine;
$newContent | Set-Content -Path $file;

# Make PowerShell as default shell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force;

# Install RemoteAccess
Install-WindowsFeature RemoteAccess;
Install-WindowsFeature RSAT-RemoteAccess-PowerShell;
Install-WindowsFeature Routing;

# Install HNS
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted;
Install-Module -Name HNS;

Install-WindowsFeature -Name containers;

# Download and extract desired containerd Windows binaries
$Version="1.6.12";
curl.exe -L https://github.com/containerd/containerd/releases/download/v$Version/containerd-$Version-windows-amd64.tar.gz -o C:\Windows\Temp\containerd-windows-amd64.tar.gz | Out-Null;
tar.exe xvf C:\Windows\Temp\containerd-windows-amd64.tar.gz -C C:\Windows\Temp | Out-Null;
Remove-Item C:\Windows\Temp\containerd-windows-amd64.tar.gz;

# Copy and configure
mkdir $Env:ProgramFiles\containerd;
Copy-Item -Path "C:\Windows\Temp\bin\*" -Destination "$Env:ProgramFiles\containerd" -Recurse -Container:$false -Force;
cd $Env:ProgramFiles\containerd\;
.\containerd.exe config default | Out-File config.toml -Encoding ascii;

# Register and start service
.\containerd.exe --register-service | Out-Null;
Set-Service -Name containerd -StartupType ‘Automatic’;
Start-Service containerd;
cd ~;

# #Restart-Computer -Force;

curl.exe -L https://dl.k8s.io/v1.27.3/kubernetes-node-windows-amd64.tar.gz -o C:\Windows\Temp\kubernetes-node-windows-amd64.tar.gz | Out-Null;
tar.exe -xvf C:\Windows\Temp\kubernetes-node-windows-amd64.tar.gz -C C:\Windows\Temp | Out-Null;
Remove-Item C:\Windows\Temp\kubernetes-node-windows-amd64.tar.gz;
# Copy
Copy-Item -Path "C:\Windows\Temp\kubernetes\node\bin\*" -Destination "C:\k" -Recurse -Container:$false -Force;

mkdir -force "C:\Program Files\containerd\cni\bin"
mkdir -force "C:\Program Files\containerd\cni\conf"
curl.exe -LO https://github.com/microsoft/windows-container-networking/releases/download/v0.2.0/windows-container-networking-cni-amd64-v0.2.0.zip | Out-Null;
Expand-Archive windows-container-networking-cni-amd64-v0.2.0.zip -DestinationPath "C:\Program Files\containerd\cni\bin" -Force;
Remove-Item windows-container-networking-cni-amd64-v0.2.0.zip;

mkdir c:\opt\cni;
mkdir C:\etc\cni;
cmd /c mklink /D C:\etc\cni\net.d "C:\Program Files\containerd\cni\conf";
cmd /c mklink /D C:\opt\cni\bin "C:\Program Files\containerd\cni\bin";

cd c:\k;
Invoke-WebRequest -Uri "https://github.com/projectcalico/calico/releases/latest/download/calicoctl-windows-amd64.exe" -OutFile kubectl-calico.exe | Out-Null;
cd ~;

curl.exe -LO "https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.23.0/crictl-v1.23.0-windows-amd64.tar.gz" | Out-Null;
tar -xvf crictl-v1.23.0-windows-amd64.tar.gz -C "$Env:ProgramFiles\containerd" | Out-Null;
Remove-Item .\crictl-v1.23.0-windows-amd64.tar.gz

Invoke-WebRequest https://github.com/projectcalico/calico/releases/download/v3.26.1/install-calico-windows.ps1 -OutFile C:\install-calico-windows.ps1 | Out-Null;

# Replace line in calico_ cript
$file1 = "C:\install-calico-windows.ps1";
$oldLine1 = "Wait-ForCalicoInit";
$newLine1 = "Start-Sleep 10";
$oldLine2 = "if (`$Backend -NE `"none`")";
$newLine2 = "if (`$false)";
$oldContent1 = Get-Content -Path $file1;
$newContent1 = $oldContent1 -replace [regex]::Escape($oldLine1), $newLine1;
$newContent2 = $newContent1 -replace [regex]::Escape($oldLine2), $newLine2;
$newContent2 | Set-Content -Path $file1;

[Environment]::SetEnvironmentVariable("Path", "$($env:path);C:\Program Files\containerd;C:\k\;", [System.EnvironmentVariableTarget]::Machine)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

Install-WindowsFeature -Name Telnet-Client;

@"
Restart-Computer -Force;
New-Item -Path "C:\Windows\Temp\computer-restarted" -ItemType File;
"@ | Out-File C:\Windows\Temp\restart_node.ps1 -Encoding ascii;

@"
while (!(Test-Path "C:\Windows\Temp\computer-restarted")){
   echo "Waiting for computer-restarted..."
   sleep 1
}
"@ | Out-File C:\Windows\Temp\wait_for_restart.ps1 -Encoding ascii;

@"
Install-RemoteAccess -VpnType RoutingOnly;
Set-Service -Name RemoteAccess -StartupType 'Automatic';
Start-Service RemoteAccess;
"@ | Out-File C:\Windows\Temp\setup_remote_access.ps1 -Encoding ascii;

@"
Set-Service -Name CalicoNode -StartupType 'Automatic';
Set-Service -Name CalicoFelix -StartupType 'Automatic';
Set-Service -Name CalicoConfd -StartupType 'Automatic';
Set-Service -Name kubelet -StartupType 'Automatic';
Set-Service -Name kube-proxy -StartupType 'Automatic';
Start-Service -Name CalicoNode;
Start-Service -Name CalicoFelix;
Start-Service -Name CalicoConfd;
Start-Service -Name kubelet;
Start-Service -Name kube-proxy;
"@ | Out-File C:\Windows\Temp\start_kube_services.ps1 -Encoding ascii;

New-Item -Path "C:\Windows\Temp\boot-finished" -ItemType File;
</powershell>
