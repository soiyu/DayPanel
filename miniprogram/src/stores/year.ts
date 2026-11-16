import { ref } from 'vue';
import { defineStore } from 'pinia';
import { todayKey } from '../domain/day.ts';
import {
  GatewayError,
  WechatCloudGateway,
  type YearView,
} from '../data/wechat-gateway.ts';

export const useYearStore = defineStore('year', () => {
  const gateway = new WechatCloudGateway();
  const year = ref(Number(todayKey().slice(0, 4)));
  const data = ref<YearView | null>(null);
  const loading = ref(false);
  const error = ref<string | null>(null);

  async function load(next = year.value): Promise<void> {
    if (loading.value) return;
    year.value = next;
    loading.value = true;
    error.value = null;
    try {
      data.value = await gateway.year(next);
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
    } finally {
      loading.value = false;
    }
  }

  return { year, data, loading, error, load };
});
