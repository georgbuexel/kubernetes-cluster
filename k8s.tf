resource "null_resource" "cloud_init" {
  # trigger this resouce upon leader manager node when instances finishing 
  triggers = {
    manager_node_ids = aws_instance.control_plane_node[0].id
  }

  #Run on leader manager node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Run service restart on each node in the clutser
    script = "./scripts/wait_for_cloud_init.sh"
  }

  depends_on = [aws_instance.control_plane_node]

}

resource "null_resource" "k8s_cluster_init" {
  # trigger this resouce upon control plane (master) node when instances finishing 
  triggers = {
    manager_node_ids = aws_instance.control_plane_node[0].id
  }

  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Initialize the clutser
    # script = "./scripts/init_k8s.sh"
    inline = [
      "sudo kubeadm init --apiserver-cert-extra-sans ${aws_instance.control_plane_node[0].public_ip}",
    ]
  }

  depends_on = [null_resource.cloud_init]

}

resource "null_resource" "k8s_cluster_setup" {
  # trigger this resouce upon control plane (master) node when instances finishing 
  triggers = {
    manager_node_ids = aws_instance.control_plane_node[0].id
  }

  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Initialize the clutser
    script = "./scripts/init_k8s.sh"
  }

  depends_on = [null_resource.k8s_cluster_init]

}

resource "null_resource" "calico_setup" {
  # trigger this resouce upon control plane (master) node when instances finishing 
  triggers = {
    manager_node_ids = aws_instance.control_plane_node[0].id
  }

  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Initialize calico
    script = "./scripts/change_calico.sh"
  }

  depends_on = [null_resource.k8s_cluster_setup]

}

resource "null_resource" "add_completition_bash" {
  # trigger this resouce upon control plane (master) node when instances finishing 
  triggers = {
    manager_node_ids = aws_instance.control_plane_node[0].id
  }

  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Install bash completition
    script = "./scripts/add_completition_bash.sh"
  }

#   depends_on = [null_resource.cloud_init, null_resource.calico_setup]
  depends_on = [null_resource.cloud_init]

}

resource "null_resource" "load_tokens" {
  # trigger this resouce upon leader manager node when instances finishing 
  triggers = {
    manager_node_ids = aws_instance.control_plane_node[0].id
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -r ubuntu@${aws_instance.control_plane_node[0].public_ip}:/tmp/join_worker_command ${path.module}/tmp"
  }

  depends_on = [null_resource.k8s_cluster_setup]

}

resource "null_resource" "load_config" {
  # trigger this resouce upon leader manager node when instances finishing 
  triggers = {
    manager_node_ids = aws_instance.control_plane_node[0].id
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -r ubuntu@${aws_instance.control_plane_node[0].public_ip}:/home/ubuntu/.kube/config ${path.module}/tmp"
  }

  depends_on = [null_resource.k8s_cluster_setup]

}

# # resource "null_resource" "manager_slave_cloud_init" {
# #   count = var.manager_node_count - 1
# #   # trigger this resouce upon slave manager node when instances finishing 
# #   triggers = {
# #     manager_node_ids = join(",", aws_instance.manager_node.*.id)
# #   }
# # 
# #   #Run on leader manager node (the first one)
# #   connection {
# #     host        = aws_instance.manager_node[count.index + 1].public_ip
# #     type        = "ssh"
# #     user        = "ubuntu"
# #     private_key = file(pathexpand("~/.ssh/id_rsa"))
# #   }
# # 
# #   provisioner "remote-exec" {
# #     # Run service restart on each node in the clutser
# #     script = "./scripts/wait_for_cloud_init.sh"
# #   }
# # 
# #   depends_on = [aws_instance.manager_node]
# # 
# # }
# # 
# # resource "null_resource" "docker_swarm_manager_join" {
# #   count = var.manager_node_count - 1
# # 
# #   # trigger this resouce upon slave manager node's when instances finishing 
# #   triggers = {
# #     manager_node_ids = join(",", aws_instance.manager_node.*.id)
# #   }
# #   #Run on each slave manager node
# #   connection {
# #     host        = aws_instance.manager_node[count.index + 1].public_ip
# #     type        = "ssh"
# #     user        = "ubuntu"
# #     private_key = file(pathexpand("~/.ssh/id_rsa"))
# #   }
# # 
# #   provisioner "remote-exec" {
# #     # Run docker swarm join on each slave manager node
# #     inline = [
# #       trimspace(file("./tmp/join_manager_command")),
# #     ]
# #   }
# # 
# #   depends_on = [null_resource.load_tokens, null_resource.manager_slave_cloud_init]
# # 
# # }

resource "null_resource" "linux_worker_cloud_init" {
  count = var.linux_worker_node_count
  # trigger this resouce upon worker nodes when instances finishing 
  triggers = {
    worker_node_ids = join(",", aws_instance.linux_worker_node.*.id)
  }

  #Run on each worker node
  connection {
    host        = aws_instance.linux_worker_node[count.index].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Run service restart on each node in the clutser
    script = "./scripts/wait_for_cloud_init.sh"
  }

  depends_on = [aws_instance.linux_worker_node]

}

resource "null_resource" "k8s_worker_join" {
  count = var.linux_worker_node_count

  # trigger this resouce upon worker nodes when instances finishing 
  triggers = {
    linux_worker_node_ids = join(",", aws_instance.linux_worker_node.*.id)
  }

  #Run on each worker node
  connection {
    host        = aws_instance.linux_worker_node[count.index].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Run docker swarm join on each worker node
    inline = [
      format("sudo %s", file("./tmp/join_worker_command")),
    ]
  }

  depends_on = [null_resource.load_tokens, null_resource.linux_worker_cloud_init]
}

resource "null_resource" "wait_for_ssh_in_windows" {
  count = var.windows_worker_node_count
  provisioner "remote-exec" {
    inline = [
      "Write-Host \"SSH is installed\""
    ]

    connection {
      type            = "ssh"
      host            = aws_instance.windows_worker_node[count.index].public_ip
      user            = "administrator"
      private_key     = file("~/.ssh/id_rsa")
      target_platform = "windows"
      script_path     = "c:/windows/temp/terraform_%RAND%.ps1"

      timeout = "10m" # Timeout value, e.g., 10 minutes
    }

    on_failure = continue
  }
  depends_on = [aws_instance.windows_worker_node]
}

# resource "null_resource" "wait_for_cloud_init" {
#   count = var.windows_worker_node_count
#   provisioner "remote-exec" {
#     script = "./scripts/wait_for_cloud_init.ps1"

#     connection {
#       type            = "ssh"
#       host            = aws_instance.windows_worker_node[count.index].public_ip
#       user            = "administrator"
#       private_key     = file("~/.ssh/id_rsa")
#       target_platform = "windows"
#       script_path     = "c:/windows/temp/terraform_%RAND%.ps1"

#       timeout = "10m" # Timeout value, e.g., 10 minutes
#     }
#     #Auskomentieren
#     #on_failure = continue
#   }
#   depends_on = [null_resource.wait_for_ssh_in_windows]
# }

resource "null_resource" "wait_for_cloud_init" {
  count = var.windows_worker_node_count

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -tt administrator@${aws_instance.windows_worker_node[count.index].public_ip} \"powershell.exe C:\\Windows\\Temp\\wait_for_cloud_init.ps1\""
  }
  depends_on = [null_resource.wait_for_ssh_in_windows]
}

resource "null_resource" "load_config_to_win" {
  count = var.windows_worker_node_count

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ${path.module}/tmp/config administrator@${aws_instance.windows_worker_node[count.index].public_ip}:/k/"
  }

  depends_on = [null_resource.wait_for_ssh_in_windows]
}

# resource "null_resource" "restart_node" {
#   count = var.windows_worker_node_count
#   provisioner "remote-exec" {
#     inline = [
#       "Restart-Computer -Force;",
#       "New-Item -Path \"C:\\Windows\\Temp\\computer-restarted\" -ItemType File;",
#     ]

#     connection {
#       type            = "ssh"
#       host            = aws_instance.windows_worker_node[count.index].public_ip
#       user            = "administrator"
#       private_key     = file("~/.ssh/id_rsa")
#       target_platform = "windows"
#       script_path     = "c:/windows/temp/terraform_%RAND%.ps1"

#       timeout = "10m" # Timeout value, e.g., 10 minutes
#     }
#     #Auskomentieren
#     #on_failure = continue
#   }
#   depends_on = [null_resource.wait_for_cloud_init]
# }

resource "null_resource" "restart_node" {
  count = var.windows_worker_node_count

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -tt administrator@${aws_instance.windows_worker_node[count.index].public_ip} \"powershell.exe C:\\Windows\\Temp\\restart_node.ps1\""
  }
  depends_on = [null_resource.wait_for_cloud_init]
}

resource "null_resource" "wait_for_ssh_in_windows2" {
  count = var.windows_worker_node_count
  provisioner "remote-exec" {
    inline = [
      "Write-Host \"SSH is installed\""
    ]

    connection {
      type            = "ssh"
      host            = aws_instance.windows_worker_node[count.index].public_ip
      user            = "administrator"
      private_key     = file("~/.ssh/id_rsa")
      target_platform = "windows"
      script_path     = "c:/windows/temp/terraform_%RAND%.ps1"

      timeout = "10m" # Timeout value, e.g., 10 minutes
    }

    on_failure = continue
  }
  depends_on = [null_resource.restart_node]
}

# resource "null_resource" "wait_for_restart" {
#   count = var.windows_worker_node_count
#   provisioner "remote-exec" {
#     inline = [
#       "while (!(Test-Path \"C:\\Windows\\Temp\\computer-restarted\")) { echo \"Waiting for restart...\"; sleep 1 }"
#     ]

#     connection {
#       type            = "ssh"
#       host            = aws_instance.windows_worker_node[count.index].public_ip
#       user            = "administrator"
#       private_key     = file("~/.ssh/id_rsa")
#       target_platform = "windows"
#       script_path     = "c:/windows/temp/terraform_%RAND%.ps1"

#       timeout = "10m" # Timeout value, e.g., 10 minutes
#     }
#     #Auskomentieren
#     #on_failure = continue
#   }
#   depends_on = [null_resource.wait_for_ssh_in_windows2]
# }

resource "null_resource" "wait_for_restart" {
  count = var.windows_worker_node_count

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -tt administrator@${aws_instance.windows_worker_node[count.index].public_ip} \"powershell.exe C:\\Windows\\Temp\\wait_for_restart.ps1\""
  }
  depends_on = [null_resource.wait_for_ssh_in_windows2]
}

# resource "null_resource" "setup_remote_access" {
#   count = var.windows_worker_node_count
#   provisioner "remote-exec" {
#     script = "./scripts/setup_remote_access.ps1"

#     connection {
#       type            = "ssh"
#       host            = aws_instance.windows_worker_node[count.index].public_ip
#       user            = "administrator"
#       private_key     = file("~/.ssh/id_rsa")
#       target_platform = "windows"
#       script_path     = "c:/windows/temp/terraform_%RAND%.ps1"

#       timeout = "10m" # Timeout value, e.g., 10 minutes
#     }
#     #Auskomentieren
#     #on_failure = continue
#   }
#   depends_on = [null_resource.wait_for_restart]
# }

resource "null_resource" "setup_remote_access" {
  count = var.windows_worker_node_count

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -tt administrator@${aws_instance.windows_worker_node[count.index].public_ip} \"powershell.exe C:\\Windows\\Temp\\setup_remote_access.ps1\""
  }
  depends_on = [null_resource.wait_for_restart]
}

resource "null_resource" "run_calico_install_script" {
  count = var.windows_worker_node_count

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -tt administrator@${aws_instance.windows_worker_node[count.index].public_ip} \"powershell.exe C:\\install-calico-windows.ps1\""
  }
  depends_on = [null_resource.setup_remote_access]
}

resource "null_resource" "run_kube_install_script" {
  count = var.windows_worker_node_count

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -tt administrator@${aws_instance.windows_worker_node[count.index].public_ip} \"powershell.exe C:\\CalicoWindows\\kubernetes\\install-kube-services.ps1\""
  }
  depends_on = [null_resource.run_calico_install_script]
}

# resource "null_resource" "start_kube_services" {
#   count = var.windows_worker_node_count
#   provisioner "remote-exec" {
#     script = "./scripts/start_kube_services.ps1"

#     connection {
#       type            = "ssh"
#       host            = aws_instance.windows_worker_node[count.index].public_ip
#       user            = "administrator"
#       private_key     = file("~/.ssh/id_rsa")
#       target_platform = "windows"
#       script_path     = "c:/windows/temp/terraform_%RAND%.ps1"

#       timeout = "10m" # Timeout value, e.g., 10 minutes
#     }
#     #Auskomentieren
#     #on_failure = continue
#   }
#   depends_on = [null_resource.run_kube_install_script]
# }

resource "null_resource" "start_kube_services" {
  count = var.windows_worker_node_count

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -tt administrator@${aws_instance.windows_worker_node[count.index].public_ip} \"powershell.exe C:\\Windows\\Temp\\start_kube_services.ps1\""
  }
  depends_on = [null_resource.run_kube_install_script]
}



# # resource "null_resource" "test_ssh" {
# #   count = var.windows_worker_node_count
# # 
# #   provisioner "local-exec" {
# #     command = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -tt administrator@${aws_instance.windows_worker_node[count.index].public_ip} \"Write-Host \"SSH is installed\"\""
# #   }
# #   depends_on = [aws_instance.windows_worker_node]
# # }

# # resource "null_resource" "load_firewall_script" {
# #   count = var.windows_worker_node_count
# # 
# #   provisioner "local-exec" {
# #     command = "scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ${path.module}/scripts/setup_firewall.ps1 administrator@${aws_instance.windows_worker_node[0].public_ip}:/windows/temp/"
# #   }
# # 
# #   depends_on = [aws_instance.windows_worker_node]
# # }
# # 
# # resource "null_resource" "run_firewall_script" {
# #   count = var.windows_worker_node_count
# # 
# #   provisioner "local-exec" {
# #     command = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -tt administrator@${aws_instance.windows_worker_node[count.index].public_ip} \"powershell.exe C:\\Windows\\Temp\\setup_firewall.ps1\""
# #   }
# #   depends_on = [null_resource.load_firewall_script]
# # }

# # resource "null_resource" "wait_for_computer_rename" {
# #   count = var.windows_worker_node_count
# #   provisioner "remote-exec" {
# #     inline = [
# #       <<EOT
# #       while (!(Test-Path "C:\Cloud\InitLogs\02_computer_renamed")){ 
# #         echo "Waiting for cloud-init..."
# #         sleep 1
# #       }
# #       EOT
# #       ,
# #       "Write-Host \"computer is renamed\""
# #     ]
# # 
# #     connection {
# #       type        = "ssh"
# #       host        = aws_instance.windows_worker_node[count.index].public_ip
# #       user        = "administrator"
# #       private_key = file("~/.ssh/id_rsa")
# #       target_platform = "windows"
# #       script_path = "c:/windows/temp/terraform_%RAND%.ps1"
# # 
# #       timeout = "10m"  # Timeout value, e.g., 10 minutes
# #     }
# #   }
# #   depends_on = [null_resource.set_firewall]
# # }
# # 
# # resource "null_resource" "wait_for_all_traffic_allowed" {
# #   count = var.windows_worker_node_count
# #   provisioner "remote-exec" {
# #     inline = [
# #       <<EOT
# #       while (!(Test-Path "C:\Cloud\InitLogs\03_all_traffic_allowed")){ 
# #         echo "Waiting for cloud-init..."
# #         sleep 1
# #       }
# #       EOT
# #       ,
# #       "Write-Host \"all traffic is allowed\""
# #     ]
# # 
# #     connection {
# #       type        = "ssh"
# #       host        = aws_instance.windows_worker_node[count.index].public_ip
# #       user        = "administrator"
# #       private_key = file("~/.ssh/id_rsa")
# #       target_platform = "windows"
# #       script_path = "c:/windows/temp/terraform_%RAND%.ps1"
# # 
# #       timeout = "10m"  # Timeout value, e.g., 10 minutes
# #     }
# #   }
# #   depends_on = [null_resource.wait_for_computer_rename]
# # }
# # 
# # resource "null_resource" "wait_for_all_containerd_installed" {
# #   count = var.windows_worker_node_count
# #   provisioner "remote-exec" {
# #     inline = [
# #       <<EOT
# #       while (!(Test-Path "C:\Cloud\InitLogs\04_containerd_installed")){ 
# #         echo "Waiting for cloud-init..."
# #         sleep 1
# #       }
# #       EOT
# #       ,
# #       "Write-Host \"containerd is installed\""
# #     ]
# # 
# #     connection {
# #       type        = "ssh"
# #       host        = aws_instance.windows_worker_node[count.index].public_ip
# #       user        = "administrator"
# #       private_key = file("~/.ssh/id_rsa")
# #       target_platform = "windows"
# #       script_path = "c:/windows/temp/terraform_%RAND%.ps1"
# # 
# #       timeout = "10m"  # Timeout value, e.g., 10 minutes
# #     }
# #   }
# #   depends_on = [null_resource.wait_for_all_traffic_allowed]
# # }
# # 
# # resource "null_resource" "wait_for_calico_script_downloaded" {
# #   count = var.windows_worker_node_count
# #   provisioner "remote-exec" {
# #     inline = [
# #       <<EOT
# #       while (!(Test-Path "C:\Cloud\InitLogs\08_calico_script_downloaded")){ 
# #         echo "Waiting for cloud-init..."
# #         sleep 1
# #       }
# #       EOT
# #       ,
# #       "Write-Host \"calico script is downloaded\""
# #     ]
# # 
# #     connection {
# #       type        = "ssh"
# #       host        = aws_instance.windows_worker_node[count.index].public_ip
# #       user        = "administrator"
# #       private_key = file("~/.ssh/id_rsa")
# #       target_platform = "windows"
# #       script_path = "c:/windows/temp/terraform_%RAND%.ps1"
# # 
# #       timeout = "10m"  # Timeout value, e.g., 10 minutes
# #     }
# #   }
# #   depends_on = [null_resource.wait_for_all_containerd_installed]
# # }
# # 
# # resource "null_resource" "wait_for_calico_script_changed" {
# #   count = var.windows_worker_node_count
# #   provisioner "remote-exec" {
# #     inline = [
# #       <<EOT
# #       while (!(Test-Path "C:\Cloud\InitLogs\09_calico_script_changed")){ 
# #         echo "Waiting for cloud-init..."
# #         sleep 1
# #       }
# #       EOT
# #       ,
# #       "Write-Host \"calico script is changed\""
# #     ]
# # 
# #     connection {
# #       type        = "ssh"
# #       host        = aws_instance.windows_worker_node[count.index].public_ip
# #       user        = "administrator"
# #       private_key = file("~/.ssh/id_rsa")
# #       target_platform = "windows"
# #       script_path = "c:/windows/temp/terraform_%RAND%.ps1"
# # 
# #       timeout = "10m"  # Timeout value, e.g., 10 minutes
# #     }
# #   }
# #   depends_on = [null_resource.wait_for_calico_script_downloaded]
# # }
# # 
# # resource "null_resource" "wait_for_scedule_task_created" {
# #   count = var.windows_worker_node_count
# #   provisioner "remote-exec" {
# #     inline = [
# #       <<EOT
# #       while (!(Test-Path "C:\Cloud\InitLogs\10_scedule_task_created")){ 
# #         echo "Waiting for cloud-init..."
# #         sleep 1
# #       }
# #       EOT
# #       ,
# #       "Write-Host \"scedule task is created\""
# #     ]
# # 
# #     connection {
# #       type        = "ssh"
# #       host        = aws_instance.windows_worker_node[count.index].public_ip
# #       user        = "administrator"
# #       private_key = file("~/.ssh/id_rsa")
# #       target_platform = "windows"
# #       script_path = "c:/windows/temp/terraform_%RAND%.ps1"
# # 
# #       timeout = "10m"  # Timeout value, e.g., 10 minutes
# #     }
# #   }
# #   depends_on = [null_resource.wait_for_calico_script_changed]
# # }
# # 
# # # resource "null_resource" "wait_for_computer_restarted" {
# # #   count = var.windows_worker_node_count
# # #   provisioner "remote-exec" {
# # #     inline = [
# # #       <<EOT
# # #       while (!(Test-Path "C:\computer_restarted")){ 
# # #         echo "Waiting for cloud-init..."
# # #         sleep 1
# # #       }
# # #       EOT
# # #       ,
# # #       "Write-Host \"computer is restarted\""
# # #     ]
# # # 
# # #     connection {
# # #       type        = "ssh"
# # #       host        = aws_instance.windows_worker_node[count.index].public_ip
# # #       user        = "administrator"
# # #       private_key = file("~/.ssh/id_rsa")
# # #       target_platform = "windows"
# # #       script_path = "c:/windows/temp/terraform_%RAND%.ps1"
# # # 
# # #       timeout = "10m"  # Timeout value, e.g., 10 minutes
# # #     }
# # #   }
# # #   depends_on = [null_resource.wait_for_scedule_task_created]
# # # }
# # 
# # # resource "null_resource" "install_calico" {
# # #   count = var.windows_worker_node_count
# # #   provisioner "remote-exec" {
# # #     inline  = ["powershell.exe \"Set-ExecutionPolicy Bypass -Scope Process -Force;C:\\install-calico-windows.ps1 -KubeVersion 1.27.3 -CalicoBackend windows-bgp\""]
# # #     # interpreter = ["PowerShell"]
# # # 
# # #     connection {
# # #       type        = "ssh"
# # #       host        = aws_instance.windows_worker_node[count.index].public_ip
# # #       user        = "administrator"
# # #       private_key = file("~/.ssh/id_rsa")
# # #       target_platform = "windows"
# # #       script_path = "c:/windows/temp/terraform_%RAND%.ps1"
# # # 
# # #       timeout = "10m"  # Timeout value, e.g., 10 minutes
# # #     }
# # #   }
# # #   depends_on = [null_resource.wait_for_calico_script_downloaded]
# # # }
# # 
# # resource "null_resource" "install_calico2" {
# #   count = var.windows_worker_node_count
# #   provisioner "local-exec" {
# #     command = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -tt administrator@${aws_instance.windows_worker_node[count.index].public_ip} \"setx NODENAME \"c1-win-node${count.index + 1}\";cd C:\\;.\\install-calico-windows.ps1 -KubeVersion 1.27.3 -CalicoBackend windows-bgp\""
# #   }
# # #   depends_on = [null_resource.wait_for_computer_restarted]
# #   depends_on = [null_resource.wait_for_scedule_task_created]
# # }
# # 
# # resource "null_resource" "install_kube_services" {
# #   count = var.windows_worker_node_count
# #   provisioner "local-exec" {
# #     command = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -tt administrator@${aws_instance.windows_worker_node[count.index].public_ip} \"C:\\CalicoWindows\\kubernetes\\install-kube-services.ps1\""
# #   }
# #   depends_on = [null_resource.install_calico2]
# # }
# # 
# # resource "null_resource" "run_kube_services" {
# #   count = var.windows_worker_node_count
# #   provisioner "remote-exec" {
# #     inline = [
# #       "Start-Service -Name kubelet;",
# #       "Start-Service -Name kube-proxy;",
# #       "cp C:\\k\\*.exe C:\\Users\\Administrator\\AppData\\Local\\Microsoft\\WindowsApps | Out-Null;",
# #       "cp C:\\k\\config ~\\.kube\\ | Out-Null;",
# #       "Write-Host \"kube services are running\""
# #     ]
# # 
# #     connection {
# #       type        = "ssh"
# #       host        = aws_instance.windows_worker_node[count.index].public_ip
# #       user        = "administrator"
# #       private_key = file("~/.ssh/id_rsa")
# #       target_platform = "windows"
# #       script_path = "c:/windows/temp/terraform_%RAND%.ps1"
# # 
# #       timeout = "10m"  # Timeout value, e.g., 10 minutes
# #     }
# #   }
# #   depends_on = [null_resource.install_kube_services]
# # }
# # 
# # # resource "null_resource" "windows_worker_cloud_init" {
# # #   count = var.windows_worker_node_count
# # #   # trigger this resouce upon worker nodes when instances finishing 
# # #   triggers = {
# # #     worker_node_ids = join(",", aws_instance.windows_worker_node.*.id)
# # #   }
# # # 
# # # #  #Run on each worker node
# # # #  connection {
# # # #    host        = aws_instance.windows_worker_node[count.index].public_ip
# # # #    type        = "ssh"
# # # #    user        = "administrator"
# # # #    private_key = file(pathexpand("~/.ssh/id_rsa"))
# # # #  }
# # # #
# # # #  provisioner "remote-exec" {
# # # #    # Check init status on each node in the clutser
# # # #    # script = "./scripts/wait_for_cloud_init.bat"
# # # #    inline = [
# # # #     "while (!(Test-Path \"C:\\ClodInitLogs\\boot-finished\")){ echo \"Waiting for cloud-init...\"; sleep 1 }"
# # # #   ]
# # # #
# # # #  }
# # # 
# # #   provisioner "remote-exec" {
# # # #    command = "C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Scripts\\InitializeInstance.ps1 -Schedule",
# # #     inline = ["while (!(Test-Path \"C:\\ClodInitLogs\\boot-finished\")){ echo \"Waiting for cloud-init...\"; sleep 1 }"]
# # #     connection {
# # #       type     = "winrm"
# # #       host = aws_instance.windows_worker_node[count.index].public_ip
# # #       user     = "Administrator"
# # #       password = "j2FPrf5jVw$;Uas66A.;4U?ustztsTrl"
# # #     }
# # #   }
# # #   depends_on = [aws_instance.windows_worker_node]
# # # 
# # # }
# # 
# # # resource "null_resource" "put_config_on_windows_worker_node" {
# # #   count = var.windows_worker_node_count
# # #   # trigger this resouce upon leader windows worker nodes when instances finishing 
# # #   triggers = {
# # #     windows_worker_node_ids = join(",", aws_instance.windows_worker_node.*.id)
# # #   }
# # # 
# # #   provisioner "local-exec" {
# # #     command = "scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -r ${path.module}/tmp/config administrator@${aws_instance.windows_worker_node[count.index].public_ip}:C:\\k"
# # #   }
# # # 
# # # #  depends_on = [null_resource.load_config, null_resource.windows_worker_cloud_init]
# # #   depends_on = [null_resource.load_config]
# # # 
# # # }
# # 
# # # resource "null_resource" "example" {
# # #   count = var.windows_worker_node_count
# # #   provisioner "remote-exec" {
# # #     inline = [
# # #        "echo 'Hello World!' > C:\\Users\\Administrator\\moi_test2.txt", 
# # # #      "powershell.exe -ExecutionPolicy Bypass -File path/to/script.ps1",
# # # #      "powershell.exe -ExecutionPolicy Bypass -File path/to/script.ps1"
# # #     ]
# # # 
# # #     connection {
# # #       type        = "winrm"
# # #       host        = aws_instance.windows_worker_node[count.index].public_ip
# # #       user        = "Administrator"
# # #       password    = rsadecrypt(aws_instance.windows_worker_node[count.index].password_data, file(pathexpand("~/.ssh/id_rsa")))
# # #       insecure    = true
# # #     }
# # #   }
# # # }
# # 
# # # resource "null_resource" "example2" {
# # #   count = var.windows_worker_node_count
# # #   provisioner "remote-exec" {
# # #     inline = [
# # #       "echo 'Hello World!' > C:\\Users\\Administrator\\moi_test2.txt", 
# # # #      "powershell.exe -ExecutionPolicy Bypass -File path/to/script.ps1",
# # # #      "powershell.exe -ExecutionPolicy Bypass -File path/to/script.ps1"
# # #     ]
# # # 
# # #   connection {
# # #     host        = aws_instance.windows_worker_node[count.index].public_ip
# # #     type        = "ssh"
# # #     user        = "administrator"
# # #     private_key = file(pathexpand("~/.ssh/id_rsa"))
# # #   }
# # #   }
# # # }
# # 
# # # resource "null_resource" "example3" {
# # #   count = var.windows_worker_node_count
# # #   provisioner "local-exec" {
# # # #    command = "echo '${templatefile("${path.module}/startup_windows_script.tpl", { hostname = "c1-win-node${count.index + 1}", configfile = file("./tmp/config")})}' > ${path.module}/tmp/output.txt"
# # #     command = "echo '${templatefile("${path.module}/tmp/test.tpl", { configfile = file("./tmp/config") })}' > ${path.module}/tmp/output.txt"
# # #   }
# # # 
# # #   triggers = {
# # #     template_hash = filesha256("${path.module}/startup_windows_script.tpl")
# # #   }
# # # }
# # 
# # 

resource "null_resource" "creatre_secret" {

  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Initialize the clutser
    # inline = ["mysql --host=${aws_db_instance.db.address} --port=${aws_db_instance.db.port} --user=${aws_db_instance.db.username} --password=${aws_db_instance.db.password} < ~/schema.sql"]
    inline = ["kubectl create secret generic my-secret --from-literal=HOST=${aws_db_instance.db.address} --from-literal=PORT=${aws_db_instance.db.port} --from-literal=NAME=${aws_db_instance.db.db_name} --from-literal=USERNAME=${aws_db_instance.db.username} --from-literal=PASSWORD='${aws_db_instance.db.password}'"]
  }

  depends_on = [null_resource.k8s_cluster_setup]

}

resource "null_resource" "pod_yaml" {
  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  # Define the file provisioner block.
  provisioner "file" {
    source      = "./scripts/my-first-pod.yml"
    destination = "my-first-pod.yml"
  }
  depends_on = [null_resource.creatre_secret]
}

resource "null_resource" "pod_setup" {

  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Initialize the clutser
    inline = ["kubectl apply -f my-first-pod.yml"]
  }

  depends_on = [null_resource.pod_yaml]

}

resource "null_resource" "pod_yaml_win" {
  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  # Define the file provisioner block.
  provisioner "file" {
    source      = "./scripts/my-first-pod-win.yml"
    destination = "my-first-pod-win.yml"
  }
  depends_on = [null_resource.creatre_secret]
}

resource "null_resource" "pod_setup_win" {

  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Initialize the clutser
    inline = ["kubectl apply -f my-first-pod-win.yml"]
  }

  depends_on = [null_resource.pod_yaml]

}

resource "null_resource" "restart_coredns" {

  #Run on control plane (master) node (the first one)
  connection {
    host        = aws_instance.control_plane_node[0].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_rsa"))
  }

  provisioner "remote-exec" {
    # Initialize the clutser
    inline = ["kubectl rollout restart -n kube-system deployment/coredns"]
  }

  depends_on = [null_resource.pod_setup]

}
