import { ref } from 'vue';
import { defineStore } from 'pinia';
import type { AchievementCard } from '../domain/models.ts';
import {
  GatewayError,
  WechatCloudGateway,
} from '../data/wechat-gateway.ts';

export const useCardsStore = defineStore('cards', () => {
  const gateway = new WechatCloudGateway();
  const cards = ref<AchievementCard[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  async function load(): Promise<void> {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    try {
      cards.value = await gateway.cards();
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
    } finally {
      loading.value = false;
    }
  }

  return { cards, loading, error, load };
});
