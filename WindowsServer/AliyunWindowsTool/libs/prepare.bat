sc stop aliyunservice
sc delete aliyunservice
sc stop "alibaba security aegis detect service"
sc delete "alibaba security aegis detect service"
sc stop "alibaba security aegis update service"
sc delete "alibaba security aegis update service"
taskkill /im AliHids.exe /f
rd /s /q "C:\ProgramData\aliyun"
rd /s /q "C:\Program Files (x86)\Alibaba"
diskpart /s .\libs\sanpolicy.txt
REG ADD HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation /v RealTimeIsUniversal /t REG_DWORD /d 1 /f
sc config w32time start= auto
sc config bfe start= auto
sc config dcomlaunch start= auto
sc config dhcp start= auto
sc config dnscache start= auto
sc config IKEEXT start= auto
sc config iphlpsvc start= auto
sc config PolicyAgent start= demand
sc config LSM start= auto
sc config netlogon start= demand
sc config netman start= demand
sc config NcaSvc start= demand
sc config netprofm start= demand
sc config NlaSvc start= auto
sc config nsi start= auto
sc config RpcSs start= auto
sc config RpcEptMapper start= auto
sc config termService start= demand
sc config MpsSvc start= auto
sc config WinHttpAutoProxySvc start= demand
sc config LanmanWorkstation start= auto
sc config RemoteRegistry start= auto
REG DELETE "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\SSLCertificateSHA1Hash" /f
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveEnable /t REG_DWORD  /d 1 /f
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveInterval /t REG_DWORD  /d 1 /f
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp" /v KeepAliveTimeout /t REG_DWORD /d 1 /f
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD  /d 1 /f
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v SecurityLayer /t REG_DWORD  /d 1 /f
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v fAllowSecProtocolNegotiation /t REG_DWORD  /d 1 /f
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD  /d 0 /f
netsh advfirewall firewall set rule dir=in name="File and Printer Sharing (Echo Request - ICMPv4-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (LLMNR-UDP-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (NB-Datagram-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (NB-Name-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (Pub-WSD-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (SSDP-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (UPnP-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (WSD EventsSecure-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Windows Remote Management (HTTP-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Windows Remote Management (HTTP-In)" new enable=yes
netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes
netsh advfirewall firewall set rule group="Core Networking" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (LLMNR-UDP-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (NB-Datagram-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (NB-Name-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (Pub-WSD-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (SSDP-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (UPnPHost-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (UPnP-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (WSD Events-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (WSD EventsSecure-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (WSD-Out)" new enable=yes
netsh advfirewall set allprofiles state on
bcdedit /set {bootmgr} integrityservices enable
bcdedit /set {default} device partition=C:
bcdedit /set {default} integrityservices enable
bcdedit /set {default} recoveryenabled Off
bcdedit /set {default} osdevice partition=C:
bcdedit /set {default} bootstatuspolicy IgnoreAllFailures
