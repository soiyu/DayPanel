import { ref } from 'vue';
import { defineStore } from 'pinia';
import {
  GatewayError,
  WechatCloudGateway,
} from '../data/wechat-gateway.ts';
import type { HabitStat } from '../domain/stats.ts';

export const useStatsStore = defineStore('stats', () => {
  const gateway = new WechatCloudGateway();
  const rangeDays = ref(30);
  const stats = ref<HabitStat[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  async function load(range = rangeDays.value): Promise<void> {
    if (loading.value) return;
    rangeDays.value = range;
    loading.value = true;
    error.value = null;
    try {
      stats.value = await gateway.stats(range);
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
    } finally {
      loading.value = false;
    }
  }

  return { rangeDays, stats, loading, error, load };
});
