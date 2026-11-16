<template>
  <view class="page">
    <view class="hero">
      <text class="eyebrow">DayPanel</text>
      <text class="title">{{ t('mine') }}</text>
      <text class="body">云端存储 · 无导出 · 无客服</text>
    </view>

    <view class="card">
      <view class="row">
        <text class="row-title">{{ t('privacy') }}</text>
        <text class="row-arrow" @tap="openPrivacy">›</text>
      </view>
      <view class="row">
        <text class="row-title">{{ t('reminderDefaults') }}</text>
        <text class="row-meta">21:00</text>
      </view>
      <view class="row">
        <text class="row-title">云端状态</text>
        <text class="row-meta">{{ store.view ? '已连接' : store.error ? '未连接' : '加载中' }}</text>
      </view>
    </view>

    <view class="danger-card">
      <text class="danger-title">{{ t('deleteAccount') }}</text>
      <text class="danger-body">{{ t('deleteAccountHelp') }}</text>
      <button class="danger" :disabled="store.busy || !store.view" @tap="confirmDelete">
        {{ t('deleteAccount') }}
      </button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { onShow } from '@dcloudio/uni-app';
import { useTodayStore } from '../../stores/today.ts';

const store = useTodayStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);

function showModal(options: Record<string, unknown>): Promise<any> {
  return new Promise((resolve, reject) => {
    uni.showModal({
      ...options,
      success: resolve,
      fail: reject,
    } as any);
  });
}

onShow(() => {
  void store.load();
});

function openPrivacy(): void {
  uni.navigateTo({ url: '/pages/settings/privacy' });
}

async function confirmDelete(): Promise<void> {
  if (!store.view || store.busy) return;
  const first = await showModal({
    title: t('deleteAccount'),
    content: `${t('deleteAccountHelp')}\n\n${t('deleteAccountWarning')}`,
    confirmText: t('deleteAccountConfirm'),
    cancelText: t('cancel'),
    confirmColor: '#be123c',
  });
  if (!first.confirm) return;

  const second = await showModal({
    title: t('deleteAccountConfirm'),
    content: '请输入“注销”以确认',
    editable: true,
    placeholderText: '注销',
    confirmText: t('deleteAccountConfirm'),
    cancelText: t('cancel'),
    confirmColor: '#be123c',
  });
  if (!second.confirm || String(second.content ?? '').trim() !== '注销') {
    uni.showToast({ title: '未注销', icon: 'none' });
    return;
  }

  const ok = await store.deleteAccount();
  if (!ok) {
    uni.showToast({ title: t('deleteAccountFailed'), icon: 'none' });
    return;
  }
  uni.showToast({ title: '已注销', icon: 'success' });
  setTimeout(() => {
    uni.reLaunch({ url: '/pages/today/index' });
  }, 400);
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 80rpx;
  box-sizing: border-box;
}
.hero {
  margin-bottom: 28rpx;
}
.eyebrow {
  display: block;
  font-size: 22rpx;
  color: #64748b;
  letter-spacing: 2rpx;
  margin-bottom: 6rpx;
}
.title {
  display: block;
  font-size: 56rpx;
  font-weight: 800;
}
.body {
  display: block;
  margin-top: 8rpx;
  color: #64748b;
  font-size: 24rpx;
}
.card,
.danger-card {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 28rpx;
  padding: 8rpx 24rpx;
  box-shadow: 0 10rpx 30rpx rgba(15, 23, 42, 0.05);
  margin-bottom: 24rpx;
}
.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-height: 96rpx;
  border-bottom: 1rpx solid #f1f5f9;
}
.row:last-child {
  border-bottom: none;
}
.row-title {
  font-size: 28rpx;
  color: #0f172a;
}
.row-meta,
.row-arrow {
  font-size: 24rpx;
  color: #64748b;
}
.row-arrow {
  font-size: 42rpx;
  line-height: 1;
}
.danger-card {
  padding: 28rpx 24rpx;
  border-color: #fecdd3;
}
.danger-title {
  display: block;
  font-size: 28rpx;
  font-weight: 700;
  color: #be123c;
}
.danger-body {
  display: block;
  margin: 10rpx 0 20rpx;
  font-size: 24rpx;
  color: #64748b;
  line-height: 1.6;
}
.danger {
  background: #be123c;
  color: #fff;
  border-radius: 999rpx;
  font-size: 26rpx;
  line-height: 1;
  padding: 20rpx 0;
  border: none;
}
.danger[disabled] {
  opacity: 0.45;
}
</style>