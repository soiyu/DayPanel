# Loop文件格式兼容边界

2026-11-06，独立格式适配记录。参考Loop v2.3.2 commit `7afc799cfb6959f8a9d892417d6427a262bfb13a` 的字段/枚举声明及本地只读SQLite结构检查，无源码/算法/测试文件复制。新测试使用本项目生成的合成数据。

- user_version21/22：Habits包含id/name/type/target_type/target_value/unit/freq_num/freq_den/archived/position/description及提醒、配色等；Repetitions包含id/habit/timestamp/value。
- v23增加question（早期description含问题）；v24增加uuid；v25增加Repetitions.notes。实际检查了上游021/022结构与旧DayPanel导出v25结构；23/24以固定迁移的列声明核对。
- HabitType0布尔/1数值；TargetType0至少/1至多；布尔Entry -1未知/0未完成/1自动覆盖/2手动完成/3跳过。数量整数为千分位，不能借用布尔枚举解释。
- SQLite时间戳是UTC午夜日编码；Repetitions是原始记录；Checkmarks、Scores、Streak等派生表不迁移。
- 不支持旧12库、其他App SQLite、CSV、加密库、活跃WAL拷贝、双库ZIP、>8MiB。应从旧App正式导出.db；未知版本或结构拒绝。
- 本实现不复现Loop滚动频率、得分、连续算法；不宣称已实现GPL许可证结论，最终分发审查保持独立。
