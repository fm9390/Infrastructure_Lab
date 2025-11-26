VMID=9001
VMNAME="ubuntu-24-04-ci-template"
NODE="pve"
BRIDGE="vmbr0"
STORAGE_SSD="local-lvm"
STORAGE_ISO="local"

cd /tmp
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

qm create $VMID --name $VMNAME --memory 2048 --cores 2 --sockets 1 --cpu x86-64-v2-AES \
  --net0 virtio,bridge=$BRIDGE --ostype l26

qm importdisk $VMID noble-server-cloudimg-amd64.img $STORAGE_SSD
qm set $VMID --scsihw virtio-scsi-pci --scsi0 ${STORAGE_SSD}:vm-$VMID-disk-0
qm set $VMID --ide2 ${STORAGE_ISO}:cloudinit
qm set $VMID --boot order=scsi0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --agent enabled=1
qm resize $VMID scsi0 20G
qm template $VMID
