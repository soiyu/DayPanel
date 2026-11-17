# DayPanel 微信小程序

云优先、无本地业务存储的 uni-app 微信小程序。设计见
[`docs/design/WECHAT-MINIPROGRAM.md`](../docs/design/WECHAT-MINIPROGRAM.md)。

## 当前状态（P1）

- 已实现纯 TypeScript 领域：本地日历日、数量千分位、频率/计划、习惯动作、提醒策略。
- 已实现 uni-app 四 tab 壳、今日页、新建/编辑/详情习惯（含暂停/跳过/归档/删除）、小事页/新建/详情/历史、手记页/新建/编辑/月份/搜索/习惯筛选、统计页、深度洞察、年历、单日历史、时间线、卡片册（收藏/心得/分享图）、外观（主题/调色板/字体/边框/预览取消）、28 个习惯图标、复盘长图、隐私页、注销入口。
- 已实现 CloudBase `api` 云函数源码：`today` / `tasks` / `notes` / `stats` / `cards` / `mutate` / `deleteAccount`；写入用 revision + 事务，客户端不直写数据库。
- 已实现 `MemoryCloud` 测试替身：验证创建→打卡→重载→并发冲突→注销纵切；任务/手记有独立领域测试。
- 已构建微信小程序：`dist/build/mp-weixin`；主包约 0.64 MB；已关闭 uni 统计。
- 尚未真实部署 CloudBase：需要小程序 AppID、云开发环境 ID、微信开发者工具；未做真机/换设备/断网验收。

### 没做的

- 2027 节假日/节气表待官方数据；微信运动/群组需真实 CloudBase 验证。
- 三通道提醒的完整发送（模板 ID/字段未提供；已有状态/开关/发送器源码）。
- 广告（v1 不接，`AdSlot` 默认关闭）。
- 习惯分组/排序、休假区间页面。
- 六款卡面为 CSS 矢量场景近似，不是 Flutter 原画的逐像素复刻；深色变体已加。
- 卡片六款原创插画：当前为 CSS 渐变占位，不冒充原画；分享图已用 Canvas 2D 生成，未在微信真机验证。
- 真实 CloudBase 集合/索引/权限创建与部署（需要后台资料）。
- 广告：v1 只预留 `AdSlot`，不加载任何广告 SDK。
- 整库导出/客服副本：按决定不做；只保留个人设置注销与单条记录删除。

## 国内化方向

国内化 P0 已落地：2026 中国节假日/调休、工作日/休息日计划、7 天补记与审计、长辈模式、中文分享钩子。P1 代码侧已落地：21/100 天挑战、微信运动同步、分享链接群组、2026 年 24 节气展示；真实 CloudBase/模板/真机仍待验证。

国内行情功能设计见 [`docs/product/DOMESTIC-FEATURES.md`](../docs/product/DOMESTIC-FEATURES.md)，决策见 [`ADR0020`](../docs/adr/0020-domestic-product-direction.md)。P0 包括中国节假日/调休、补记、长辈模式、中文分享；社交/微信运动默认关闭，待确认。

## 部署

见 [`docs/development/WECHAT-DEPLOY.md`](../docs/development/WECHAT-DEPLOY.md)。需要真实 AppID、CloudBase 环境 ID、微信开发者工具和订阅消息模板；当前不能用本地数据冒充云端。

## 命令

```bash
npm install
npm run typecheck
npm test
npm run build:mp-weixin
npm run build:cloud
npm run prepare:wechat
npm run audit:size
# 或一次跑完
npm run verify
```

- `dist/build/mp-weixin`：用微信开发者工具导入；`project.config.json` 已指向 `cloudfunctions/`。
- `touristappid` 只是占位，需替换为真实 AppID。
- `src/config.ts` 的 `CLOUD_ENV` 留空时使用默认云环境；发布前显式填写。
- 云函数部署：在微信开发者工具中右键 `cloudfunctions/api` → 上传并部署；`wx-server-sdk` 由函数自己的 `package.json` 安装。

## 约束

- 不写本地业务文件；数据源是 CloudBase。
- 无整库导出、无客服；账号级删除只走个人设置“注销账号”（单条记录删除保留）。
- 提醒三通道默认全开，但实际发送需要用户授权（一次性/摘要/日历各自授权）。
- v1 全免费；后续广告另行接入与审核，v1 不加载广告 SDK。
- `MemoryCloud` 是测试替身，不是生产持久化；不能据此宣称已上云。