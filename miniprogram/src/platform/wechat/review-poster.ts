import type { Insights } from '../../domain/insights.ts';

declare const wx: any;
declare const uni: any;

const WIDTH = 600;
const HEIGHT = 900;
const WEEKDAYS = ['一', '二', '三', '四', '五', '六', '日'];

function titleFor(range: number): string {
  if (range === 7) return 'DayPanel 周报';
  if (range === 30) return 'DayPanel 月报';
  return `DayPanel · 近 ${range} 天`;
}

export async function shareReviewPoster(data: Insights): Promise<void> {
  const canvasId = 'reviewPosterCanvas';
  const ctx = uni.createCanvasContext(canvasId);
  const rate = Math.round(data.overall.rate * 100);

  ctx.setFillStyle('#f8fafc');
  ctx.fillRect(0, 0, WIDTH, HEIGHT);
  ctx.setFillStyle('#ffffff');
  ctx.fillRect(28, 28, WIDTH - 56, HEIGHT - 56);

  ctx.setFillStyle('#0f172a');
  ctx.setFontSize(40);
  ctx.fillText(titleFor(data.range), 64, 106);
  ctx.setFontSize(22);
  ctx.setFillStyle('#64748b');
  ctx.fillText(`${data.start} → ${data.end}`, 64, 148);

  ctx.setFillStyle('#eff6ff');
  ctx.fillRect(64, 184, WIDTH - 128, 150);
  ctx.setFillStyle('#1d4ed8');
  ctx.setFontSize(28);
  ctx.fillText('整体完成率', 88, 228);
  ctx.setFontSize(64);
  ctx.fillText(`${rate}%`, 88, 300);
  ctx.setFontSize(24);
  ctx.setFillStyle('#64748b');
  ctx.fillText(
    `${data.overall.completed} / ${data.overall.planned} 项达标`,
    280,
    292,
  );
  const delta = Math.round(data.overall.delta * 100);
  ctx.fillText(`较上一周期 ${delta >= 0 ? '+' : ''}${delta}%`, 280, 262);

  ctx.setFillStyle('#0f172a');
  ctx.setFontSize(26);
  ctx.fillText('星期强弱', 64, 394);
  const maxRate = Math.max(0.01, ...data.weekdays.map((day) => day.rate));
  data.weekdays.forEach((day, index) => {
    const x = 64 + index * 72;
    const barHeight = Math.round((day.rate / maxRate) * 90);
    ctx.setFillStyle('#e2e8f0');
    ctx.fillRect(x, 430 + (90 - barHeight), 44, barHeight);
    ctx.setFillStyle('#7c3aed');
    ctx.fillRect(x, 430 + (90 - barHeight), 44, 8);
    ctx.setFillStyle('#64748b');
    ctx.setFontSize(18);
    ctx.fillText(WEEKDAYS[index], x + 10, 550);
    ctx.fillText(`${Math.round(day.rate * 100)}%`, x + 2, 576);
  });

  ctx.setFillStyle('#0f172a');
  ctx.setFontSize(26);
  ctx.fillText('习惯趋势', 64, 630);
  let y = 674;
  for (const habit of data.habits.slice(0, 5)) {
    ctx.setFillStyle('#1e293b');
    ctx.setFontSize(24);
    ctx.fillText(habit.title.slice(0, 18), 64, y);
    ctx.setFillStyle('#1d4ed8');
    ctx.fillText(`${Math.round(habit.rate * 100)}%`, 430, y);
    const trend = Math.round(habit.trend * 100);
    ctx.setFillStyle(trend >= 0 ? '#047857' : '#be123c');
    ctx.fillText(`${trend >= 0 ? '+' : ''}${trend}`, 500, y);
    y += 42;
  }

  ctx.setFillStyle('#94a3b8');
  ctx.setFontSize(20);
  ctx.fillText(
    `手记 ${data.journalNotes} · 卡片 ${data.cards} · 共现 ${data.pairs.length} 组`,
    64,
    HEIGHT - 70,
  );
  ctx.fillText('DayPanel · 真实记录', 64, HEIGHT - 42);

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