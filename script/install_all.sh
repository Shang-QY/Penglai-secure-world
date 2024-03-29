while getopts "d:" arg
do
    case $arg in
        d)
        DEVICE=$OPTARG
        ;;
        ?)
        echo "unkonw argument"
        exit 1
        ;;
    esac
done

if [ ! $DEVICE ]
then
    DEVICE=/dev/sda
fi
echo "SD card device: $DEVICE"
if [ ! -e $DEVICE ]
then
    echo 'Device not found!'
    exit 1
fi
BOOT_PARTITION=$DEVICE"3"
ROOTFS_PARTITION=$DEVICE"4"

if test -z "$SECURE_WORLD_DIR";then
	echo "SECURE_WORLD_DIR is null string"
    exit 1
else
	echo $SECURE_WORLD_DIR
fi

cd $SECURE_WORLD_DIR
mkdir -p $SECURE_WORLD_DIR/disk
mkdir -p $SECURE_WORLD_DIR/disk/__boot
mkdir -p $SECURE_WORLD_DIR/disk/__

# install normal linux
sudo mount $BOOT_PARTITION $SECURE_WORLD_DIR/disk/__boot
# sudo cat > $SECURE_WORLD_DIR/out/grub.cfg <<EOF
# set default=0
# set timeout_style=menu
# set timeout=2

# set debug="linux,loader,mm"
# set term="vt100"

# menuentry 'boot_by_UART1 plic_hart0 no_network Fedora_with_modules reserved_payload linux-5.15.10 visionfive' {
#     linux /fedora_with_modules.gz ro root=UUID=59fcd098-2f22-441a-ba45-4f7185baf23f rhgb console=tty0 console=ttyS2,115200 earlycon rootwait stmmaceth=chain_mode:1 selinux=0 LANG=en_US.UTF-8
#     devicetree /dtbs/5.15.10+/starfive/visionfive-v1-uart-reserved-plic-nonet.dtb
#         initrd /initramfs-5.15.10+.img
# }
# EOF
sudo cp $SECURE_WORLD_DIR/out/uboot/grub.cfg $SECURE_WORLD_DIR/disk/__boot/
sudo cp $SECURE_WORLD_DIR/out/normal_linux/kernel/fedora_with_modules.gz $SECURE_WORLD_DIR/disk/__boot/
sudo cp $SECURE_WORLD_DIR/out/normal_linux/kernel/visionfive-v1-uart-reserved-plic-nonet.dtb $SECURE_WORLD_DIR/disk/__boot/dtbs/5.15.10+/starfive/
sudo sync
sudo umount $SECURE_WORLD_DIR/disk/__boot/
echo 'Transfer normal linux successfully!'

# install sdk, driver and secure linux
sudo mount $ROOTFS_PARTITION $SECURE_WORLD_DIR/disk/__
# sudo cat > $SECURE_WORLD_DIR/out/riscv/run.sh <<EOF
# cd new_sec
# sudo insmod penglai_linux.ko
# ./host sec-image sec-dtb.dtb
# EOF
sudo cp $SECURE_WORLD_DIR/out/normal_linux/sdk/run.sh $SECURE_WORLD_DIR/disk/__/home/riscv/run.sh
sudo chmod a+x $SECURE_WORLD_DIR/disk/__/home/riscv/run.sh

sudo mkdir -p $SECURE_WORLD_DIR/disk/__/home/riscv/new_sec
sudo cp $SECURE_WORLD_DIR/out/normal_linux/sdk/host $SECURE_WORLD_DIR/disk/__/home/riscv/new_sec/
sudo cp $SECURE_WORLD_DIR/out/normal_linux/sdk/remote $SECURE_WORLD_DIR/disk/__/home/riscv/new_sec/
sudo cp $SECURE_WORLD_DIR/out/normal_linux/driver/penglai_linux.ko $SECURE_WORLD_DIR/disk/__/home/riscv/new_sec/

sudo cp $SECURE_WORLD_DIR/out/secure_linux/sec-image $SECURE_WORLD_DIR/disk/__/home/riscv/new_sec/
sudo cp $SECURE_WORLD_DIR/out/secure_linux/sec-dtb.dtb $SECURE_WORLD_DIR/disk/__/home/riscv/new_sec/
sudo cp $SECURE_WORLD_DIR/out/secure_linux/css-file $SECURE_WORLD_DIR/disk/__/home/riscv/new_sec/
echo 'stat sec-image'
sudo stat $SECURE_WORLD_DIR/disk/__/home/riscv/new_sec/sec-image
echo 'stat sec-dtb.dtb'
sudo stat $SECURE_WORLD_DIR/disk/__/home/riscv/new_sec/sec-dtb.dtb
sudo sync
sudo umount $SECURE_WORLD_DIR/disk/__/
echo 'Transfer secure linux successfully!'
