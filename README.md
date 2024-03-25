# virtual-qemu-raspberry-script
本脚本为树莓派系列适配，树莓派 pi1 pi2 pi3  
![Watchers](https://img.shields.io/github/watchers/smallflowercat1995/virtual-qemu-raspberry-script) ![Stars](https://img.shields.io/github/stars/smallflowercat1995/virtual-qemu-raspberry-script) ![Forks](https://img.shields.io/github/forks/smallflowercat1995/virtual-qemu-raspberry-script) ![Vistors](https://visitor-badge.laobi.icu/badge?page_id=smallflowercat1995.virtual-qemu-raspberry-script) ![LICENSE](https://img.shields.io/badge/license-CC%20BY--SA%204.0-green.svg)
<a href="https://star-history.com/#smallflowercat1995/virtual-qemu-raspberry-script&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=smallflowercat1995/virtual-qemu-raspberry-script&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=smallflowercat1995/virtual-qemu-raspberry-script&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=smallflowercat1995/virtual-qemu-raspberry-script&type=Date" />
  </picture>
</a>
>
本脚本仅仅为 树莓派系列适配，其他环境，可以魔改爆改本脚本，从而达成你的目的
树莓派 pi1 pi2 pi3 不传入任何参数则默认为 pi1
命令使用方法，比如模拟 pi3 则命令为
```
bash initdir-raspberry.sh pi3
```
## 效果图：
![pi1~3](https://github.com/smallflowercat1995/virtual-qemu-raspberry-script/assets/144557489/6ec39a7f-e718-4701-8044-9a55d2aae5b5)

## 描述：
本脚本依赖以下包，你可能需要自己安装，我可以提供支持部分系统的命令，但是其他系统，要靠你自己啊
```
# MacOS
brew update --auto-update ; brew install aria2 wget curl p7zip gptfdisk ossp-uuid qemu git
# termux os
pkg install -y qemu-utils aria2 wget curl p7zip fdisk ossp-uuid qemu-system-aarch64-headless qemu-system-arm-headless git
# alpine os
sudo apk add aria2 wget curl 7zip qemu-system-aarch64 qemu-system-arm qemu-img gptfdisk ossp-uuid git
# debian os
sudo apt-get install -y qemu-utils aria2 wget curl p7zip fdisk uuid qemu-system-arm qemu-system-aarch64 git
```

执行脚本命令后会下载镜像校验sha256sum并创造以下目录结构，例如 pi1
```
bash initdir-raspberry.sh pi1
```
    
    2023-05-03-raspios-bullseye-armhf-pi1
    ├── 2023-05-03-raspios-bullseye-armhf.img      # 这个是解压出来的树莓派 img 镜像  
    ├── 2023-05-03-raspios-bullseye-armhf.img.xz   # 这个是脚本下砸的镜像压缩包   
    ├── 2023-05-03-raspios-bullseye-armhf.qcow2    # 这个是通过 img 镜像转换为 qcow2 磁盘格式镜像  
    ├── 2023-05-03-raspios-bullseye-armhfkd        # 这个文件夹里面包含启动所需的内核和设备树  
    ├── deldir.sh                                  # 这个是清理当前目录的脚本  
    └── launch.sh                                  # 这个是运行qemu模拟器脚本  
    
### pi1 
#### ssh 端口转发：22 -> 8023，需要开启虚拟机树莓派SSH服务，但是pi1似乎开启ssh有问题，目前我还不理解。
#### vnc 端口开放：5903
![pi1](https://github.com/smallflowercat1995/virtual-qemu-raspberry-script/assets/144557489/0eb5e396-1722-43da-b877-1b221667a847)
### pi2 
#### ssh 端口转发：22 -> 8024，需要开启虚拟机树莓派SSH服务
#### vnc 端口开放：5904
![pi2](https://github.com/smallflowercat1995/virtual-qemu-raspberry-script/assets/144557489/b9917973-4817-4111-9a33-ae3e162aefdf)
### pi3 
#### ssh 端口转发：22 -> 8025，需要开启虚拟机树莓派SSH服务
#### vnc 端口开放：5905
![pi3](https://github.com/smallflowercat1995/virtual-qemu-raspberry-script/assets/144557489/551c214a-9de6-43da-911c-e5f65c86583e)


## 参考&感谢
[QEMU Emulate Raspberry Pi 3 and 4：https://liviaerxin.github.io/blog/qemu-raspberry-pi](https://liviaerxin.github.io/blog/qemu-raspberry-pi)  
[如何用QEMU在x86電腦模擬ARM版樹莓派系統，虛擬機跑Raspberry Pi OS：https://ivonblog.com/posts/emulate-raspberry-pi-os-on-x86-linux/](https://ivonblog.com/posts/emulate-raspberry-pi-os-on-x86-linux/)  
[Raspberry Pi and QEMU：https://www.marcusfolkesson.se/categories/qemu/](https://www.marcusfolkesson.se/categories/qemu/)  
[dhruvvyas90/qemu-rpi-kernel：https://github.com/dhruvvyas90/qemu-rpi-kernel/tree/master/native-emulation](https://github.com/dhruvvyas90/qemu-rpi-kernel/tree/master/native-emulation)  
[edt11x/edt-qemu-raspi3：https://github.com/edt11x/edt-qemu-raspi3](https://github.com/edt11x/edt-qemu-raspi3)  
[farabimahmud/emulate-raspberry-pi3-in-qemu：https://github.com/farabimahmud/emulate-raspberry-pi3-in-qemu](https://github.com/farabimahmud/emulate-raspberry-pi3-in-qemu)  
[dhruvvyas90/qemu-rpi-kernel：https://github.com/dhruvvyas90/qemu-rpi-kernel](https://github.com/dhruvvyas90/qemu-rpi-kernel)  
[lukechilds/dockerpi：https://github.com/lukechilds/dockerpi](https://github.com/lukechilds/dockerpi)  
[raspi4-with-arceos-doc：https://chenlongos.com/raspi4-with-arceos-doc/chapter_1.1.html](https://chenlongos.com/raspi4-with-arceos-doc/chapter_1.1.html)  
[使用QEMU模拟树莓派Raspberry Pi：https://cloud.tencent.com/developer/article/1685107](https://cloud.tencent.com/developer/article/1685107)  
[在qemu中启动树莓派：https://blog.csdn.net/qq_42924144/article/details/134650893](https://blog.csdn.net/qq_42924144/article/details/134650893)  
[QEMU仿真树莓派1和3B-保姆级教程：https://zhuanlan.zhihu.com/p/452590356](https://zhuanlan.zhihu.com/p/452590356)  
