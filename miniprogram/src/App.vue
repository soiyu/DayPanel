<script setup lang="ts">
import { onLaunch } from '@dcloudio/uni-app';
import { useThemeStore } from './stores/theme.ts';

onLaunch(() => {
  // CloudBase is initialized lazily by the gateway. No local business data is
  // read here; the first page load fetches today's cloud snapshot.
  void useThemeStore().load();
});
</script>

<style>
page {
  background: #f8fafc;
  color: #0f172a;
  font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', 'Microsoft YaHei', sans-serif;
}

.page {
  --dp-bg: #f8fafc;
  --dp-paper: #ffffff;
  --dp-ink: #0f172a;
  --dp-ink-2: #1e293b;
  --dp-ink-3: #334155;
  --dp-ink-4: #475569;
  --dp-muted: #64748b;
  --dp-faint: #94a3b8;
  --dp-line: #e2e8f0;
  --dp-soft: #f1f5f9;
  --dp-accent: #2563eb;
  --dp-accent-ink: #1d4ed8;
  --dp-accent-soft: #eff6ff;
  --dp-violet: #6d28d9;
  --dp-violet-soft: #f5f3ff;
  --dp-teal: #047857;
  --dp-teal-soft: #ecfdf5;
  --dp-rose: #be123c;
  --dp-rose-soft: #fff1f2;
  --dp-orange: #c2410c;
  --dp-orange-soft: #fff7ed;
  --dp-on-accent: #ffffff;
  --dp-bg-translucent: rgba(248, 250, 252, 0.96);
  --dp-shadow: rgba(15, 23, 42, 0.05);
  --dp-shadow-soft: rgba(15, 23, 42, 0.04);
  --dp-icon-radius: 20rpx;
  --dp-icon-border: 0;
  --dp-art-base: #edf3ff;
  --dp-art-dawn-bg: linear-gradient(180deg, #dbeafe, #ede9fe);
  --dp-art-sun: #f2c49f;
  --dp-art-hill-back: #b7a4e7;
  --dp-art-hill-front: #5885d9;
  --dp-art-cloud: rgba(255, 255, 255, 0.75);
  --dp-art-plant-bg: linear-gradient(180deg, #f1f5f9, #e2e8f0);
  --dp-art-stem: #5885d9;
  --dp-art-leaf-a: #b7a4e7;
  --dp-art-leaf-b: #5885d9;
  --dp-art-pot: #f2c49f;
  --dp-art-root: #dbeafe;
  --dp-art-river-bg: linear-gradient(180deg, #ede9fe 0 42%, #dbeafe 42% 100%);
  --dp-art-bank-a: #b7a4e7;
  --dp-art-bank-b: #5885d9;
  --dp-art-water: rgba(255, 255, 255, 0.58);
  --dp-art-stairs-bg: linear-gradient(160deg, #fff7ed, #fef3c7);
  --dp-art-step: #c2410c;
  --dp-art-stairs-sun: #f59e0b;
  --dp-art-window-bg: linear-gradient(180deg, #f5f3ff, #e0e7ff);
  --dp-art-window-frame: #6d28d9;
  --dp-art-window-pane: #c4b5fd;
  --dp-art-window-light: rgba(255, 255, 255, 0.7);
  --dp-art-stars-bg: linear-gradient(180deg, #0f172a, #1e293b 55%, #312e81);
  --dp-art-star: #f8fafc;
  --dp-art-moon: #e0e7ff;
}
.page.frame-soft {
  --dp-icon-radius: 20rpx;
  --dp-icon-border: 0;
  --dp-art-base: #edf3ff;
  --dp-art-dawn-bg: linear-gradient(180deg, #dbeafe, #ede9fe);
  --dp-art-sun: #f2c49f;
  --dp-art-hill-back: #b7a4e7;
  --dp-art-hill-front: #5885d9;
  --dp-art-cloud: rgba(255, 255, 255, 0.75);
  --dp-art-plant-bg: linear-gradient(180deg, #f1f5f9, #e2e8f0);
  --dp-art-stem: #5885d9;
  --dp-art-leaf-a: #b7a4e7;
  --dp-art-leaf-b: #5885d9;
  --dp-art-pot: #f2c49f;
  --dp-art-root: #dbeafe;
  --dp-art-river-bg: linear-gradient(180deg, #ede9fe 0 42%, #dbeafe 42% 100%);
  --dp-art-bank-a: #b7a4e7;
  --dp-art-bank-b: #5885d9;
  --dp-art-water: rgba(255, 255, 255, 0.58);
  --dp-art-stairs-bg: linear-gradient(160deg, #fff7ed, #fef3c7);
  --dp-art-step: #c2410c;
  --dp-art-stairs-sun: #f59e0b;
  --dp-art-window-bg: linear-gradient(180deg, #f5f3ff, #e0e7ff);
  --dp-art-window-frame: #6d28d9;
  --dp-art-window-pane: #c4b5fd;
  --dp-art-window-light: rgba(255, 255, 255, 0.7);
  --dp-art-stars-bg: linear-gradient(180deg, #0f172a, #1e293b 55%, #312e81);
  --dp-art-star: #f8fafc;
  --dp-art-moon: #e0e7ff;
}
.page.frame-ring {
  --dp-icon-radius: 50%;
  --dp-icon-border: 3rpx solid var(--dp-accent);
}
.page.frame-plain {
  --dp-icon-radius: 0;
  --dp-icon-border: 0;
}
.page.palette-teal {
  --dp-accent: #0d7e73;
  --dp-accent-ink: #0f766e;
  --dp-accent-soft: #f0fdfa;
}
.page.palette-violet {
  --dp-accent: #7c3aed;
  --dp-accent-ink: #6d28d9;
  --dp-accent-soft: #f5f3ff;
}
.page.palette-apricot {
  --dp-accent: #a34d27;
  --dp-accent-ink: #9a431d;
  --dp-accent-soft: #fff7ed;
}
.page.palette-coast {
  --dp-accent: #0b7187;
  --dp-accent-ink: #086f83;
  --dp-accent-soft: #e6f5f6;
}
.page.theme-dark {
  --dp-bg: #0a0f1d;
  --dp-paper: #161f30;
  --dp-ink: #f1f5f9;
  --dp-ink-2: #e2e8f0;
  --dp-ink-3: #cbd5e1;
  --dp-ink-4: #94a3b8;
  --dp-muted: #94a3b8;
  --dp-faint: #64748b;
  --dp-line: #2a3649;
  --dp-soft: #1e293b;
  --dp-shadow: rgba(0, 0, 0, 0.35);
  --dp-shadow-soft: rgba(0, 0, 0, 0.25);
  --dp-teal-soft: #122620;
  --dp-rose-soft: #2a1620;
  --dp-orange-soft: #2a211d;
  --dp-bg-translucent: rgba(10, 15, 29, 0.96);
  --dp-art-base: #152a33;
  --dp-art-dawn-bg: linear-gradient(180deg, #1e293b, #312e81);
  --dp-art-sun: #f0bc8b;
  --dp-art-hill-back: #6d5fa3;
  --dp-art-hill-front: #3b5f9e;
  --dp-art-cloud: rgba(148, 163, 184, 0.35);
  --dp-art-plant-bg: linear-gradient(180deg, #152a33, #122620);
  --dp-art-stem: #7dd3fc;
  --dp-art-leaf-a: #a78bfa;
  --dp-art-leaf-b: #60a5fa;
  --dp-art-pot: #d9a06b;
  --dp-art-root: #1e3a4a;
  --dp-art-river-bg: linear-gradient(180deg, #1d162c 0 42%, #152a33 42% 100%);
  --dp-art-bank-a: #6d5fa3;
  --dp-art-bank-b: #3b5f9e;
  --dp-art-water: rgba(226, 232, 240, 0.35);
  --dp-art-stairs-bg: linear-gradient(160deg, #2a211d, #3a2a1f);
  --dp-art-step: #f0bc8b;
  --dp-art-stairs-sun: #fbbf24;
  --dp-art-window-bg: linear-gradient(180deg, #1d162c, #2a1f44);
  --dp-art-window-frame: #c4b5fd;
  --dp-art-window-pane: #7c6bb0;
  --dp-art-window-light: rgba(226, 232, 240, 0.25);
}
.page.theme-dark .earned-card,
.page.theme-dark .habit,
.page.theme-dark .card,
.page.theme-dark .month,
.page.theme-dark .field,
.page.theme-dark .task,
.page.theme-dark .note,
.page.theme-dark .event,
.page.theme-dark .job-card {
  color: var(--dp-ink);
}
.page.font-serif {
  font-family: 'Noto Serif SC', 'Songti SC', serif;
}
.page.elder-mode .title {
  font-size: 64rpx !important;
}
.page.elder-mode .habit-title,
.page.elder-mode .task-title,
.page.elder-mode .row-title,
.page.elder-mode .name {
  font-size: 34rpx !important;
}
.page.elder-mode .habit-meta,
.page.elder-mode .row-meta,
.page.elder-mode .task-meta,
.page.elder-mode .hint {
  font-size: 26rpx !important;
}
.page.elder-mode button {
  min-height: 96rpx;
}
.page.elder-mode .action,
.page.elder-mode .primary,
.page.elder-mode .ghost {
  font-size: 30rpx !important;
}
.page.theme-dark,
.page.theme-dark .page {
  background: var(--dp-bg);
  color: var(--dp-ink);
}
</style>