# Windows Server: Migrate the VM from Aliyun to Azure

[中文](https://github.com/Azure/AliyunMigration/tree/master/WindowsServer)

Unlike Azure, Aliyun cannot easily export the vm disks and move to multiple environment no matter cloud or on-premise even another region of Aliyun. This causes many troubles in developing, testing and expanding. Hence, this article illustrates how to move Windows Server VM from Aliyun to Azure and keep the data inside the VM without re-deployment. 

## Main Steps

The main steps are: __Preparation__, __Adjust Configuration__, __Export Disks__, __Upload Disks__, __Build VM__. In these steps, __Adjust Configuration__ will change the configuration in the VMs of Aliyun to fit Azure requirement. Therefore, it will impact the running instance. There are some recommendded approaches:

* Take [Snapshot](https://help.aliyun.com/document_detail/25455.html?spm=5176.doc25429.6.644.VHJtFD) before making changes. You can [Rollback](https://help.aliyun.com/document_detail/25450.html?spm=5176.doc25455.6.641.S3Z8he) once any error happens.
* If you have a Hyper-V machines, you can __Export Disks__ first and then __Adjust Configuration__.

Based on strategy, the process can be

1. __Preparation__ => __Adjust Configuration__ => __Export Disks__ => __Upload Disks__ => __Build VM__
2. __Preparation__ => __Export Disks__ => __Adjust Configuration__ => __Upload Disks__ => __Build VM__

You can decide what's the best process according to business requirment. We will introduce the details of each steps in following page.

## Preparation

First of all, we recommend to take [SnapShot](https://help.aliyun.com/document_detail/25455.html?spm=5176.doc25429.6.644.VHJtFD) for existing disks.

Secondly, in order to export the disks of VM, we need to attach data disks to store the exported vhds. The disk size should be twice of original disk. You can see [Attach Data Disks](https://help.aliyun.com/document_detail/25446.html?spm=5176.doc25450.6.624.AYaS4Z) for detail steps. After attaching disks, you also need to [Change Settings](https://help.aliyun.com/document_detail/25418.html?spm=5176.doc25446.2.4.pia69h) inside guest OS.

Finally, we also need a storage account in Azure for vhd uploading. The storage account must be same type(Classic or ARM) with VM. Please check [Create Storage Account](https://docs.microsoft.com/en-us/azure/storage/storage-create-storage-account) for detail steps. After storage account creation, please also create a container called __vhds__.


## Adjust Configuration

In this step, we will adjust server configuration to compact with Azure environment.

1. Use account with administrator permission to login Windows Sever in Aliyun
2. Download [Toolkit](https://aliyunmigration.blob.core.chinacloudapi.cn/packages/AliyunWindowsTool.zip) inside the Aliyun VM.
3. Unzip Toolkit
4. Execute AliyunWindowsPreparation.ps1

This script will modify Windows Server configuration and install Azure agent to finish the preparation to migrate to Azure.

## Export Disks

In Windows Server, we will leverage [disk2vhd](https://technet.microsoft.com/en-us/sysinternals/ee656415.aspx) to do the disk export. it should be already included in the [Toolkit](https://aliyunmigration.blob.core.chinacloudapi.cn/packages/AliyunWindowsTool.zip) we download previously or you can download the tool standalone.

Execute disk2vhd, select the disk you can to export and select the target path to the disk we just mount, uncheck _use vhdx_ and then click _create_.

Wait until the job finish.

## Upload Disks

We will leverage Azure Powershell to upload the vhds into the Azure storage account we just created.

1. Use account with administrator permission to login Windows Sever in Aliyun
2. Download [Toolkit](https://aliyunmigration.blob.core.chinacloudapi.cn/packages/AliyunWindowsTool.zip) inside the Aliyun VM. (you can skip step 2. 3. if you have downloaded)
3. Unzip Toolkit
4. Execute vhdUploader.ps1

vhdUploader will follow the steps:

1. Enter Azure Subscription name
2. Enter Azure Storage Account name
3. Enter vhd local path
3. Install Azure PowerShell module
4. Enter Azure account and password
5. Upload the vhds

Wait until the upload complete. You can go to [Azure Portal](portal.azure.cn) to query the disk url we just upload.

## Build VM

When the above steps complete, click the __deploy to Azure__ icon to create Azure VM.

<a href="https://portal.azure.cn/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAliyunMigration%2Fmaster%2FARMTemplateRepos%2FcreateVmFromCustomVhd.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Input the information accordingly: location, disk url, OS type, VM size and VM name. 

Lastly, click __Create__ and it will start the deployment. After a while, you can connect to the VM you just create.


## Need Help？

Any question or feedback, please [Contact Us](mailto:amcteam@microsoft.com)。
