# Windows Server: 将虚机从阿里云迁移到Azure

阿里云无法像Azure一样，能容易的导出vhd并迁移到各种环境中，包含本地及云端环境，或是迁移至其他的区域。这造成在开发，测试或是扩展时有很大的麻烦。因此本文阐述的是如何将Windows Server的虚机，从阿里云中迁移到Azure环境，同时能保存虚机内的数据，不需重新部署应用的方法。

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

接着，为了导出虚机的磁盘，我们需要挂载数据盘以存放导出的虚拟磁盘文件(.vhd)，大小建议为需要备份的磁盘大小的两倍，详细方法请参考[挂载数据盘](https://help.aliyun.com/document_detail/25446.html?spm=5176.doc25450.6.624.AYaS4Z)，值得提醒的是，除了在阿里云控制台进行挂载，也需要在操作系统内[进行配置](https://help.aliyun.com/document_detail/25418.html?spm=5176.doc25446.2.4.pia69h)。

最后，为了准备上传磁盘的空间，需要在Azure上创建一个存储账户，值得注意的是这个存储账户必须与虚机是同一种类型，这边采用的是资源管理模式(Azure Resource Manager)，进行[存储账户创建](https://www.azure.cn/documentation/articles/storage-create-storage-account/)，同时请创建一个容器(container)，名为vhds。

## 调整服务器配置

在此步骤中，我们将进行服务器的调整以兼容于Azure的环境。

1. 用具有管理员权限的账户登入阿里云的Windows Server虚机
2. 在阿里云的虚机内下载[工具包]()
3. 解压缩工具包
4. 执行AliyunWindowsPreparation.ps1

此脚本将会修改Windows Server的配置并安装Azure的Agent，已完成迁移至Azure的准备。

## 导出磁盘

在Windows Server中，我们所使用的工具是[disk2vhd](https://technet.microsoft.com/en-us/sysinternals/ee656415.aspx)，在之前下载的[工具包]()内tools的文件夹已经包含，或者也可以单独下载。

执行这个disk2vhd，选择要备份的磁盘并将备份的目标路径指向刚才挂载的磁盘上，并取消勾选*use vhdx*，最后点选*create*。

等待直至导出磁盘完成。

## 上传磁盘

在此我们将运用Azure PowerShell将刚才导出的磁盘上传至先前创建的存储账户中。

1. 用具有管理员权限的账户登入阿里云的Windows Server虚机
2. 在阿里云的虚机内下载[工具包]() (若之前下载过可省略2.3.步骤)
3. 解压缩工具包
4. 在tools文件夹中，执行vhdUploader.ps1

vhdUploader将会进行下列步骤：

1. 输入Azure订阅名称
2. 输入要上传的目标存储账户
3. 安装Azure PowerShell模组
4. 输入Azure 账号及密码
5. 进行磁盘上传

等待直至上传完成，记录磁盘的url，或到[Azure门户](portal.azure.cn)查询刚才上传的磁盘的url。

## 建立新的虚机

当上述步骤都已经完成，可以点选下面图标根据你上传的磁盘url创建机器。

<a href="https://portal.azure.cn/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAliyunMigration%2Fmaster%2FARMTemplateRepos%2FcreateVmFromCustomVhd.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

在栏位中依序填入VM创建的地点，刚才上传的系统磁盘url，OS类型(这边应该选Windows)，VM的大小及VM的名称。

接着点选创建，虚机将开始进行部署。过一段时间之后，便可以连结上你所迁移的机器了。

## 需要帮助？

如果有任何问题或反馈，欢迎[联系我们](mailto:amcteam@microsoft.com)。