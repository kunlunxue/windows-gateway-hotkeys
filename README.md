# Windows Gateway / DNS Hotkeys

使用全局键盘快捷键，在两组自定义的 IPv4 网关和 DNS 配置之间快速切换。适用于需要频繁切换路由器、代理网关或开发网络环境的 Windows 电脑。

## 功能

- `Ctrl + Alt + 1`：切换到配置 A
- `Ctrl + Alt + 2`：切换到配置 B
- `Ctrl + Alt + G`：在 Windows 通知中显示当前网关和 DNS
- 安装时选择物理网卡，并填写两组网关与 DNS
- DNS 支持填写多个地址，用逗号分隔
- 登录 Windows 后自动启动，无需每次确认管理员权限

## 安装

1. 下载或克隆本仓库。
2. 双击 `Install.cmd`，接受管理员权限提示。
3. 在安装窗口中选择要控制的网卡。
4. 填写配置 A、配置 B 的网关和 DNS，然后点击 **Install**。

安装窗口会将当前默认网关和 DNS 预填到配置 A。配置保存在：

```text
%ProgramData%\NetworkGatewayHotkeys\Config.json
```

重新运行 `Install.cmd` 可以修改配置。卸载时双击 `Uninstall.cmd`。

## 注意事项

- 目前仅支持 IPv4。
- 切换时只修改所选网卡的默认网关和 DNS，不修改该网卡的 IP 地址或子网掩码。
- 安装程序通过计划任务以最高权限在用户登录时启动热键程序。
- 如果所选网卡之后被重命名，请重新运行安装程序选择网卡。
