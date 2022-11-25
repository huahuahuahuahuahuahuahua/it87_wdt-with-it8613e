# it87-wdt-driver

## 测试机型
理论上所有使用IT8613 IO芯片的都能这么使用，如果有在其他机型上测试通过，可以提交PR修改这里
```
畅网N5105 第一版
```

## 依赖
因为我本机构建过内核，不确定需要哪些依赖，理论上只需要`build-essential`，如果还是缺少依赖，那就执行
```
apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison
```

安装Headers（适用于Pve，其他发行版本安装`linux-headers-$(uname -r)`)
```
apt install pve-headers-$(uname -r)
```

## 编译&安装
```
make
make install
modprobe it87_wdt
```

## 检查
查看是否多了一个watchdog
```
# ls /dev/watchdog*
/dev/watchdog  /dev/watchdog0  /dev/watchdog1
```

Pve默认会启用softwatchdog，所以如果正常的话，会多出一个watchdog1，ID是 IT87 WDT
```
# wdctl /dev/watchdog1
Device:        /dev/watchdog1
Identity:      IT87 WDT [version 0]
Timeout:       60 seconds
```

## watchdog服务安装
这个有点麻烦，因为Pve默认带了一个watchdog-mux，并且和watchdog冲突，所以watchdog这里使用手动安装
```
mkdir -p /tmp/wd
cd /tmp/wd
apt download watchdog
dpkg -x watchdog_5.16-1+b1_amd64.deb extract
```

解压之后的目录结构应该是这样
```
# tree extract/
extract/
|-- etc
|   |-- init.d
|   |   |-- watchdog
|   |   `-- wd_keepalive
|   `-- watchdog.conf
|-- lib
|   `-- systemd
|       `-- system
|           |-- watchdog.service
|           `-- wd_keepalive.service
|-- usr
|   |-- sbin
|   |   |-- watchdog
|   |   |-- wd_identify
|   |   `-- wd_keepalive
|   `-- share
|       |-- doc
|       |   `-- watchdog
|       |       |-- IAFA-PACKAGE
|       |       |-- README
|       |       |-- README.Debian
|       |       |-- README.watchdog.ipmi.gz
|       |       |-- changelog.Debian.amd64.gz
|       |       |-- changelog.Debian.gz
|       |       |-- changelog.gz
|       |       |-- copyright
|       |       |-- examples
|       |       |   |-- README
|       |       |   |-- another-chance.sh
|       |       |   |-- dbcheck.sh
|       |       |   |-- repair.sh
|       |       |   |-- systemcheck.sh
|       |       |   `-- uptime.sh
|       |       |-- watch_err.h
|       |       `-- watchdog.lsm
|       `-- man
|           |-- man5
|           |   `-- watchdog.conf.5.gz
|           `-- man8
|               |-- watchdog.8.gz
|               |-- wd_identify.8.gz
|               `-- wd_keepalive.8.gz
`-- var
    `-- log
        `-- watchdog

```

手动创建配置文件`/etc/default/watchdog` 粘贴内容进去
```
# Start watchdog at boot time? 0 or 1
run_watchdog=1
# Start wd_keepalive after stopping watchdog? 0 or 1
run_wd_keepalive=1
# Load module before starting watchdog
watchdog_module="it87_wdt"
# Specify additional watchdog options here (see manpage).
```

然后将以下文件复制到系统的对应目录，例如 extract/usr/sbin/watchdog 就复制到系统根目录的 /usr/sbin/watchdog
```
|-- etc
|   |-- init.d
|   |   |-- watchdog
|   |   `-- wd_keepalive
|   `-- watchdog.conf
|-- lib
|   `-- systemd
|       `-- system
|           |-- watchdog.service
|           `-- wd_keepalive.service
|-- usr
|   |-- sbin
|   |   |-- watchdog
|   |   |-- wd_identify
|   |   `-- wd_keepalive
```

修改watchdog配置，把`/etc/watchdog.conf`里面的`watchdog-device`改成上述对应的watchdog，我这里是`/dev/watchdog1`
以及调整 `watchdog-timeout` 为期望的超时时间
其他的如`test-binary`根据你实际需求修改，因为我USB会有LinkReset的问题，所以我这里给了一个写盘的测试脚本，可以参考
```
#! /bin/bash


if [ -f /tmp/wd_failed ]; then
   echo "File exists."
   exit 1
fi

data=$(date)
echo $data > /data/watchdog_check
```

开启服务
```
systemctl enable /lib/systemd/system/watchdog.service
systemctl start watchdog
```

## 待确认的问题
我只做了简单的测试，但是有一些疑惑的地方，希望大家也能分享一下测试结果。
我做过的测试：
1. 在BIOS中配置超时时间为5Min
2. Watchdog中配置的是600s，`touch /tmp/wd_failed`让watchdog test-binary返回错误
3. 大约8分钟后，机器重启

不太确定BIOS中配置的5Min、和watchdog service中配置的600s之间的关系是什么。我个人猜测是 BIOS中的Timer是为了防止OS启动失败，如果OS启动完成，watchdog server启动后激活watchdog，则以watchdog service的配置为准。
如果大家有其他测试情况，欢迎在issue中反馈。