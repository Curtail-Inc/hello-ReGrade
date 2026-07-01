import {expect, test} from 'vitest';
import {bundle} from '@remotion/bundler';
import {renderStill, selectComposition} from '@remotion/renderer';
import path from 'path';

test('Video composition renders a still without throwing', async () => {
  // publicDir must be set at bundle time, not renderStill time (remotion 4.0.230
  // renderStill() has no publicDir option); clips live in ../../capture at build time.
  const serveUrl = await bundle({
    entryPoint: path.join(__dirname, '../src/index.ts'),
    publicDir: path.join(__dirname, '../../capture'),
  });
  const props = {fps: 24, width: 1920, height: 1080,
    beats: [{id: 'a', clip: '01-cold-open.mp4', durationFrames: 48}], captions: []};
  const composition = await selectComposition({serveUrl, id: 'Video', inputProps: props});
  const out = path.join(__dirname, 'still.png');
  await renderStill({composition, serveUrl, output: out, inputProps: props, frame: 0});
  expect(out).toBeTruthy();
}, 120000);
