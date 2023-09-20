$powerShellPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$baseDir = "$PSScriptRoot\.."
$NSSMPath = "$baseDir\nssm\win64\nssm.exe"
$kubePath = "c:\k"
# Springe in Install-KubeletService

Unblock-File $baseDir\kubernetes\kubelet-service.ps1

    & $NSSMPath install kubelet $powerShellPath
    & $NSSMPath set kubelet AppParameters $baseDir\kubernetes\kubelet-service.ps1
    & $NSSMPath set kubelet AppDirectory $baseDir
    & $NSSMPath set kubelet DisplayName "kubelet service"
    & $NSSMPath set kubelet Description "Kubernetes kubelet node agent."

    # Configure it to auto-start by default.
    & $NSSMPath set kubelet Start SERVICE_AUTO_START
    & $NSSMPath set kubelet ObjectName LocalSystem
    & $NSSMPath set kubelet Type SERVICE_WIN32_OWN_PROCESS

    # Throttle process restarts if restarts in under 1500ms.
    & $NSSMPath set kubelet AppThrottle 1500

    & $NSSMPath set kubelet AppStdout $kubePath\kubelet.out.log
    & $NSSMPath set kubelet AppStderr $kubePath\kubelet.err.log

    # Configure online file rotation.
    & $NSSMPath set kubelet AppRotateFiles 1
    & $NSSMPath set kubelet AppRotateOnline 1
    # Rotate once per day.
    & $NSSMPath set kubelet AppRotateSeconds 86400
    # Rotate after 10MB.
    & $NSSMPath set kubelet AppRotateBytes 10485760
# Raus aus Install-KubeletService
# Springe in die Funktion Install-KubeProxyService

Unblock-File $baseDir\kubernetes\kube-proxy-service.ps1

& $NSSMPath install kube-proxy $powerShellPath
& $NSSMPath set kube-proxy AppParameters $baseDir\kubernetes\kube-proxy-service.ps1
& $NSSMPath set kube-proxy AppDirectory $baseDir
& $NSSMPath set kube-proxy DisplayName "kube-proxy service"
& $NSSMPath set kube-proxy Description "Kubernetes kube-proxy network proxy."

# Configure it to auto-start by default.
& $NSSMPath set kube-proxy Start SERVICE_AUTO_START
& $NSSMPath set kube-proxy ObjectName LocalSystem
& $NSSMPath set kube-proxy Type SERVICE_WIN32_OWN_PROCESS

# Throttle process restarts if restarts in under 1500ms.
& $NSSMPath set kube-proxy AppThrottle 1500

& $NSSMPath set kube-proxy AppStdout $kubePath\kube-proxy.out.log
& $NSSMPath set kube-proxy AppStderr $kubePath\kube-proxy.err.log

# Configure online file rotation.
& $NSSMPath set kube-proxy AppRotateFiles 1
& $NSSMPath set kube-proxy AppRotateOnline 1
# Rotate once per day.
& $NSSMPath set kube-proxy AppRotateSeconds 86400
# Rotate after 10MB.
& $NSSMPath set kube-proxy AppRotateBytes 10485760

# Raus aus Install-KubeProxyService
