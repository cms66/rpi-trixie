# Declare menus - Option 0 used for menu title

declare -a mnuMainFull=(
"Setup - Main menu#"
"Hardware#show_menu mnuHardwareFull"
"NFS#show_menu mnuNFSFull"
"Cluster#show_menu mnuClusterFull"
"OpenCV#show_menu mnuOpenCVFull"
"SDM#show_menu mnuSDMFull"
"Update setup#git_pull_setup"
"Update system#update_system"
"System summary#show_system_summary"
"SSH keys#show_menu mnuSSHFull"
"Quit#break 2"
)
declare -a mnuHardwareFull=(
"Setup - Hardware menu#"
"Camera - CSI#setup_camera_csi"
"Camera - USB#setup_camera_usb"
"I2C#setup_i2c"
"GPS#setup_gps"
"PCIe#setup_pcie"
"Hailo-8#setup_hailo"
"Back#break 2"
)
declare -a mnuNFSFull=(
"Setup - NFS menu#"
"Install - NFS - Server#install_nfs_server"
"Add NFS local export#add_nfs_local"
"Add NFS remote mount#add_nfs_remote"
"Back#break 2"
)
declare -a mnuClusterFull=(
"Setup - Cluster menu#"
"Install - Slurm - Local#install_slurm_local"
"Install - Slurm - Client#install_slurm_client"
"Install - OpenMPI - Local#install_openmpi_local"
"Install - OpenMPI - Server#install_server"
"Install - OpenMPI - Client#install_openmpi_client"
"Setup - Munge - Shared key#setup_munge_key"
"Back#break 2"
)
declare -a mnuOpenCVFull=(
"Setup - OpenCV menu#"
"Install - Local#install_opencv_local"
"Install - Server#install_server"
"Install - Client#install_opencv_client"
"Back#break 2"
)
declare -a mnuSDMFull=(
"Setup - SDM menu#init_sdm"
"Install - SDM - Local#install_sdm_local"
"Install - SDM - Server#install_server"
"Download latest images#download_latest_os_images"
"Modify image#modify_sdm_image"
"Burn image#burn_sdm_image"
"Explore image#explore_sdm_image"
"Edit configuration#edit_sdm_config"
"Show configuration#show_sdm_config"
"Back#break 2"
)
declare -a mnuSSHFull=(
"Setup - SSH menu#"
"Create user keys#create_user_ssh_keys"
"Copy user key to host#copy_user_ssh_keys"
"Back#break 2"
)
