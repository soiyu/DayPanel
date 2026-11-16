# DayPanel 微信小程序

云优先、无本地业务存储的 uni-app 微信小程序。设计见
[`docs/design/WECHAT-MINIPROGRAM.md`](../docs/design/WECHAT-MINIPROGRAM.md)。

当前是 P1 进行中：

- 已落地纯 TypeScript 领域：本地日历日、数量千分位、频率/计划、习惯动作。
- 已落地 `MemoryCloud` 测试替身：真实 revision 校验，用来验证“创建→打卡→重载→并发冲突→注销”纵切。
- CloudBase 环境、AppID、云函数部署、uni-app 页面依赖尚未接入；需要微信后台/CloudBase 控制台资料，不能用假数据代替。

## 测试

不需要安装依赖，Node 22 直接剥离类型运行：

```bash
npm test
```

## 约束

- 不写本地业务文件；数据源是 CloudBase。
- 无导出、无客服；账号级删除只走个人设置“注销账号”。
- 提醒三通道默认全开，但实际发送需要用户授权（一次性/摘要/日历各自授权）。
- v1 不加载广告 SDK；后续广告另行接入与审核。