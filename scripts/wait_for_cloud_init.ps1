while (!(Test-Path "C:\Windows\Temp\boot-finished")){
   echo "Waiting for cloud-init..."
   sleep 1
}