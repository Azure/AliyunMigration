# CentOS: 将虚机从阿里云迁移到Azure

[English](https://github.com/Azure/AliyunMigration/tree/master/WindowsServer/README_ENG.md)

阿里云无法像Azure一样，能容易的导出vhd并迁移到各种环境中，包含本地及云端环境，或是迁移至其他的区域。这造成在开发，测试或是扩展时有很大的麻烦。因此本文阐述的是如何将CentOS 6.8的虚机，从阿里云中迁移到Azure环境，同时能保存虚机内的数据，不需重新部署应用的方法。


## 主要步骤

迁移的主要步骤分为：__准备环境__，__调整服务器配置__，__导出磁盘__，__上传磁盘__，__建立新的虚机__。在这几个步骤中，**调整服务器配置**将对阿里云中的配置进行调整以符合Azure的需求，因此将会涉及一些影响在阿里云运行的调整。有几个推荐的做法：

* 在调整前进行[快照](https://help.aliyun.com/document_detail/25455.html?spm=5176.doc25429.6.644.VHJtFD)，操作错误时可进行[回滚](https://help.aliyun.com/document_detail/25450.html?spm=5176.doc25455.6.641.S3Z8he)
* 如本地有Hyper-V机器，可先进行**导出磁盘**再进行**调整服务器配置**

因此，根据你的策略，流程可分为

1. __准备环境__=>__调整服务器配置__=>__导出磁盘__=>__上传磁盘__=>__建立新的虚机__
2. __准备环境__=>__导出磁盘__=>__调整服务器配置__=>__上传磁盘__=>__建立新的虚机__

你可根据需要决定选择何种流程，以下我们将针对各步骤进行详细说明。

## 准备环境

首先，推荐先对现有磁盘进行[快照](https://help.aliyun.com/document_detail/25455.html?spm=5176.doc25429.6.644.VHJtFD)。

接着，为了导出虚机的磁盘，我们需要挂载数据盘以存放导出的虚拟磁盘文件(.vhd)，大小建议为需要备份的磁盘大小的两倍，详细方法请参考[挂载数据盘](https://help.aliyun.com/document_detail/25446.html?spm=5176.doc25450.6.624.AYaS4Z)，值得提醒的是，除了在阿里云控制台进行挂载，也需要在操作系统内[进行配置](https://help.aliyun.com/document_detail/25426.html?spm=5176.doc25446.2.3.pia69h)。

最后，为了准备上传磁盘的空间，需要在Azure上创建一个存储账户，值得注意的是这个存储账户必须与虚机是同一种类型，这边采用的是资源管理模式(Azure Resource Manager)，进行[存储账户创建](https://www.azure.cn/documentation/articles/storage-create-storage-account/)，同时请创建一个容器(container)，名为vhds。

## 调整服务器配置

在此步骤中，我们将进行服务器的调整以兼容于Azure的环境。

1.用具有管理员权限的账户登入阿里云的Linux虚机

2.修改 /etc/sysconfig/network

```bash
vi /etc/sysconfig/network
```

修改为

```
NETWORKING=yes
HOSTNAME=localhost.localdomain
```

3.修改 /etc/sysconfig/network-scripts/ifcfg-eth0

```bash
vi /etc/sysconfig/network-scripts/ifcfg-eth0
```

修改为

```
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
USERCTL=no
PEERDNS=yes
IPV6INIT=no
```

4.修改 /etc/sysconfig/network-scripts/ifcfg-eth1，将其禁用

```bash
vi /etc/sysconfig/network-scripts/ifcfg-eth0
```

修改为

```
DEVICE=eth1
#ONBOOT=yes
#BOOTPROTO=static
#IPADDR=1.1.1.1
#NETMASK=255.255.255.0
```

5.修改 udev 规则，以避免产生以太网接口的静态规则。在 Azure 或 Hyper-V 中克隆虚拟机时，这些规则会引发问题：

```bash
sudo ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules
```

6.修改服务启动的配置，禁用阿里云的服务

```bash
sudo chkconfig network on
sudo chkconfig aegis off
sudo chkconfig aliyun-util off
```

7.更新镜像库

```bash
wget -q https://aliyunmigration.blob.core.chinacloudapi.cn/packages/CentOS-Base.repo -O /etc/yum.repos.d/CentOS-Base.repo
```

8.修改 /etc/yum.conf

```bash
vi /etc/yum.conf
```

添加一行

```
http_caching=packages
```

9.清除yum元数据并进行更新

```bash
yum clean all
sudo yum -y update
```

10.安装 Azure Linux 代理和依赖项

```bash
sudo yum install python-pyasn1 WALinuxAgent
```

11.在 grub 配置中修改内核引导行，以使其包含 Azure 的其他内核参数。 为此，请在文本编辑器(vi)中打开 /boot/grub/menu.lst，并确保默认内核包含以下参数

```
console=ttyS0 earlyprintk=ttyS0 rootdelay=300
```

12.编辑磁盘文件，将不需用到的磁盘禁用

```bash
vi /etc/fstab
```

在我的例子中，将数据盘标注掉：
```
#/dev/vdb1 /mnt ext3 defaults 0 0
```

至此，你已完成CentOS 6.8上传至Azure磁盘前的准备。

## 导出磁盘

在Linux中，我们所使用的工具是[dd](https://www.linux.com/learn/full-metal-backup-using-dd-command)，进行整个磁盘的备份，再备份完成后再用[qemu](http://wiki.qemu-project.org/Main_Page)工具，转成vhd的文件格式。

首先，执行dd指令，这里我导出的磁盘为/dev/vda，额外挂载作为备份的磁盘为/mnt，导出的文件为aliyuncentos68.raw

```bash
dd if=/dev/vda of=/mnt/aliyuncentos68.raw bs=100M
```

等待dd完成后，安装qemu工具。

```bash
sudo yum install qemu-kvm
```

安装完成后，进行格式转换，其中/mnt为刚才的备份目录，aliyuncentos68.raw为刚才的备份文件，aliyuncentos68.vhd则为转换后的文件

```bash
cd /mnt
qemu-img convert -f raw -o subformat=fixed -O vpc aliyuncentos68.raw aliyuncentos68.vhd
```

等待直至转换磁盘完成。

## 上传磁盘

在此我们将运用Azure CLI将刚才导出的磁盘上传至先前创建的存储账户中。

首先需要安装NodeJS

```bash
curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
sudo yum -y install nodejs
```

接着安装Azure CLI

```bash
npm install -g azure-cli
```

然后需要刚才在Azure创建的存储账户信息及密钥组成连结字符串，如

```
DefaultEndpointsProtocol=https;BlobEndpoint=storagename.blob.core.chinacloudapi.cn;AccountName=storagename;AccountKey=storagekey
```

接着执行指令进行上传

```bash
cd /mnt
azure storage blob upload -c 'DefaultEndpointsProtocol=https;BlobEndpoint=storagename.blob.core.chinacloudapi.cn;AccountName=storagename;AccountKey=storagekey' -t page --container vhds -f aliyuncentos68.vhd
```

## 建立新的虚机

当上述步骤都已经完成，可以点选下面图标根据你上传的磁盘url创建机器。

<a href="https://portal.azure.cn/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAliyunMigration%2Fmaster%2FARMTemplateRepos%2FcreateVmFromCustomVhd.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

在栏位中依序填入VM创建的地点，刚才上传的系统磁盘url，OS类型(这边应该选Linux)，VM的大小及VM的名称。

接着点选创建，虚机将开始进行部署。过一段时间之后，便可以连结上你所迁移的机器了。

## 需要帮助？

如果有任何问题或反馈，欢迎[联系我们](mailto:amcteam@microsoft.com)。
