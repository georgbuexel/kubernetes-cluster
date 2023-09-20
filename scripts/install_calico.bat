<powershell>
###############################################################Install Calico####################################################
# mkdir C:\k
#Copy the Kubernetes kubeconfig file from the master node (default, Location $HOME/.kube/config), to c:\k\config.

Invoke-WebRequest https://github.com/projectcalico/calico/releases/download/v3.26.1/install-calico-windows.ps1 -OutFile c:\install-calico-windows.ps1

c:\install-calico-windows.ps1 -KubeVersion 1.20.0

#Install and start kubelet/kube-proxy service. Execute following PowerShell script/commands.
C:\CalicoWindows\kubernetes\install-kube-services.ps1
Set-Service -Name kubelet -StartupType ‘Automatic’;
Set-Service -Name kube-proxy -StartupType ‘Automatic’;

Start-Service -Name kubelet
Start-Service -Name kube-proxy

#Copy kubectl.exe, kubeadm.etc to the folder below which is on the path: 
cp C:\k\*.exe C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps
</powershell>