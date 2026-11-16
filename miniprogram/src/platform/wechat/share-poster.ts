import { evidenceOf } from '../../domain/achievement.ts';
import type { AchievementCard } from '../../domain/models.ts';

declare const wx: any;
declare const uni: any;

const WIDTH = 600;
const HEIGHT = 800;

const BACKGROUNDS = [
  '#e0f2fe',
  '#fef3c7',
  '#ecfdf5',
  '#f5f3ff',
  '#fff1f2',
  '#f1f5f9',
];

function drawWrapped(
  ctx: any,
  text: string,
  x: number,
  y: number,
  maxWidth: number,
  lineHeight: number,
  maxLines: number,
): number {
  const chars = [...text];
  let line = '';
  let lines = 0;
  let cursorY = y;
  for (const char of chars) {
    const test = line + char;
    const width =
      typeof ctx.measureText === 'function'
        ? ctx.measureText(test).width
        : test.length * 14;
    if (width > maxWidth && line) {
      ctx.fillText(line, x, cursorY);
      cursorY += lineHeight;
      lines += 1;
      line = char;
      if (lines >= maxLines) return cursorY;
    } else {
      line = test;
    }
  }
  if (line) {
    ctx.fillText(line, x, cursorY);
    cursorY += lineHeight;
  }
  return cursorY;
}

export async function shareCardPoster(card: AchievementCard): Promise<void> {
  const canvasId = 'posterCanvas';
  const ctx = uni.createCanvasContext(canvasId);
  const bg = BACKGROUNDS[card.artwork % BACKGROUNDS.length];

  ctx.setFillStyle(bg);
  ctx.fillRect(0, 0, WIDTH, HEIGHT);
  ctx.setFillStyle('rgba(255,255,255,0.55)');
  ctx.fillRect(36, 36, WIDTH - 72, HEIGHT - 72);
  ctx.setFillStyle('#0f172a');
  ctx.setFontSize(44);
  ctx.fillText('DayPanel', 72, 110);
  ctx.setFontSize(26);
  ctx.setFillStyle('#475569');
  ctx.fillText(card.day, 72, 152);

  ctx.setFontSize(52);
  ctx.setFillStyle('#0f172a');
  ctx.fillText(card.favorite ? '收藏卡片' : '成就卡片', 72, 238);

  ctx.setFontSize(24);
  ctx.setFillStyle('#64748b');
  ctx.fillText('完成快照', 72, 282);

  ctx.setFontSize(28);
  ctx.setFillStyle('#1e293b');
  let y = 322;
  for (const item of evidenceOf(card)) {
    const suffix =
      item.kind === 'check' ? '' : ` ${item.unit ? item.unit : ''}`.trimEnd();
    y = drawWrapped(ctx, `· ${item.title}${suffix}`, 72, y, WIDTH - 144, 42, 2);
    if (y > 560) break;
  }

  if (card.reflection) {
    ctx.setFillStyle('rgba(15,23,42,0.06)');
    ctx.fillRect(56, 580, WIDTH - 112, 2);
    ctx.setFontSize(24);
    ctx.setFillStyle('#64748b');
    ctx.fillText('心得', 72, 626);
    ctx.setFontSize(26);
    ctx.setFillStyle('#334155');
    drawWrapped(ctx, card.reflection, 72, 666, WIDTH - 144, 38, 2);
  }

  ctx.setFontSize(20);
  ctx.setFillStyle('#94a3b8');
  ctx.fillText('记录真实的一天', 72, HEIGHT - 52);

  await new Promise<void>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('draw_timeout')), 4000);
    ctx.draw(false, () => {
      clearTimeout(timer);
      resolve();
    });
  });

  const path: string = await new Promise((resolve, reject) => {
    wx.canvasToTempFilePath({
      canvasId,
      destWidth: WIDTH * 2,
      destHeight: HEIGHT * 2,
      success: (result: any) => resolve(result.tempFilePath),
      fail: (error: any) => reject(new Error(error?.errMsg ?? 'canvas_failed')),
    });
  });

  try {
    await wx.showShareImageMenu({ path });
  } catch {
    await uni.saveImageToPhotosAlbum({ filePath: path });
  }
}