#!/bin/bash
IFS_BAK=${IFS}
# IFS=$(echo -en "\n\b")
IFS=$'\n'
GREEN="\033[32m"
YELLOW="\033[33m"
END='\033[0m'
echo -e "${GREEN}本脚本仅仅为 树莓派系列适配，其他环境，可以魔改爆改本脚本，从而达成你的目的
树莓派 pi1 pi2 pi3 不传入任何参数则默认为 pi1
命令使用方法，比如模拟 pi3 则命令为 bash initdir-raspberry.sh pi3${END}"
TARGET="${1:-pi1}"

echo -e "${YELLOW}首先安装 p7zip 和 gptfdisk 或 fdisk 不过termux不支持 fdisk 可惜
${GREEN}# MacOS
${YELLOW}brew update --auto-update ; brew install aria2 wget curl p7zip gptfdisk ossp-uuid qemu git
${GREEN}# termux os
${YELLOW}pkg install -y qemu-utils aria2 wget curl p7zip fdisk ossp-uuid qemu-system-aarch64-headless qemu-system-arm-headless git
${GREEN}# alpine os
${YELLOW}sudo apk add aria2 wget curl 7zip qemu-system-aarch64 qemu-system-arm qemu-img gptfdisk ossp-uuid git
${GREEN}# debian os
${YELLOW}sudo apt-get install -y qemu-utils aria2 wget curl p7zip fdisk uuid qemu-system-arm qemu-system-aarch64 git${END}"

echo -e "${GREEN}"
read -rp "准备好了吗？回车开始！(ctrl + c 退出)" others
echo "·${others}·"
# 是否改变镜像空间大小 0不改 1改
RESIZE_FLAG="1"
# 基本度量衡1G大小，不可变
GIB_IN_BYTES="1073741824"
# 扩展磁盘8GB大小，自定义
RESIZE_GIBYTES="8"
# 下载镜像类型
FILE_TYPE=".img.xz"
# 解压后文件类型
QEMU_TYPE1="img"
# 转化磁盘类型
QEMU_TYPE2="qcow2"
# 转化镜像类型 ，最终启动镜像， QEMU_TYPE1 to QEMU_TYPE2
QEMU_TYPES="${QEMU_TYPE2}"
# 镜像下载地址和sha256sum校验，自定义
IMG_URL_BAK="https://downloads.raspberrypi.com/raspios_armhf/images/raspios_armhf-2024-03-15/2024-03-15-raspios-bookworm-armhf${FILE_TYPE}"
IMG_URL_CHECKSUM_BAK="52a807d37a894dfcb09274382762f8274c7044ce3d98040aba474e0af93b85ab"

IMG_URL="https://downloads.raspberrypi.com/raspios_armhf/images/raspios_armhf-2023-05-03/2023-05-03-raspios-bullseye-armhf${FILE_TYPE}"
IMG_URL_CHECKSUM="38a66ed777a1f4e4c07f7dcb2b2feadfda4503d5e139f675758e0e91d34ed75f"

IMG_URL_BAK="https://downloads.raspberrypi.com/raspios_arm64/images/raspios_arm64-2023-05-03/2023-05-03-raspios-bullseye-arm64${FILE_TYPE}"
IMG_URL_CHECKSUM_BAK="e7c0c89db32d457298fbe93195e9d11e3e6b4eb9e0683a7beb1598ea39a0a7aa"

# 判断链接位数以及传入变量参数
if [[ "${IMG_URL}" =~ "arm64" ]] && [ "${TARGET}" != "pi3" ]; then
    echo " ${TARGET} 不能使用 64 位，强制改初始变量为支持 64 位的 pi3 "
    TARGET=pi3
fi

# https://github.com/dhruvvyas90/qemu-rpi-kernel
# debian qemu-rpi-kernel文件，其他支持请自行搜索 kernrl
# debian qemu-rpi-dtb文件，其他支持请自行搜索 dtb
QEMU_RPI_KERNEL_URL_BAK="https://cdn.jsdelivr.net/gh/dhruvvyas90/qemu-rpi-kernel@master/kernel-qemu-5.10.63-bullseye"
QEMU_RPI_DTB_URL_BAK="https://cdn.jsdelivr.net/gh/dhruvvyas90/qemu-rpi-kernel@master/versatile-pb-bullseye-5.10.63.dtb"
QEMU_RPI_KERNEL_URL="https://cdn.jsdelivr.net/gh/dhruvvyas90/qemu-rpi-kernel@master/kernel-qemu-5.4.51-buster"
QEMU_RPI_DTB_URL="https://cdn.jsdelivr.net/gh/dhruvvyas90/qemu-rpi-kernel@master/versatile-pb-buster-5.4.51.dtb"
QEMU_RPI_KERNEL_FILE="$(basename ${QEMU_RPI_KERNEL_URL})"
QEMU_RPI_DTB_FILE="$(basename ${QEMU_RPI_DTB_URL})"

# 得到压缩文件名
FILENAME=$(basename $IMG_URL)

# 去除压缩包扩展得到文件名
NAME=$(basename $FILENAME $FILE_TYPE)
# 拼接虚拟机专属目录
TMP_DIR=$(pwd)/${NAME}-${TARGET}
# 创建文件夹，这个自己定义
mkdir -pv ${TMP_DIR}
# 创建临时目录用于存放解压文件
mkdir -pv ${TMP_DIR}/${NAME}
# 创建一个专门存放 .img .dtb cmdline.txt fstab 文件的地方
mkdir -pv "${TMP_DIR}/${NAME}kd"

cd ${TMP_DIR} ; bash deldir.sh ; cd -

echo -e "默认下载链接 ${IMG_URL} 
默认下载路径 ${TMP_DIR}"

# 判断 ${TMP_DIR}/${NAME}kd/${QEMU_RPI_KERNEL_FILE} 和 ${TMP_DIR}/${NAME}kd/${QEMU_RPI_DTB_FILE} 文件是否存在
if [ ! -e "${TMP_DIR}/${NAME}kd/${QEMU_RPI_KERNEL_FILE}" ] && [ ! -e "${TMP_DIR}/${NAME}kd/${QEMU_RPI_DTB_FILE}" ]; then
    echo "文件不存在开始下载 ${TMP_DIR}/${NAME}kd/${QEMU_RPI_KERNEL_FILE} 和 ${TMP_DIR}/${NAME}kd/${QEMU_RPI_DTB_FILE} ..."
    aria2c -d "${TMP_DIR}/${NAME}kd/" "${QEMU_RPI_KERNEL_URL}" -o "${QEMU_RPI_KERNEL_FILE}"
    aria2c -d "${TMP_DIR}/${NAME}kd/" "${QEMU_RPI_DTB_URL}" -o "${QEMU_RPI_DTB_FILE}"
fi

# 判断镜像解压文件是否存在
if [ ! -f "${TMP_DIR}/${FILENAME}" ]; then
    # 文件不存在，因此需要下载它
    echo -e "文件不存在开始下载 ${TMP_DIR}/${FILENAME} ..."
    aria2c -d "${TMP_DIR}/" "${IMG_URL}" -o "${FILENAME}"
    # 计算文件的实际SHA256值
    ACTUAL_SUM=$(sha256sum "${TMP_DIR}/${FILENAME}" | awk '{ print $1 }')
    if [ "$IMG_URL_CHECKSUM" = "$ACTUAL_SUM" ]; then
      # 解压
      echo "sha256sum校验通过，下载完成并解压 ${TMP_DIR}/${FILENAME} ..."
      7z x -y -o"${TMP_DIR}" "${TMP_DIR}/${FILENAME}"
    else
      echo "sha256sum校验不通过，请检查网络或校验铭文，退出"
      exit 1
    fi
fi

# 计算文件的实际SHA256值
ACTUAL_SUM=$(sha256sum "${TMP_DIR}/${FILENAME}" | awk '{ print $1 }')

# 比较预期和实际的SHA256值
if [ "$IMG_URL_CHECKSUM" = "$ACTUAL_SUM" ]; then
    # SHA256值匹配，因此可以提取镜像
    # 解压
    echo "sha256sum校验通过，找到并解压 ${TMP_DIR}/${FILENAME} ..."
    7z x -y -o"${TMP_DIR}" "${TMP_DIR}/${FILENAME}"
else
    # SHA256值不匹配，因此需要再次下载文件
    echo -e "SHA256值检查失败。正在重新下载 ${TMP_DIR}/${FILENAME} ..."
    aria2c -d "${TMP_DIR}/" "${IMG_URL}" -o "${FILENAME}"
    # 计算文件的实际SHA256值
    ACTUAL_SUM=$(sha256sum "${TMP_DIR}/${FILENAME}" | awk '{ print $1 }')
    if [ "$IMG_URL_CHECKSUM" = "$ACTUAL_SUM" ]; then
      # 解压
      echo "sha256sum校验通过，下载完成并解压 ${TMP_DIR}/${FILENAME} ..."
      7z x -y -o"${TMP_DIR}" "${TMP_DIR}/${FILENAME}"
    else
      echo "sha256sum校验不通过，请检查网络或校验铭文，退出"
      exit 2
    fi
fi

# 删除压缩包，这里注释代表不删除，毕竟下载不易
#rm -fv ${TMP_DIR}/${FILENAME}

# MACOS挂载指令，LinuxOS请跳过
# hdiutil mount "${NAME}.${QEMU_TYPE1}" -section 8192  -mountpoint  "${TMP_DIR}/${NAME}/${NAME}"

# 复制内核文件
# cp -r ${TMP_DIR}/${NAME}/${NAME}/*.img* ${TMP_DIR}/${NAME}kd/

# 复制 dtb 文件
# cp -r ${TMP_DIR}/${NAME}/${NAME}/*.dtb ${TMP_DIR}/${NAME}kd/

# 复制 vmlinuz 文件
# cp -r ${TMP_DIR}/${NAME}/${NAME}/*vmlinuz* ${TMP_DIR}/${NAME}kd/

# 如果用的是MACOS系统，那你直接就可以接触挂载，但是linux不支持，真是够了
# hdiutil unmount "${TMP_DIR}/${NAME}/${NAME}"

# LinuxOS无法直接挂载，但是，可以用7z解压指令解压的方式提取，虽然很暴力
# 看看你镜像的分区内容，其实没啥用，毕竟termux连mount命令都会报错，offset用不了，真是够了。
gdisk -l  "${TMP_DIR}/${NAME}.${QEMU_TYPE1}"

# 解压，这里一般只要树莓派不改变镜像结构，那就会得到两个文件 0.fat 和 1.img
7z -y x "${TMP_DIR}/${NAME}.${QEMU_TYPE1}" -o"${TMP_DIR}/${NAME}/" "0.fat"

# 解压 0.fat 提取文件 .dtb .img cmdline.txt config.txt
7z -y x "${TMP_DIR}/${NAME}/0.fat" -o"${TMP_DIR}/${NAME}kd/" "*.dtb"
7z -y x "${TMP_DIR}/${NAME}/0.fat" -o"${TMP_DIR}/${NAME}kd/" "*.img"
7z -y x "${TMP_DIR}/${NAME}/0.fat" -o"${TMP_DIR}/${NAME}kd/" "*vmlinuz*"
7z -y x "${TMP_DIR}/${NAME}/0.fat" -o"${TMP_DIR}/${NAME}kd/" "cmdline.txt"

# LinuxOS最后把一些解压没用的材料删除吧
rm -rfv "${TMP_DIR}/${NAME}"

# "转化 QEMU_TYPE1 为 QEMU_TYPE2 动态磁盘，这一步耐心点 ..."
if [ "${QEMU_TYPES}" = "${QEMU_TYPE2}" ];then
    echo "转化 ${QEMU_TYPE1} 为 ${QEMU_TYPE2} 动态磁盘，这一步耐心点 ..."
    rm -fv "${TMP_DIR}/${NAME}.${QEMU_TYPE2}"
    qemu-img convert -f $(if [ "${QEMU_TYPE1}" = "img" ] ; then  echo raw ; else echo ${QEMU_TYPE1} ; fi) -O ${QEMU_TYPE2} "${TMP_DIR}/${NAME}.${QEMU_TYPE1}" "${TMP_DIR}/${NAME}.${QEMU_TYPE2}"
fi

# 修改镜像大小为2的倍数，这是qemu限制的，没办法，这个单位是byte，最好添加到8GB
# 查看镜像信息，将8G*1024*1024*1024乘得的byte单位的值-镜像本身查询到的byte值，比如最终得到的值为 8589934592 记住这个值，到时候扩展磁盘用得上
# 将得到的值扩容到该镜像里，在察看一遍信息确认一下，带回进入虚拟机调整容量，
if [[ "${RESIZE_FLAG}" != "0" ]]; then
  echo "查看镜像信息 ${TMP_DIR}/${NAME}.${QEMU_TYPES}"
  qemu-img info "${TMP_DIR}/${NAME}.${QEMU_TYPES}"
  NUM=$(qemu-img info --output json "${TMP_DIR}/${NAME}.${QEMU_TYPES}" | grep "virtual-size" | tail -n 1 | awk '{print $2}' | sed 's/,//')
  if [[ "$(($NUM % ($GIB_IN_BYTES * 2)))" != "0" ]]; then
    NEW_NUM=$((($NUM / ($GIB_IN_BYTES * 2) + 1) * 2))
    echo "Rounding image size up to ${NEW_NUM}GiB so it's a multiple of 2GiB..."
    qemu-img resize -f $(if [ "${QEMU_TYPES}" = "img" ] ; then  echo raw ; else echo ${QEMU_TYPES} ; fi) --shrink "${TMP_DIR}/${NAME}.${QEMU_TYPES}" +$((${RESIZE_GIBYTES}*${GIB_IN_BYTES}-${NUM}))
  fi
  echo "查看处理后镜像信息 ${TMP_DIR}/${NAME}.${QEMU_TYPES}"
  qemu-img info "${TMP_DIR}/${NAME}.${QEMU_TYPES}"
fi

# 看看 kernel and dtb
ls -al "${TMP_DIR}/${NAME}kd/"

# 清理替换 cmdline.txt 内容
CMDLINE=$(cat "${TMP_DIR}/${NAME}kd/cmdline.txt" | sed -e 's/root=PARTUUID=[^ ]* //' -e 's/init=\/usr\/lib\/raspberrypi-sys-mods\/firstboot //')
echo "###please first resise ${QEMU_TYPE2}###"

# qemu树莓派支持名: raspi0 支持的树莓派类型: 树莓派Zero、树莓派Zero W 树莓派cpu: ARM1176JZF-S，cpu核心数: 1核心 最大内存: 512MB
# qemu树莓派支持名: raspi1ap 支持的树莓派类型: 树莓派1代A+ 树莓派cpu: ARM11，cpu核心数: 1核心 最大内存: 256MB
# qemu树莓派支持名: raspi2b 支持的树莓派类型: 树莓派2代B 树莓派cpu: Cortex-A7，cpu核心数: 4核心 最大内存: 1GB
# qemu树莓派支持名: raspi3ap 支持的树莓派类型: 树莓派3代A+ 树莓派cpu: Cortex-A53，cpu核心数: 4核心 最大内存: 512MB
# qemu树莓派支持名: raspi3b 支持的树莓派类型: 树莓派3代B 树莓派cpu: Cortex-A53，cpu核心数: 4核心 最大内存: 1GB
# qemu树莓派支持名: raspi4 支持的树莓派类型: 树莓派4代B 树莓派cpu: Cortex-A72，cpu核心数: 4核心 最大内存: 2GB/4GB/8GB
# kernel.img: 支持树莓派1代A+ (raspi1ap)，CPU: ARM11，核心数: 1，最大内存: 256MB
# bcm2710-rpi-zero-2.dtb, bcm2710-rpi-zero-2-w.dtb: 这些设备树二进制文件（.dtb）适用于树莓派Zero 2 W (raspi0)
# bcm2708-rpi-zero.dtb, bcm2708-rpi-zero-w.dtb, bcm2708-rpi-cm.dtb, bcm2708-rpi-b.dtb, bcm2708-rpi-b-rev1.dtb, bcm2708-rpi-b-plus.dtb: 这些设备树二进制文件（.dtb）适用于树莓派1代A+ (raspi1ap)
# kernel7.img: 支持树莓派2代B (raspi2b)，CPU: Cortex-A7，核心数: 4，最大内存: 1GB
# bcm2710-rpi-2-b.dtb, bcm2709-rpi-cm2.dtb, bcm2709-rpi-2-b.dtb: 这些设备树二进制文件（.dtb）适用于树莓派2代B (raspi2b)
# kernel7l.img: 支持树莓派3代A+ (raspi3ap) 和 树莓派3代B (raspi3b)，CPU: Cortex-A53，核心数: 4，最大内存: 512MB (3A+) / 1GB (3B)
# bcm2710-rpi-cm3.dtb, bcm2710-rpi-3-b.dtb, bcm2710-rpi-3-b-plus.dtb: 这些设备树二进制文件（.dtb）适用于树莓派3代A+ (raspi3ap) 和 树莓派3代B (raspi3b)
# kernel8.img: 支持树莓派4代B (raspi4)，CPU: Cortex-A72，核心数: 4，最大内存: 2GB/4GB/8GB
# bcm2711-rpi-cm4s.dtb, bcm2711-rpi-cm4.dtb, bcm2711-rpi-cm4-io.dtb, bcm2711-rpi-400.dtb, bcm2711-rpi-4-b.dtb: 这些设备树二进制文件（.dtb）适用于树莓派4代B (raspi4)

# 获取磁盘ROOT标识
ROOT=$(cat "${TMP_DIR}/${NAME}kd/cmdline.txt" | sed 's; ;\n;g' | grep 'root=PARTUUID=')

# 环境变量判断并自定义配置参数
if [ "${TARGET}" = "pi1" ]; then
  EMULATOR="qemu-system-arm"
  MACHINE="--machine type=versatilepb"
  CPU="--cpu arm1176"
  CPU_NUM="--smp cpus=1,sockets=1,cores=1,threads=1"
  MEMORY="--m 256m"
  DISK_DRIVE0="--drive if=none,index=0,media=disk,id=disk0,format="$(if [ "${QEMU_TYPES}" = "img" ] ; then  echo raw ; else echo ${QEMU_TYPES} ; fi)",file=${TMP_DIR}/${NAME}.${QEMU_TYPES}"
  DISK_DEVICE0="--device virtio-blk-pci,drive=disk0,disable-modern=on,disable-legacy=off"
  NET="--net nic --net user,hostfwd=tcp::8023-:22"
  DTB="--dtb ${TMP_DIR}/${NAME}kd/${QEMU_RPI_DTB_FILE}"
  KERNEL="--kernel ${TMP_DIR}/${NAME}kd/${QEMU_RPI_KERNEL_FILE}"
  DISPLAY="--display vnc=0.0.0.0:3"
  APPEND="$(if [ "${ROOT}" != "" ] ; then  echo "${ROOT}" ; else echo "root=/dev/vda2" ; fi)"
  OTHER=""
elif [ "${TARGET}" = "pi2" ]; then
  EMULATOR="qemu-system-arm"
  MACHINE="--machine type=raspi2b"
  CPU="--cpu cortex-a7"
  CPU_NUM="--smp cpus=4,sockets=1,cores=4,threads=1"
  MEMORY="--m 1024m"
  DISK_DRIVE0="--drive format="$(if [ "${QEMU_TYPES}" = "img" ] ; then  echo raw ; else echo ${QEMU_TYPES} ; fi)",file=${TMP_DIR}/${NAME}.${QEMU_TYPES}"
  DISK_DEVICE0=""
  NET="--netdev user,id=net0,hostfwd=tcp::8024-:22 --device usb-net,netdev=net0"
  DTB="--dtb ${TMP_DIR}/${NAME}kd/bcm2709-rpi-2-b.dtb"
  KERNEL="--kernel ${TMP_DIR}/${NAME}kd/kernel7.img"
  DISPLAY="--display vnc=0.0.0.0:4"
  APPEND="$(if [ "${ROOT}" != "" ] ; then  echo "${ROOT}" ; else echo "root=/dev/mmcblk0p2" ; fi)"
  OTHER="--usb --device usb-mouse --device usb-kbd"
elif [ "${TARGET}" = "pi3" ]; then
  EMULATOR="qemu-system-aarch64"
  MACHINE="--machine type=raspi3b"
  CPU="--cpu cortex-a53"
  CPU_NUM="--smp cpus=4,sockets=1,cores=4,threads=1"
  MEMORY="--m 1024m"
  DISK_DRIVE0="--drive format="$(if [ "${QEMU_TYPES}" = "img" ] ; then  echo raw ; else echo ${QEMU_TYPES} ; fi)",file=${TMP_DIR}/${NAME}.${QEMU_TYPES}"
  DISK_DEVICE0=""
  NET="--netdev user,id=net0,hostfwd=tcp::8025-:22 --device usb-net,netdev=net0"
  DTB="--dtb ${TMP_DIR}/${NAME}kd/bcm2710-rpi-3-b-plus.dtb"
  KERNEL="--kernel ${TMP_DIR}/${NAME}kd/kernel8.img"
  DISPLAY="--display vnc=0.0.0.0:5"
  APPEND="$(if [ "${ROOT}" != "" ] ; then  echo "${ROOT}" ; else echo "root=/dev/mmcblk0p2" ; fi)"
  OTHER="--usb --device usb-mouse --device usb-kbd"
else
  echo "Target ${TARGET} not supported"
  echo "Supported targets: pi1 pi2 pi3"
  exit 3
fi

# make launch.sh
cat << EOF >"${TMP_DIR}/launch.sh"
#!\$PREFIX/bin/bash
IFS_BAK=\${IFS}
IFS=\$'\n'
# `cat "${TMP_DIR}/${NAME}kd/cmdline.txt"`

echo "Booting QEMU machine \"\${MACHINE}\" with kernel=${KERNEL} dtb=${DTB} \\\\
exec ${EMULATOR} \\\\
  --no-reboot \\\\
  --serial mon:stdio \\\\
  ${MACHINE} \\\\
  ${CPU} \\\\
  ${CPU_NUM} \\\\
  ${MEMORY} \\\\
  ${DISK_DRIVE0} \\\\
  ${DISK_DEVICE0} \\\\
  ${NET} \\\\
  ${DTB} \\\\
  ${KERNEL} \\\\
  ${DISPLAY} \\\\
  --append \\"rw console=ttyAMA0,115200 ${APPEND} rootwait rootfstype=ext4 fsck.repair=yes fbcon=map:10 fbcon=font:ProFont6x11 logo.nologo dwc_otg.fiq_fsm_enable=0 dwc_otg.lpm_enable=0 bcm2708_fb.fbwidth=1024 bcm2708_fb.fbheight=768 panic=1\\" \\\\
  ${OTHER}"


# root模式sh参数 用于修改密码 ，追加 init=/bin/sh
#  --append "init=/bin/sh"
# 比如这样先挂载磁盘比如 /dev/mmcblk0p2 : mount /dev/mmcblk0p2 /mnt ; chroot /mnt
# 然后修改密码，运行缓慢等待 successfully : echo "raspberry\nraspberry" | passwd pi 
# 执行之后，ctrl + a + x 退出，删除 --append 里参数 init=/bin/sh
# 运行qemu模拟器，输入用户名/密码 : pi/raspberry

# 启动初始化脚本参数 用于磁盘扩容修复，ssh开启等作用 ，追加 init=/usr/lib/raspberrypi-sys-mods/firstboot
#  --append "init=/usr/lib/raspberrypi-sys-mods/firstboot"
# 但是针对 pi1 也就是 qemu 的 versatilepb 的机器使用会修复 parte uuid 造成系统损坏，不建议用在 pi1 模拟器上
# 或者可以修改 sudo nano /usr/lib/raspberrypi-sys-mods/firstboot 脚本注释 fix_partuuid 函数，就可以在 pi1 模拟器上追加运行了

exec ${EMULATOR} \\
  --no-reboot \\
  --serial mon:stdio \\
  ${MACHINE} \\
  ${CPU} \\
  ${CPU_NUM} \\
  ${MEMORY} \\
  ${DISK_DRIVE0} \\
  ${DISK_DEVICE0} \\
  ${NET} \\
  ${DTB} \\
  ${KERNEL} \\
  ${DISPLAY} \\
  --append "rw console=ttyAMA0,115200 ${APPEND} rootwait rootfstype=ext4 fsck.repair=yes fbcon=map:10 fbcon=font:ProFont6x11 logo.nologo dwc_otg.fiq_fsm_enable=0 dwc_otg.lpm_enable=0 bcm2708_fb.fbwidth=1024 bcm2708_fb.fbheight=768 panic=1" \\
  ${OTHER}
IFS=\${IFS_BAK}
EOF

# make deldir sh
cat << EOF >${TMP_DIR}/deldir.sh
#!\$PREFIX/bin/bash
IFS_BAK=\${IFS}
# IFS=\$(echo -en "\n\b")
IFS=\$'\n'
TMP_DIR="${TMP_DIR}"
cd \${TMP_DIR}
IMG_URL="${IMG_URL}"
FILENAME=\$(basename \$IMG_URL)
NAME=\$(basename \$FILENAME .img.xz)
NAME=\$(basename \$NAME .zip)
QEMU_TYPES=${QEMU_TYPES}

rm -rfv "\${TMP_DIR}/\${NAME}" \\
  "\${TMP_DIR}/\${NAME}.\${QEMU_TYPE1}" \\
  "\${TMP_DIR}/\${NAME}.\${QEMU_TYPE2}" \\
  "\${TMP_DIR}/\${NAME}kd" \\
  "\${TMP_DIR}/deldir.sh" \\
  "\${TMP_DIR}/launch.sh"
IFS=\${IFS_BAK}
EOF
IFS=${IFS_BAK}

echo -e "${END}\n${YELLOW}已经完成，执行 cd ${TMP_DIR} 进入目录会看到两个脚本
${GREEN}运行 qemu 模拟器脚本 -> ${TMP_DIR}/launch.sh
${GREEN}清理 ${TMP_DIR} 目录脚本 -> ${TMP_DIR}/deldir.sh
${YELLOW}现在执行 launch.sh 就可以看到效果了！${END}"
