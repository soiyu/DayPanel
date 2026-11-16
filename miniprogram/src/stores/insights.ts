import { ref } from 'vue';
import { defineStore } from 'pinia';
import {
  GatewayError,
  WechatCloudGateway,
} from '../data/wechat-gateway.ts';
import type { Insights, InsightRange } from '../domain/insights.ts';

export const useInsightsStore = defineStore('insights', () => {
  const gateway = new WechatCloudGateway();
  const range = ref<InsightRange>(30);
  const data = ref<Insights | null>(null);
  const loading = ref(false);
  const error = ref<string | null>(null);

  async function load(next: InsightRange = range.value): Promise<void> {
    if (loading.value) return;
    range.value = next;
    loading.value = true;
    error.value = null;
    try {
      data.value = await gateway.insights(next);
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
    } finally {
      loading.value = false;
    }
  }

  return { range, data, loading, error, load };
});
