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
}
.page.frame-soft {
  --dp-icon-radius: 20rpx;
  --dp-icon-border: 0;
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
.page.theme-dark,
.page.theme-dark .page {
  background: var(--dp-bg);
  color: var(--dp-ink);
}
</style>