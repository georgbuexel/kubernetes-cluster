Set-Service -Name kubelet -StartupType 'Automatic';
Set-Service -Name kube-proxy -StartupType 'Automatic';
Start-Service -Name kubelet;
Start-Service -Name kube-proxy;
