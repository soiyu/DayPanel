<script setup lang="ts">
import { onLaunch } from '@dcloudio/uni-app';

onLaunch(() => {
  // CloudBase is initialized lazily by the gateway. No local business data is
  // read here; the first page load fetches today's cloud snapshot.
});
</script>

<style>
page {
  background: #f8fafc;
  color: #0f172a;
  font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', 'Microsoft YaHei', sans-serif;
}
</style>