# Windows 网关 / DNS 一键切换

本机配置：`WLAN`（接口索引 5），固定 IPv4 地址保持不变，只切换默认网关与 DNS。

## 安装

双击 `Install.cmd`，接受一次管理员权限提示。安装后会立即生效，并在每次 Windows 登录时自动启动。

- `Ctrl + Alt + 1`：网关、DNS 切到 `192.168.3.1`
- `Ctrl + Alt + 2`：网关、DNS 切到 `192.168.3.11`
- `Ctrl + Alt + G`：右下角通知显示当前网关和 DNS

如需移除，双击 `Uninstall.cmd` 并接受管理员权限提示。

安装器会将脚本复制到 `%ProgramData%\NetworkGatewayHotkeys`，并创建以最高权限运行的登录计划任务 `Network Gateway Hotkeys`。脚本在修改前会再次核对接口索引 5 的名称必须为 `WLAN`，防止网卡索引变化时误改其他接口。
