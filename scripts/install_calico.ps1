$powerShellPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$baseDir = "$PSScriptRoot\..\.."
$NSSMPath = "$baseDir\nssm\win64\nssm.exe"
function Set-EnvVarIfNotSet {
    param(
        [parameter(Mandatory=$true)] $var,
        [parameter(Mandatory=$true)] $defaultValue
    )
    if (-not (Test-Path "env:$var"))
    {
        Write-Host ("Environment variable $var is not set. Setting it to the default value: {0}" -f $defaultValue)
        [Environment]::SetEnvironmentVariable($var, $defaultValue, 'Process')
    } else {
        Write-Host ("Environment variable $var is already set: {0}" -f (gci env:$var | select -expand Value))
    }
}

function Set-ConfigParameters {
    param(
        [parameter(Mandatory=$true)] $var,
        [parameter(Mandatory=$true)] $value
    )
    $OldString='Set-EnvVarIfNotSet -var "{0}".*$' -f $var
    $NewString='Set-EnvVarIfNotSet -var "{0}" -defaultValue "{1}"' -f $var, $value
    (Get-Content $baseDir\config.ps1) -replace $OldString, $NewString | Set-Content $baseDir\config.ps1 -Force
}
# ipmo is alias for Import-Module
$ReleaseBaseURL="https://github.com/projectcalico/calico/releases/download/v3.26.1/",
$ReleaseFile="calico-windows-v3.26.1.zip",
$KubeVersion="",
$DownloadOnly="no",
$StartCalico="yes",
$AutoCreateServiceAccountTokenSecret="yes",
$Datastore="kubernetes",
$EtcdEndpoints="",
$EtcdTlsSecretName="",
$EtcdKey="",
$EtcdCert="",
$EtcdCaCert="",
$ServiceCidr="10.96.0.0/12",
$DNSServerIPs="10.96.0.10",
$CalicoBackend=""

$ErrorActionPreference = "Stop"
$BaseDir="c:\k"
$RootDir="c:\CalicoWindows"
$CalicoZip="c:\calico-windows.zip"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$helper = "$BaseDir\helper.psm1"
$helperv2 = "$BaseDir\helper.v2.psm1"
md $BaseDir -ErrorAction Ignore
Invoke-WebRequest https://raw.githubusercontent.com/Microsoft/SDN/master/Kubernetes/windows/helper.psm1 -O $BaseDir\helper.psm1
Invoke-WebRequest https://raw.githubusercontent.com/Microsoft/SDN/master/Kubernetes/windows/helper.v2.psm1 -O $BaseDir\helper.v2.psm1
ipmo -force -DisableNameChecking $helper
ipmo -force -DisableNameChecking $helperv2
# Überprüfen
#DownloadFile -Url $ReleaseBaseURL/$ReleaseFile -Destination c:\calico-windows.zip
$platform="ec2"
Remove-Item $RootDir -Force  -Recurse -ErrorAction SilentlyContinue
Expand-Archive -Force $CalicoZip c:\
ipmo -force $RootDir\libs\calico\calico.psm1
Set-ConfigParameters -var 'CALICO_DATASTORE_TYPE' -value $Datastore
Set-ConfigParameters -var 'ETCD_ENDPOINTS' -value $EtcdEndpoints
Set-ConfigParameters -var 'ETCD_KEY_FILE' -value $EtcdKey
Set-ConfigParameters -var 'ETCD_CERT_FILE' -value $EtcdCert
Set-ConfigParameters -var 'ETCD_CA_CERT_FILE' -value $EtcdCaCert
Set-ConfigParameters -var 'K8S_SERVICE_CIDR' -value $ServiceCidr
Set-ConfigParameters -var 'DNS_NAME_SERVERS' -value $DNSServerIPs

$token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "300"} -Method PUT -Uri http://169.254.169.254/latest/api/token -ErrorAction Ignore
$awsNodeName = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/local-hostname -ErrorAction Ignore
Set-ConfigParameters -var 'NODENAME' -value $awsNodeName
# Springe in die Funktion
# $calicoNs = GetCalicoNamespace
$ErrorActionPreference = 'Continue'
$name=c:\k\kubectl.exe --kubeconfig=$KubeConfigPath get ns calico-system
$ErrorActionPreference = 'Stop'
$calicoNs = "kube-system"
# Springe in die Funktion
# GetCalicoKubeConfig -CalicoNamespace $calicoNs

$ErrorActionPreference = 'Continue'
$CalicoNamespace = $calicoNs
$KubeConfigPath = "c:\\k\\config"
$secretName=c:\k\kubectl.exe --kubeconfig=$KubeConfigPath get secret -n $CalicoNamespace --field-selector=type=kubernetes.io/service-account-token --no-headers -o custom-columns=":metadata.name" | findstr $SecretNamePrefix | select -first 1
$ErrorActionPreference = 'Stop'
$secretName = "calico-node-token"
# Springe in die Funktion CreateTokenAccountSecret -Name $secretName -Namespace $CalicoNamespace -KubeConfigPath $KubeConfigPath
$Name = $secretName
$Namespace = $calicoNs
$KubeConfigPath = "c:\\k\\config"
$tempFile = C:\Users\Administrator\AppData\Local\Temp\2\tmp2A4.tmp
$yaml=@"
apiVersion: v1
kind: Secret
metadata:
  name: $Name
  namespace: $Namespace
  annotations:
    kubernetes.io/service-account.name: calico-node
type: kubernetes.io/service-account-token
"@
Set-Content -Path $tempFile.FullName -value $yaml
c:\k\kubectl --kubeconfig $KubeConfigPath apply -f $tempFile.FullName
# CA from the k8s secret is already base64-encoded.
$ca=c:\k\kubectl.exe --kubeconfig=$KubeConfigPath get secret/$secretName -o jsonpath='{.data.ca\.crt}' -n $CalicoNamespace
# Token from the k8s secret is base64-encoded but we need the jwt token.
$tokenBase64=c:\k\kubectl.exe --kubeconfig=$KubeConfigPath get secret/$secretName -o jsonpath='{.data.token}' -n $CalicoNamespace
$token=[System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($tokenBase64))

$server=(Get-ChildItem $KubeConfigPath | Select-String https).Line
(Get-Content $RootDir\calico-kube-config.template).replace('<ca>', $ca).replace('<server>', $server.Trim()).replace('<token>', $token) | Set-Content $RootDir\calico-kube-config -Force
# Raus aus der Funktion GetCalicoKubeConfig
# Springe in die Funktion $Backend = GetBackendType -CalicoNamespace $calicoNs
$KubeConfigPath = "$RootDir\calico-kube-config"
$encap=c:\k\kubectl.exe --kubeconfig="$KubeConfigPath" get felixconfigurations.crd.projectcalico.org default -o jsonpath='{.spec.ipipEnabled}'
$encap=c:\k\kubectl.exe --kubeconfig="$KubeConfigPath" get felixconfigurations.crd.projectcalico.org default -o jsonpath='{.spec.vxlanEnabled}'
$ipipModes = c:\k\kubectl.exe --kubeconfig="$KubeConfigPath" get ippools.crd.projectcalico.org -o jsonpath='{.items[*].spec.ipipMode}'
$ipipEnabled = $ipipModes | Select-String -pattern '(Always)|(CrossSubnet)'
$vxlanModes=c:\k\kubectl.exe --kubeconfig="$KubeConfigPath" get ippools.crd.projectcalico.org -o jsonpath='{.items[*].spec.vxlanMode}'
$vxlanEnabled = $vxlanModes | Select-String -pattern '(Always)|(CrossSubnet)'
# return ("bgp")
$Backend = "bgp"
# Raus aus der Funktion $Backend = GetBackendType -CalicoNamespace $calicoNs

Set-ConfigParameters -var 'CALICO_NETWORKING_BACKEND' -value "windows-bgp"
# Springe in die Funktion InstallCalico
pushd
cd $RootDir
# Springe in das Modul .\install-calico.ps1
$PSScriptRoot = ""C:\CalicoWindows"
ipmo "$PSScriptRoot\libs\calico\calico.psm1" -Force
Unblock-File $PSScriptRoot\*.ps1
# Springe in . $PSScriptRoot\config.ps1
$baseDir = "$PSScriptRoot"
ipmo $baseDir\libs\calico\calico.psm1 -Force
Set-EnvVarIfNotSet -var "KUBE_NETWORK" -defaultValue "Calico.*"

Set-EnvVarIfNotSet -var "CALICO_NETWORKING_BACKEND" -defaultValue "windows-bgp"

Set-EnvVarIfNotSet -var "K8S_SERVICE_CIDR" -defaultValue "10.96.0.0/12"
Set-EnvVarIfNotSet -var "DNS_NAME_SERVERS" -defaultValue "10.96.0.10"
Set-EnvVarIfNotSet -var "DNS_SEARCH" -defaultValue "svc.cluster.local"

Set-EnvVarIfNotSet -var "CALICO_DATASTORE_TYPE" -defaultValue "kubernetes"

Set-EnvVarIfNotSet -var "KUBECONFIG" -defaultValue "$PSScriptRoot\calico-kube-config"

Set-EnvVarIfNotSet -var "ETCD_ENDPOINTS" -defaultValue ""
Set-EnvVarIfNotSet -var "ETCD_KEY_FILE" -defaultValue ""
Set-EnvVarIfNotSet -var "ETCD_CERT_FILE" -defaultValue ""
Set-EnvVarIfNotSet -var "ETCD_CA_CERT_FILE" -defaultValue ""
# Bei containerd wäre 
# Set-EnvVarIfNotSet -var "CNI_BIN_DIR" -defaultValue (Get-ContainerdCniBinDir)
# Set-EnvVarIfNotSet -var "CNI_CONF_DIR" -defaultValue (Get-ContainerdCniConfDir)
# Ich muss hier noch ein mal überprüfen
Set-EnvVarIfNotSet -var "CNI_BIN_DIR" -defaultValue "c:\k\cni"
Set-EnvVarIfNotSet -var "CNI_CONF_DIR" -defaultValue "c:\k\cni\config"

Set-EnvVarIfNotSet -var "CNI_CONF_FILENAME" -defaultValue "10-calico.conf"
Set-EnvVarIfNotSet -var "CNI_IPAM_TYPE" -defaultValue "calico-ipam"
Set-EnvVarIfNotSet -var "VXLAN_VNI" -defaultValue 4096
$env:VXLAN_MAC_PREFIX = "0E-2A"
Set-EnvVarIfNotSet -var "VXLAN_MAC_PREFIX" -defaultValue "0E-2A"
Set-EnvVarIfNotSet -var "VXLAN_ADAPTER" -defaultValue ""

## Node configuration.

Set-EnvVarIfNotSet -var "NODENAME" -defaultValue "ip-10-0-1-192.eu-central-1.compute.internal"
Set-EnvVarIfNotSet -var "CALICO_K8S_NODE_REF" -defaultValue $env:NODENAME
Set-EnvVarIfNotSet -var "STARTUP_VALID_IP_TIMEOUT" -defaultValue 90
Set-EnvVarIfNotSet -var "IP" -defaultValue "autodetect"
Set-EnvVarIfNotSet -var "CALICO_LOG_DIR" -defaultValue "$PSScriptRoot\logs"
Set-EnvVarIfNotSet -var "FELIX_LOGSEVERITYFILE" -defaultValue "none"
Set-EnvVarIfNotSet -var "FELIX_LOGSEVERITYSYS" -defaultValue "none"

# Raus aus . $PSScriptRoot\config.ps1
# Springe in die Funtion Test-CalicoConfiguration
# Musste direktories anlegen md c:\k\cni\config
# Raus aus Test-CalicoConfiguration
# Springe in die Funtion Install-NodeService
# Springe in die Funtion ensureRegistryKey
$softwareRegistryKey = "HKLM:\Software\Tigera"
$calicoRegistryKey = $softwareRegistryKey + "\Calico"
New-Item $softwareRegistryKey
New-Item $calicoRegistryKey
# Raus aus ensureRegistryKey
# Springe in die Funktion Install-NodeService

Unblock-File $baseDir\node\node-service.ps1


& $NSSMPath install CalicoNode $powerShellPath
& $NSSMPath set CalicoNode AppParameters $baseDir\node\node-service.ps1
& $NSSMPath set CalicoNode AppDirectory $baseDir
& $NSSMPath set CalicoNode DisplayName "Calico Windows Startup"
& $NSSMPath set CalicoNode Description "Calico Windows Startup, configures Calico datamodel resources for this node."

& $NSSMPath set CalicoNode Start SERVICE_AUTO_START
& $NSSMPath set CalicoNode ObjectName LocalSystem
& $NSSMPath set CalicoNode Type SERVICE_WIN32_OWN_PROCESS

& $NSSMPath set CalicoNode AppThrottle 1500
md -Path "$env:CALICO_LOG_DIR"
& $NSSMPath set CalicoNode AppStdout $env:CALICO_LOG_DIR\calico-node.log
& $NSSMPath set CalicoNode AppStderr $env:CALICO_LOG_DIR\calico-node.err.log

& $NSSMPath set CalicoNode AppRotateFiles 1
& $NSSMPath set CalicoNode AppRotateOnline 1
& $NSSMPath set CalicoNode AppRotateSeconds 86400
& $NSSMPath set CalicoNode AppRotateBytes 10485760

# Raus aus Install-NodeService

# Springe in die Funktion Install-FelixService
Unblock-File $baseDir\felix\felix-service.ps1

# We run Felix via a wrapper script to make it easier to update env vars.
& $NSSMPath install CalicoFelix $powerShellPath
& $NSSMPath set CalicoFelix AppParameters $baseDir\felix\felix-service.ps1
& $NSSMPath set CalicoFelix AppDirectory $baseDir
& $NSSMPath set CalicoFelix DependOnService "CalicoNode"
& $NSSMPath set CalicoFelix DisplayName "Calico Windows Agent"
& $NSSMPath set CalicoFelix Description "Calico Windows Per-host Agent, Felix, provides network policy enforcement for Kubernetes."

# Configure it to auto-start by default.
& $NSSMPath set CalicoFelix Start SERVICE_AUTO_START
& $NSSMPath set CalicoFelix ObjectName LocalSystem
& $NSSMPath set CalicoFelix Type SERVICE_WIN32_OWN_PROCESS

# Throttle process restarts if Felix restarts in under 1500ms.
& $NSSMPath set CalicoFelix AppThrottle 1500
& $NSSMPath set CalicoFelix AppStdout $env:CALICO_LOG_DIR\calico-felix.log
& $NSSMPath set CalicoFelix AppStderr $env:CALICO_LOG_DIR\calico-felix.err.log

# Configure online file rotation.
& $NSSMPath set CalicoFelix AppRotateFiles 1
& $NSSMPath set CalicoFelix AppRotateOnline 1
# Rotate once per day.
& $NSSMPath set CalicoFelix AppRotateSeconds 86400
# Rotate after 10MB.
& $NSSMPath set CalicoFelix AppRotateBytes 10485760

# Raus aus Install-FelixService

# Springe in die Funktion Install-ConfdService

Unblock-File $baseDir\confd\confd-service.ps1

# We run confd via a wrapper script to make it easier to update env vars.
& $NSSMPath install CalicoConfd $powerShellPath
& $NSSMPath set CalicoConfd AppParameters $baseDir\confd\confd-service.ps1
& $NSSMPath set CalicoConfd AppDirectory $baseDir
& $NSSMPath set CalicoConfd DependOnService "CalicoNode"
& $NSSMPath set CalicoConfd DisplayName "Calico BGP Agent"
& $NSSMPath set CalicoConfd Description "Calico BGP Agent, confd, configures BGP routing."

# Configure it to auto-start by default.
& $NSSMPath set CalicoConfd Start SERVICE_AUTO_START
& $NSSMPath set CalicoConfd ObjectName LocalSystem
& $NSSMPath set CalicoConfd Type SERVICE_WIN32_OWN_PROCESS

# Throttle process restarts if confd restarts in under 1500ms.
& $NSSMPath set CalicoConfd AppThrottle 1500
& $NSSMPath set CalicoConfd AppStdout $env:CALICO_LOG_DIR\calico-confd.log
& $NSSMPath set CalicoConfd AppStderr $env:CALICO_LOG_DIR\calico-confd.err.log

# Configure online file rotation.
& $NSSMPath set CalicoConfd AppRotateFiles 1
& $NSSMPath set CalicoConfd AppRotateOnline 1
# Rotate once per day.
& $NSSMPath set CalicoConfd AppRotateSeconds 86400
# Rotate after 10MB.
& $NSSMPath set CalicoConfd AppRotateBytes 10485760
# Raus aus Install-ConfdService

# Springe in die Funktion Install-CNIPlugin
cp "$baseDir\cni\*.exe" "$env:CNI_BIN_DIR"
$cniConfFile = $env:CNI_CONF_DIR + "\" + $env:CNI_CONF_FILENAME
$nodeNameFile = "$baseDir\nodename".replace('\', '\\')
$etcdKeyFile = "$env:ETCD_KEY_FILE".replace('\', '\\')
$etcdCertFile = "$env:ETCD_CERT_FILE".replace('\', '\\')
$etcdCACertFile = "$env:ETCD_CA_CERT_FILE".replace('\', '\\')
$kubeconfigFile = "$env:KUBECONFIG".replace('\', '\\')
$mode = ""

$dnsIPs = "$env:DNS_NAME_SERVERS".Split(",")
$ipList = @()
foreach ($ip in $dnsIPs) {
    $ipList += "`"$ip`""
}
$dnsIPList=($ipList -join ",").TrimEnd(',')

# HNS v1 and v2 have different string values for the ROUTE endpoint policy type.
$routeType = "ROUTE"

# Hier muss ich noch mal sehen, weil bei Containerd geprüft wird

$dsrSupport = "$true"

(Get-Content "$baseDir\cni.conf.template") | ForEach-Object {
    $_.replace('__NODENAME_FILE__', $nodeNameFile).
            replace('__KUBECONFIG__', $kubeconfigFile).
            replace('__K8S_SERVICE_CIDR__', $env:K8S_SERVICE_CIDR).
            replace('__DNS_NAME_SERVERS__', $dnsIPList).
            replace('__DATASTORE_TYPE__', $env:CALICO_DATASTORE_TYPE).
            replace('__DSR_SUPPORT__', $dsrSupport).
            replace('__ETCD_ENDPOINTS__', $env:ETCD_ENDPOINTS).
            replace('__ETCD_KEY_FILE__', $etcdKeyFile).
            replace('__ETCD_CERT_FILE__', $etcdCertFile).
            replace('__ETCD_CA_CERT_FILE__', $etcdCACertFile).
            replace('__IPAM_TYPE__', $env:CNI_IPAM_TYPE).
            replace('__MODE__', $mode).
            replace('__VNI__', $env:VXLAN_VNI).
            replace('__MAC_PREFIX__', $env:VXLAN_MAC_PREFIX).
            replace('__ROUTE_TYPE__', $routeType)
} | Set-Content "$cniConfFile"
# Raus aus Install-CNIPlugin

# Raus aus Modul .\install-calico.ps1
popd
# Raus aus InstallCalico
Start-Service CalicoNode
Wait-ForCalicoInit
Start-Service CalicoFelix
Start-Service CalicoConfd
New-NetFirewallRule -Name KubectlExec10250 -Description "Enable kubectl exec and log" -Action Allow -LocalPort 10250 -Enabled True -DisplayName "kubectl exec 10250" -Protocol TCP -ErrorAction SilentlyContinue

  
