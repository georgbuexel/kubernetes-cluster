Install-Feature -FeatureName Containers
md -Path "C:\Users\Administrator\DockerDownloads"
Invoke-WebRequest -Uri https://download.docker.com/win/static/stable/x86_64/docker-24.0.4.zip -OutFile C:\Users\Administrator\DockerDownloads\docker-24.0.4.zip -UseBasicParsing
Expand-Archive -Path "C:\Users\Administrator\DockerDownloads\docker-24.0.4.zip" -DestinationPath "C:\Users\Administrator\DockerDownloads\docker-24.0.4"
Copy-File -SourcePath C:\Users\Administrator\DockerDownloads\docker-24.0.4\docker\docker.exe -DestinationPath C:\Windows\System32\docker.exe
Copy-File -SourcePath C:\Users\Administrator\DockerDownloads\docker-24.0.4\docker\dockerd.exe -DestinationPath C:\Windows\System32\dockerd.exe
md -Path C:\ProgramData\docker\config
$daemonSettings = New-Object PSObject
# $certsPath = "C:\ProgramData\docker\config\certs.d"
# $daemonSettings | Add-Member NoteProperty hosts @("npipe://", "0.0.0.0:2376")
$daemonSettings | Add-Member NoteProperty hosts @("npipe://")
$daemonSettingsFile = "C:\ProgramData\docker\config\daemon.json"
$daemonSettings | ConvertTo-Json | Out-File -FilePath $daemonSettingsFile -Encoding ASCII
& dockerd --register-service --service-name docker
Set-Service -Name docker -StartupType 'Automatic'
Start-Service -Name docker

nssm install cri-dockerd <path_to_dockerd> --config-file=<path_to_dockerd_config>
Replace <path_to_dockerd> with the path to the dockerd executable (e.g., C:\Program Files\Docker\Docker\resources\bin\dockerd.exe).

Replace <path_to_dockerd_config> with the path to the daemon.json configuration file for Docker (e.g., C:\ProgramData\Docker\config\daemon.json).

