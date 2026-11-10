# Plus 与 Google Play 准备验收

2026-11-11，代码起点7ce6492。用户授权全部高级功能、日历、必要备份/导出、上架代码，并要求完成测试后关机。规则见ADR0016，路径见PLUS-FLOWS。旧原生工程未修改，没有推送远端。

## 已实现范围

|能力|实际交付|边界|
|---|---|---|
|组合桌面|真实第三类Launcher组件，1–4混合事项、顺序、直接显式完成/撤销、数量直输、实际尺寸/大字适配、独立实例/重新配置/查看全部|不同事项修订隔离；同对象旧动作/ABA/恢复世代拒绝；绑定不进业务备份|
|逐次明细|数量/整数次数的每次值、当地日期、时间/未知、备注，单条修改/删除与日总量同事务|旧总量只迁移为未知时间基线；总量改成明确调整事实；删除清除备注/值但保留幂等墓碑；负总量拒绝|
|周累计|自然周同历史计划版本累计数量/整数次数，目标文案、首页/组件/统计/提醒联动|与周达标天数区分；次日生效；休息/分段/不同单位不混算；不变成每日卡片义务|
|复盘卡|周/月、日期、最多6习惯、记录日数/真实数量、名称/心得选择、两幅新增原创画面、预览PNG/系统分享|名称和心得默认隐藏；未知历史不被虚构；不自动发送；无自由公式/无限编辑器|
|装扮|新增耳机/电脑/山野/钢笔4原创图标，杏色书房/海岸蓝绿2组合主题；原创启动/自适应/商店图标|基础图标/主题保留；不改变记录/计划/卡片资格|
|日历|提醒时刻旁直接交给系统事件编辑，下一次安排、固定星期/间隔重复、用户确认保存|无日历权限；取消不宣称成功；无日历显示系统提示；周目标单次安排；独立副本无双向同步|
|数据出口|schema12完整备份/恢复/回退，免费可读CSV，恢复预览含明细数|兼容schema2–11；runtime/item_revisions/收据/桌面绑定不导入；已有数据查看/纠正/导出不经付费锁|
|Play准备|Billing9.1.0一次性商品、真实商品价/恢复/待付款/取消/签名校验/确认购买/离线缓存；release配置/AAB/检查/隐私支持/商店材料|没有真实Console商品、公钥、签名和政策URL，不宣称实际付款或可直接上传；debug显式为测试权益|

## 工程命令与结果

所有工具通过本地scripts/dev.ps1与ignored配置，不改全局Java/SDK。

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 analyze
$plusTests = @('--no-pub','--concurrency=2') + @(rg --files test -g '*test.dart' | Where-Object { $_ -notlike '*process_recovery_test.dart' })
./scripts/dev.ps1 test -Extra $plusTests
./scripts/dev.ps1 test -Extra '--no-pub','--concurrency=1','test/process_recovery_test.dart'
./scripts/dev.ps1 test -Extra '--no-pub','--concurrency=2','test/plus_records_test.dart','test/plus_ui_test.dart','test/plus_panel_actions_test.dart'
./scripts/dev.ps1 test -Extra '--no-pub','--concurrency=2','test/backup_test.dart','test/pm04_backup_flow_test.dart','test/qa02_content_journeys_test.dart'
./scripts/dev.ps1 native-test -Extra '--offline'
./scripts/dev.ps1 assemble -Extra '--no-pub'
./scripts/dev.ps1 bundle -Extra '--offline'
python scripts/check-android-package.py build/app/outputs/bundle/release/app-release.aab
./scripts/dev.ps1 release-check
git diff --check
git diff --cached --check
```

- 常规整套434项通过4:10（plus-suite-final.log）；独立真实进程终止/恢复6项通过24秒（plus-process.log），共440个不同Flutter/Dart测试。
- 后续末次输入/CSV/显示修正受影响21项通过7秒（plus-input-final.log），提醒与界面25项通过10秒（plus-final-ui-rules.log），备份/预览/恢复内容37项通过1:02（plus-backup-ui-final.log）。均与整套重叠，不累加。
- 分析No issues found（plus-analyze-final.log）；格式化无未提交格式问题。JVM19项，0失败/0错误（包含日历/周累计5项）。
- 发布AAB构建成功，R8与lintVital完成；4个64位ELF库LOAD对齐通过16KB检查（plus-aab-16k.log）。这不是16KB真实内核运行验收；API36镜像当前为4KB。
- 发布资料检查按设计拒绝缺失`.local/play-release.properties`。AAB未签名（jarsigner检查），不是可直接上传文件。未生成假签名或代用户创建Play身份/收款资料。

### 失败记录与修复

1. schema12新增表后旧测试通过“把当前数据改成旧schema”模拟历史备份，必须去掉新表；旧库降级夹具必须先去掉schema12对象。真实v3夹具补回当时已有的kind列。没有为了兼容测试放宽strict备份。
2. 新对象修订触发器最初用INSERT OR IGNORE，与外层SQL冲突策略交互可使分组外键解除失败；改成NOT EXISTS插入，修订不会重置。新并发与分组回归通过。
3. 设备串行Activity重建复现SQLite持锁，主Dart引擎的生命周期与原生句柄不一致。主Activity复用引擎、解绑清桥，数量/配置仍显式关闭存储，后台写入仍关闭连接。随后API28全42通过。API36继续要求所有Flutter/原生连接明确使用WAL，避免journal_mode切换竞争；API35+快照采用官方只读DEFERRED事务，避免读查询争抢写锁；最终结果见设备段。debug与未配置商品时延迟创建Billing客户端，避免启动无用连接。
4. API36大字号重新加载旧RemoteViews时日期行49px超过42px，修正日期行高度；未缩小触区或放宽裁切断言。
5. API36隔离用户冷启动动作入队后仍在启动，原30秒断言窗口不足；独立干净用户用与产品后台任务相同的120秒窗口后真实提交/重复/旧绑定断言通过（104.909秒），不是跳过断言或人为直接改库。初始API36部分动作测试没有真正进入桌面（新用户未完成设置/锁屏/异步Activity启动）；完成临时用户设置、明确主页面已启动并启动HOME，再保留“后台动作后仍是Launcher”的断言，不把前置失败当产品通过。
6. 官方Flutter发布x86_64依赖下载停滞。分段从同一Google Storage地址取回42551087bytes并核对响应CRC32C；本地缓存注册仅在ignored目录，使用正常release Gradle任务完成。无第三方替换二进制或跳过编译。
7. 一次命令误写不存在的backup_ui_test.dart而未加载，保留失败日志；随后实际backup_test/pm04_backup_flow/内容组合37项完整通过。
8. 两模拟器同开期间API28系统与控制台失联，停止卡住进程保留镜像；未wipe、未覆盖镜像。重启后的主用户保留结果见设备段。该环境异常不包装成App全设备稳定证据。

## 实际设备

业务写入只在临时Android用户。主用户安装前关闭进程归档数据库，结束比对原表。日期展示使用设备当时日期；主机记录日期2026-11-11，未人为改系统日期凑跨日。

API28实际操作：阅读本次3→改单条4→新增2总量6→删第二条回4；周累计3次在一天记3后本周3/3；组合系统添加、布尔/常驻连续动作不串、数量取消、查看全部、真实拖动缩小、英文深色320dp160%、恢复后重新配置；日历无日历提示/本地测试日历/先取消再保存；周复盘真实PNG保存并取回目视；CSV和schema12文件取回检查，恢复预览取消与确认后的逐次明细/总量一致。

API28原生回归使用11类：PanelDeviceTest、PlusPurchaseDeviceTest、ReminderEngineTest、CompletionFeedbackDeviceTest、WidgetSnapshotTest、WidgetLifecycleTest、LegacyReaderTest、CardImageDeviceTest、WidgetDirectActionDeviceTest、WidgetPinDeviceTest、WidgetVisualTest（包前缀app.daypanel.next，相应widgets/reminders/importing子包）。runner命令：

```powershell
& $adb -s emulator-5554 shell am instrument --user 10 -w -e class $classes app.daypanel.next.debug.test/androidx.test.runner.AndroidJUnitRunner
# API36同一组，将设备改为emulator-5556；每次等待用户解锁/Launcher就绪。
```

已确认API28生命周期修复后42项通过56.704秒（plus-api28-lifecycle-final.log）。API36只读事务修复后的整轮42项已完成，41通过、1项在原生测试准备数据的8秒写锁等待失败，业务动作尚未执行（plus-api36-readonly-final.log，536.22秒）。受影响组件组使用与冷启动任务一致的120秒等待再次验证；断言未删、未忽略，最终结果及API28收尾见下方。购买签名用真实RSA生成/验签的本地测试；没有把它当Play支付交易。

## 截图

以下为临时用户真实API28截图；详细时间与操作在ignored plus-device-results.jsonl。

|场景|文件|
|---|---|
|每次记录真实时间与总量|[查看](evidence/plus/plus-device-records.webp)|
|两次记录合计6|[查看](evidence/plus/plus-device-events-6.webp)|
|删除第二条后回4|[查看](evidence/plus/plus-device-events-delete.webp)|
|组合桌面缩放后四事项|[查看](evidence/plus/plus-final-panel-compact.webp)|
|不同事项连续撤销|[查看](evidence/plus/plus-final-panel-two-actions.webp)|
|恢复重选后英文深色大字号|[查看](evidence/plus/plus-final-panel-en-large.webp)|
|系统日历真实事件草稿|[查看](evidence/plus/plus-device-calendar-draft.webp)|
|恢复后逐次明细与总量|[查看](evidence/plus/plus-final-restored-events.webp)|
|最终包系统保存的真实周复盘PNG|[查看](evidence/plus/plus-final-saved-review.webp)|

plus-en-event-keyboard、plus-en-panel-config、plus-en-review-card为加载项目书页字体的Flutter实际渲染，非实体设备截图；保存在同一evidence/plus目录并单独说明。商店应使用最终release真实设备截图，当前没有上传。

## 仍需外部完成

- 真实Google Play开发者身份/收款、正式包名确认、商品、公钥、上传密钥、支持联系/公开隐私政策；license tester实际买/取消/待付款/退款/恢复；封闭测试及生产访问/审核。
- 当前签名验证在设备端并离线缓存；Google建议服务端验证，本项目未擅自新增业务云。离线不能即时知晓退款，成功连接Play查询后核对权益。不能宣称抗修改客户端/防破解。
- Billing依赖带入BILLING、INTERNET、ACCESS_NETWORK_STATE和Google支付诊断传输组件；没有接入产品使用分析/广告SDK。Data safety与公开政策要依据最终SDK和发行者服务核定，不能仅凭“本机记录”勾无任何数据处理。
- 实体手机/TalkBack手工、其它厂商Launcher/省电、自然午夜/完整周、真实16KB内核、第二台实际换机、规模性能尚未完整验收。当前没有云/账号/社交/AI/专注或订阅。

## 最终产物与收尾

API36最后受影响组件11项全部通过205.997秒（plus-api36-final-affected.log），与此前42项中其它31项通过合并覆盖全部42个原生用例；这不是一次42/42零失败运行，失败与修复过程保留。该模拟器为4KB页面，实际用户10/11均已停止删除，只剩主用户0；主用户本轮前后均无databases目录（仅cache/code_cache），不声称对不存在的数据库做了15表比较。初次归档长度判断误把tar错误前缀当文件，结尾已检查tar头识别并保留错误证据，主用户目录确认无业务库。

最终本机产物：

- APK：`build/app/outputs/flutter-apk/app-debug.apk`，195360749 bytes，SHA-256 `e4b32f6cf62817486e021f55f9213f784fe1cbaef291c35db55618fac91256f8`。
- AAB：`build/app/outputs/bundle/release/app-release.aab`，73745205 bytes，SHA-256 `8bf7b822077426d2b6d13ecbba0ad0ad6bd48fa8a1e1fdf22dfe54d15db08842`；未配置真实签名，明确未签名。

API28重启并覆盖最终包后11类42项原生测试全部通过37.008秒（plus-api28-final-matrix.log）；没有忽略失败或删断言。API28最终已切回用户0并停止删除测试用户10，只剩主用户；主用户打开正常，关闭后归档post-plus-db.tar，与pre-plus-db.tar逐表比较 **原15张表全部字段一致**（含runtime generation/revision），SQLite11→12，FK检查空、integrity_check=ok。该主用户没有数字记录，所以迁移基线0；真实数字旧备份迁移由专项测试和设备临时用户验证（plus-retention-final.log）。用户要求完成后关机；文件/代码保存和提交后执行非强制关机，不推送远端。真实Play账号等外部步骤仍待资料，不能把本轮代码完成称为已正式上架。
