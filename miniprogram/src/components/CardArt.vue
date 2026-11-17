<template>
  <view class="art" :class="[`art-${artwork}`, { compact }]">
    <view v-if="artwork === 0" class="dawn">
      <view class="sun" />
      <view class="hill hill-back" />
      <view class="hill hill-front" />
      <view class="cloud cloud-a" />
      <view class="cloud cloud-b" />
    </view>

    <view v-else-if="artwork === 1" class="plant">
      <view class="leaf leaf-left" />
      <view class="leaf leaf-right" />
      <view class="stem" />
      <view class="pot" />
      <view class="root root-a" />
      <view class="root root-b" />
      <view class="root root-c" />
    </view>

    <view v-else-if="artwork === 2" class="river">
      <view class="bank bank-left" />
      <view class="bank bank-right" />
      <view class="water water-a" />
      <view class="water water-b" />
      <view class="water water-c" />
    </view>

    <view v-else-if="artwork === 3" class="stairs">
      <view class="step step-1" />
      <view class="step step-2" />
      <view class="step step-3" />
      <view class="step step-4" />
      <view class="stairs-sun" />
    </view>

    <view v-else-if="artwork === 4" class="window">
      <view class="window-frame" />
      <view class="window-pane pane-a" />
      <view class="window-pane pane-b" />
      <view class="window-pane pane-c" />
      <view class="window-pane pane-d" />
      <view class="window-light" />
    </view>

    <view v-else class="stars">
      <view class="star star-1" />
      <view class="star star-2" />
      <view class="star star-3" />
      <view class="star star-4" />
      <view class="star star-5" />
      <view class="star star-6" />
      <view class="moon" />
    </view>
  </view>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    artwork: number;
    compact?: boolean;
  }>(),
  { compact: false },
);
</script>

<style scoped>
.art {
  position: relative;
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: #edf3ff;
}
.art.compact {
  background: #edf3ff;
}
.dawn,
.plant,
.river,
.stairs,
.window,
.stars {
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
}
.dawn {
  background: linear-gradient(180deg, #dbeafe, #ede9fe);
}
.sun {
  position: absolute;
  right: 16%;
  top: 12%;
  width: 18%;
  height: 30%;
  border-radius: 50%;
  background: #f2c49f;
}
.hill {
  position: absolute;
  bottom: -28%;
  width: 82%;
  height: 78%;
  border-radius: 50% 50% 0 0;
}
.hill-back {
  left: -18%;
  background: #b7a4e7;
  transform: rotate(7deg);
}
.hill-front {
  right: -20%;
  bottom: -34%;
  background: #5885d9;
  transform: rotate(-5deg);
}
.cloud {
  position: absolute;
  height: 5%;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.75);
}
.cloud-a {
  left: 10%;
  top: 22%;
  width: 18%;
}
.cloud-b {
  left: 14%;
  top: 30%;
  width: 26%;
}
.plant {
  background: linear-gradient(180deg, #f1f5f9, #e2e8f0);
}
.stem {
  position: absolute;
  left: 48%;
  bottom: 30%;
  width: 4%;
  height: 42%;
  border-radius: 999px;
  background: #5885d9;
}
.leaf {
  position: absolute;
  width: 26%;
  height: 22%;
  background: #b7a4e7;
  border-radius: 80% 0 80% 0;
}
.leaf-left {
  left: 24%;
  top: 28%;
  transform: rotate(-18deg);
}
.leaf-right {
  right: 18%;
  top: 18%;
  background: #5885d9;
  transform: rotate(22deg);
}
.pot {
  position: absolute;
  left: 32%;
  bottom: 18%;
  width: 36%;
  height: 24%;
  background: #f2c49f;
  border-radius: 6% 6% 14% 14%;
}
.root {
  position: absolute;
  bottom: 6%;
  width: 3%;
  height: 16%;
  background: #dbeafe;
  border-radius: 999px;
}
.root-a { left: 42%; transform: rotate(12deg); }
.root-b { left: 50%; transform: rotate(-8deg); }
.root-c { left: 58%; transform: rotate(18deg); }
.river {
  background: linear-gradient(180deg, #ede9fe 0 42%, #dbeafe 42% 100%);
}
.bank {
  position: absolute;
  bottom: 0;
  width: 52%;
  height: 54%;
  background: #b7a4e7;
  border-radius: 50% 50% 0 0;
}
.bank-left {
  left: -20%;
  transform: rotate(8deg);
}
.bank-right {
  right: -20%;
  background: #5885d9;
  transform: rotate(-8deg);
}
.water {
  position: absolute;
  left: 8%;
  right: 8%;
  height: 5%;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.58);
}
.water-a { top: 56%; }
.water-b { top: 68%; left: 18%; right: 20%; }
.water-c { top: 80%; left: 24%; right: 12%; }
.stairs {
  background: linear-gradient(160deg, #fff7ed, #fef3c7);
}
.step {
  position: absolute;
  bottom: 0;
  background: #c2410c;
  border-radius: 4% 4% 0 0;
}
.step-1 { left: 4%; width: 20%; height: 20%; opacity: 0.55; }
.step-2 { left: 24%; width: 22%; height: 34%; opacity: 0.7; }
.step-3 { left: 46%; width: 24%; height: 50%; opacity: 0.85; }
.step-4 { left: 70%; width: 26%; height: 66%; }
.stairs-sun {
  position: absolute;
  right: 12%;
  top: 12%;
  width: 16%;
  height: 26%;
  border-radius: 50%;
  background: #f59e0b;
  opacity: 0.7;
}
.window {
  background: linear-gradient(180deg, #f5f3ff, #e0e7ff);
}
.window-frame {
  position: absolute;
  left: 18%;
  right: 18%;
  top: 12%;
  bottom: 12%;
  border: 8rpx solid #6d28d9;
  border-radius: 12rpx;
  box-sizing: border-box;
}
.window-pane {
  position: absolute;
  top: 12%;
  bottom: 12%;
  width: 2rpx;
  background: #6d28d9;
}
.pane-a { left: 50%; }
.pane-b { left: 18%; right: 18%; top: 50%; width: auto; height: 2rpx; }
.pane-c { left: 15%; top: 24%; width: 10%; height: 12%; background: #c4b5fd; border-radius: 50%; }
.pane-d { right: 15%; bottom: 24%; width: 14%; height: 10%; background: #a78bfa; border-radius: 50%; }
.window-light {
  position: absolute;
  left: 30%;
  right: 30%;
  bottom: 4%;
  height: 8%;
  background: rgba(255, 255, 255, 0.7);
  border-radius: 50%;
}
.stars {
  background: linear-gradient(180deg, #0f172a, #1e293b 55%, #312e81);
}
.star {
  position: absolute;
  width: 4rpx;
  height: 4rpx;
  border-radius: 50%;
  background: #f8fafc;
}
.star-1 { left: 18%; top: 22%; width: 6rpx; height: 6rpx; }
.star-2 { left: 34%; top: 40%; }
.star-3 { left: 62%; top: 18%; width: 7rpx; height: 7rpx; }
.star-4 { left: 74%; top: 46%; }
.star-5 { left: 46%; top: 66%; width: 6rpx; height: 6rpx; }
.star-6 { left: 26%; top: 62%; }
.moon {
  position: absolute;
  right: 18%;
  top: 16%;
  width: 18%;
  height: 30%;
  border-radius: 50%;
  background: #e0e7ff;
  opacity: 0.85;
}
</style>