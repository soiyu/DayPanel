# Google Play 发布准备

本轮授权为基础免费+Plus非消耗型一次买断。现有基础记录、备份/恢复/回退/CSV导出、数据查看与纠正保持可用。无广告、分析SDK、账号、云同步或订阅。商品只展示Play实际本地化价格，取消/待付款不能当成功。

## 本地构建

1. 复制play-release.properties.example到ignored .local/play-release.properties，填真实的正式包名、Play商品ID、公钥、上传密钥与支持联系/公开政策地址。最终包名一旦发布不能随便改；不要把debug包身份用于正式上架。
2. scripts/dev.ps1 release-check检查必要字段。没有真实资料会明确阻止“可发布”确认；不会生成假的密钥/价格/已购状态。
3. scripts/dev.ps1 bundle -Extra '--no-pub'构建release AAB。配置签名时使用正式上传密钥；未配置时可构建检查用未签名AAB，不能称可上传包。不要用debug签名冒充正式签名。
4. python scripts/check-android-package.py build/app/outputs/bundle/release/app-release.aab核验64位库ELF的16KB页面对齐；再用Play内部测试安装，按实际设备下载大小验收。
5. 版本号由pubspec.yaml维护，后续上传递增build number。仓库不保存APK/AAB/私钥/证书密码/服务账号。

## Console与支付

- 创建daypanel_plus一次性非消耗型商品，单一标准购买选项，不配置订阅、租赁或虚构折扣。价格由负责人在Console决定，本轮代码不硬编码报价。
- 使用当前Billing Library；连接→查询商品→Play确认→校验签名/package/product/purchaseState/token→确认购买→本机缓存已验证收据；queryPurchases恢复。待付款不授予权益；成功查询到退款/不存在的购买会移除权益。离线保留之前已验证收据，退款离线无法实时获知。
- debug明确开放测试权益并标识“未产生购买”，不初始化无用Billing连接；release无公钥/商品时显示不可购买，不放行Plus。业务备份不包含收据，换机通过同一Google Play购买账号恢复，记录通过自己的备份恢复。
- 收据验证在设备端完成，具备真实性校验但不能抵御被修改客户端或root环境。Google建议在安全服务端验证/确认购买；本项目未增加未授权业务云服务，正式规模化商业分发前应评估独立购买验证服务。不要将本地合成签名测试称为真实付款测试。
- 必须用Play license tester实际验证：购买成功、取消、待付款转成功/取消、确认重试、断网、重复按钮、已拥有、换设备恢复、退款后刷新、账号切换。外部商品/账号尚未提供，因此这部分不能由APK构建代替。

## 商店与申报

准备英文优先的名称、短/长说明、应用图标、真实手机与桌面截图、特性图、客服邮箱、公开HTTPS隐私政策、内容分级、目标受众、广告声明与Data safety。不要在标题/截图声称无条件全部免费；写明可选一次性购买，无订阅。

不收集个人业务内容的本地App也要提供政策和完成Data safety申报。文件/系统分享/日历仅用户主动交给所选应用；购买交由Google Play处理。最终申报须根据实际release merged manifest、Billing SDK行为与发行者服务确认，不能仅依本模板勾“完全不收集”。日历不申请READ_CALENDAR/WRITE_CALENDAR，用户在系统日历确认独立副本。

若使用2023-11-13后创建的新个人开发者账号，当前生产访问流程要求至少12名测试者连续参与14天封闭测试后申请；仍以实际Console提示为准。身份/收款/Play App Signing/测试与审核需要真实账号。未上传、未提交审核、未推送远端。

本地开源依赖通知与字体OFL保留。原工程Loop源码未复制；原始代码发行许可和发行者法律信息仍需负责人核定。

## 本轮实际产物

源码版本**0.2.1+3**（新增深度洞察，versionCode递增）；debug为app.daypanel.next.debug，release默认app.daypanel.next，发布前核定。此前0.2.0+2的`DayPanel-0.2.0-Plus-debug.apk`可安装测试，`DayPanel-0.2.0-Plus-UNSIGNED.aab`为未签名检查产物、不可直接上传；0.2.1+3尚未在本机构建（缺JDK/Android SDK），需按上文由负责人或CI生成新AAB并重新核验。最终哈希和全部失败/修复过程见PLUS-VALIDATION。默认包名未替负责人作永久品牌承诺。
