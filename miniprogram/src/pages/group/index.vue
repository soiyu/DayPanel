<template>
  <view class="page" :class="themeClass">
    <view class="hero">
      <view>
        <text class="title">{{ group ? group.name : t('groups') }}</text>
        <text class="hint">{{ t('groupNote') }}</text>
      </view>
      <button v-if="!group" class="ghost" @tap="createGroup">{{ t('createGroup') }}</button>
    </view>

    <view v-if="loading" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="error" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <text class="state-body">{{ error }}</text>
      <button class="primary" @tap="reload">{{ t('retry') }}</button>
    </view>

    <template v-else-if="group">
      <view class="group-card">
        <view class="group-row">
          <text class="label">{{ t('groupCode') }}</text>
          <text class="code" @tap="copyCode">{{ group.code }}</text>
        </view>
        <view class="group-row">
          <text class="label">{{ t('groupMembers') }}</text>
          <text class="value">{{ home?.group.memberCount ?? group.memberCount }}</text>
        </view>
        <view class="group-row">
          <text class="label">{{ t('groupToday') }}</text>
          <text class="value">{{ totalRecords }}</text>
        </view>
        <button class="share" open-type="share">{{ t('groupShare') }}</button>
      </view>

      <view class="section">
        <text class="section-title">{{ t('groupToday') }}</text>
        <view v-for="member in home?.members ?? []" :key="member.label" class="member">
          <text class="member-name">{{ member.label }}{{ member.isMe ? '（我）' : '' }}</text>
          <text class="member-count">{{ member.records }}</text>
        </view>
      </view>
    </template>

    <view v-else-if="groups.length === 0" class="state">
      <text class="state-title">{{ t('noGroups') }}</text>
      <text class="state-body">{{ t('joinGroup') }}</text>
    </view>

    <view v-else class="list">
      <view v-for="item in groups" :key="item.id" class="group" @tap="openGroup(item.code)">
        <view class="group-main">
          <text class="group-name">{{ item.name }}</text>
          <text class="group-meta">{{ item.code }} · {{ item.memberCount || 1 }} {{ t('groupMembers') }}</text>
        </view>
        <text class="arrow">›</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { onLoad, onShareAppMessage, onShow } from '@dcloudio/uni-app';
import {
  WechatCloudGateway,
  type GroupHomeView,
  type GroupSummary,
} from '../../data/wechat-gateway.ts';
import { useTodayStore } from '../../stores/today.ts';
import { useThemeClass } from '../../composables/useTheme.ts';

const gateway = new WechatCloudGateway();
const today = useTodayStore();
const themeClass = useThemeClass();
const t = (key: Parameters<typeof today.tr>[0]) => today.tr(key);
const code = ref('');
const group = ref<GroupSummary | null>(null);
const home = ref<GroupHomeView | null>(null);
const groups = ref<GroupSummary[]>([]);
const loading = ref(false);
const error = ref('');

const totalRecords = computed(() =>
  (home.value?.members ?? []).reduce((sum, member) => sum + member.records, 0),
);

onLoad(async (options: Record<string, string | undefined>) => {
  code.value = String(options?.code ?? '').toUpperCase();
  if (code.value) {
    loading.value = true;
    try {
      group.value = await gateway.joinGroup(code.value);
      home.value = await gateway.groupHome(code.value);
    } catch {
      error.value = '群组链接无效或已失效';
    } finally {
      loading.value = false;
    }
  }
});

onShow(async () => {
  if (code.value) return;
  await today.load();
  try {
    groups.value = await gateway.myGroups();
  } catch {
    groups.value = [];
  }
});

onShareAppMessage(() => ({
  title: group.value ? `一起打卡：${group.value.name}` : 'DayPanel 群组打卡',
  path: group.value
    ? `/pages/group/index?code=${encodeURIComponent(group.value.code)}`
    : '/pages/group/index',
}));

async function reload(): Promise<void> {
  error.value = '';
  if (code.value) {
    try {
      group.value = await gateway.joinGroup(code.value);
      home.value = await gateway.groupHome(code.value);
    } catch {
      error.value = '群组链接无效或已失效';
    }
  } else {
    groups.value = await gateway.myGroups();
  }
}

async function createGroup(): Promise<void> {
  const result: any = await new Promise((resolve) => {
    uni.showModal({
      title: t('createGroup'),
      editable: true,
      placeholderText: t('groupName'),
      success: resolve,
      fail: resolve,
    });
  });
  const name = String(result?.content ?? '').trim();
  if (!result?.confirm || !name) return;
  try {
    const created = await gateway.createGroup(name);
    code.value = created.code;
    group.value = created;
    home.value = await gateway.groupHome(created.code);
  } catch {
    uni.showToast({ title: '创建失败', icon: 'none' });
  }
}

async function openGroup(value: string): Promise<void> {
  code.value = value;
  group.value = await gateway.joinGroup(value);
  home.value = await gateway.groupHome(value);
}

function copyCode(): void {
  if (!group.value) return;
  uni.setClipboardData({ data: group.value.code });
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 80rpx;
  box-sizing: border-box;
  background: var(--dp-bg);
}
.hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16rpx;
  margin-bottom: 18rpx;
}
.title {
  display: block;
  font-size: 46rpx;
  font-weight: 800;
  color: var(--dp-ink);
}
.hint {
  display: block;
  margin-top: 6rpx;
  font-size: 22rpx;
  color: var(--dp-muted);
  line-height: 1.5;
}
.ghost,
.primary,
.share {
  border-radius: 999rpx;
  font-size: 24rpx;
  line-height: 1;
  padding: 16rpx 22rpx;
  border: none;
}
.ghost {
  background: var(--dp-accent-soft);
  color: var(--dp-accent-ink);
  font-weight: 700;
}
.primary {
  background: var(--dp-accent);
  color: var(--dp-on-accent);
}
.share {
  background: var(--dp-accent);
  color: var(--dp-on-accent);
  width: 100%;
  margin-top: 18rpx;
  font-weight: 700;
}
.state {
  min-height: 40vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 14rpx;
  color: var(--dp-muted);
}
.state-title {
  font-size: 30rpx;
  font-weight: 700;
  color: var(--dp-ink);
}
.state-body {
  font-size: 23rpx;
  text-align: center;
}
.group-card {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 22rpx;
  margin-bottom: 18rpx;
}
.group-row {
  display: flex;
  justify-content: space-between;
  min-height: 64rpx;
  align-items: center;
  border-bottom: 1rpx solid var(--dp-soft);
}
.group-row:last-of-type {
  border-bottom: none;
}
.label {
  font-size: 24rpx;
  color: var(--dp-muted);
}
.code,
.value {
  font-size: 25rpx;
  font-weight: 700;
  color: var(--dp-accent-ink);
  letter-spacing: 2rpx;
}
.section {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 18rpx 22rpx;
}
.section-title {
  display: block;
  font-size: 23rpx;
  color: var(--dp-muted);
  margin-bottom: 10rpx;
}
.member {
  display: flex;
  justify-content: space-between;
  min-height: 56rpx;
  align-items: center;
  border-bottom: 1rpx solid var(--dp-soft);
}
.member:last-child {
  border-bottom: none;
}
.member-name {
  font-size: 25rpx;
  color: var(--dp-ink);
}
.member-count {
  font-size: 25rpx;
  font-weight: 700;
  color: var(--dp-accent);
}
.list {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}
.group {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 22rpx;
  padding: 20rpx 22rpx;
  display: flex;
  align-items: center;
  gap: 16rpx;
}
.group-main {
  flex: 1;
  min-width: 0;
}
.group-name {
  display: block;
  font-size: 27rpx;
  font-weight: 700;
  color: var(--dp-ink);
}
.group-meta {
  display: block;
  margin-top: 4rpx;
  font-size: 21rpx;
  color: var(--dp-muted);
}
.arrow {
  font-size: 40rpx;
  color: var(--dp-faint);
}
</style>
