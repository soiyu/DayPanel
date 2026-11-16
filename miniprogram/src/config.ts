/**
 * Replace with the CloudBase environment id from the WeChat console. Leaving
 * it empty makes `wx.cloud.init()` use the default environment, which is fine
 * for local development but should be explicit before release.
 */
export const CLOUD_ENV = '';
export const CLOUD_FUNCTION = 'api';

/**
 * Public subscription-message template id from the MP console. Empty means
 * the digest/once actions are visibly disabled; do not fabricate a template.
 */
export const REMINDER_TEMPLATE_ID = '';