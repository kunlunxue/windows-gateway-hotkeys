# Windows Gateway / DNS Hotkeys

[English](#english) | [中文](#中文)

## English

Use global keyboard shortcuts to switch quickly between two custom IPv4 gateway and DNS profiles. This utility is designed for Windows computers that frequently switch between routers, proxy gateways, or development network environments.

### Features

- `Ctrl + Alt + 1`: Switch to Profile A.
- `Ctrl + Alt + 2`: Switch to Profile B.
- `Ctrl + Alt + G`: Show the current gateway and DNS in a Windows notification.
- Select a physical network adapter and enter two gateway/DNS profiles during installation.
- Use multiple DNS server addresses by separating them with commas.
- Start automatically after Windows sign-in without repeated administrator prompts.

### Installation

1. Download or clone this repository.
2. Double-click `Install.cmd` and accept the administrator permission prompt.
3. Select the network adapter that you want to control.
4. Enter the gateway and DNS addresses for Profile A and Profile B, then click **Install**.

The installer pre-fills Profile A with the current default gateway and DNS. The configuration is saved at:

```text
%ProgramData%\NetworkGatewayHotkeys\Config.json
```

Run `Install.cmd` again to change the configuration. Double-click `Uninstall.cmd` to remove the utility.

### Notes

- Only IPv4 is currently supported.
- Switching changes only the default gateway and DNS of the selected adapter. It does not change the adapter's IP address or subnet mask.
- The installer creates a scheduled task that starts the hotkey program with elevated privileges when the user signs in.
- If the selected adapter is renamed, run the installer again and select the adapter under its new name.
- All installer, validation, status, and uninstaller messages are displayed in English.

## 中文

使用全局键盘快捷键，在两组自定义的 IPv4 网关和 DNS 配置之间快速切换。适用于需要频繁切换路由器、代理网关或开发网络环境的 Windows 电脑。

### 功能

- `Ctrl + Alt + 1`：切换到配置 A。
- `Ctrl + Alt + 2`：切换到配置 B。
- `Ctrl + Alt + G`：在 Windows 通知中显示当前网关和 DNS。
- 安装时选择物理网卡，并填写两组网关与 DNS。
- DNS 支持填写多个地址，用逗号分隔。
- 登录 Windows 后自动启动，无需每次确认管理员权限。

### 安装

1. 下载或克隆本仓库。
2. 双击 `Install.cmd`，接受管理员权限提示。
3. 在安装窗口中选择要控制的网卡。
4. 填写配置 A、配置 B 的网关和 DNS，然后点击 **Install**。

安装窗口会将当前默认网关和 DNS 预填到配置 A。配置保存在：

```text
%ProgramData%\NetworkGatewayHotkeys\Config.json
```

重新运行 `Install.cmd` 可以修改配置。双击 `Uninstall.cmd` 可以卸载程序。

### 注意事项

- 目前仅支持 IPv4。
- 切换时只修改所选网卡的默认网关和 DNS，不修改该网卡的 IP 地址或子网掩码。
- 安装程序会创建计划任务，在用户登录时以管理员权限启动热键程序。
- 如果所选网卡之后被重命名，请重新运行安装程序并选择新名称下的网卡。
- 安装、输入验证、状态通知和卸载过程中的所有程序提示均使用英文。
