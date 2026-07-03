import {useCurrentFrame, useVideoConfig, interpolate, spring} from 'remotion';
import {RED} from './theme';

// Timed highlight boxes over the terminal line being narrated.
// Coords are in the 1920x1080 frame; from/to are fractions of the beat's duration.
// `emphatic` marks the payoff climax — bigger entrance overshoot, a breathing pulse, and a stronger glow.
type HL = {x: number; y: number; w: number; h: number; from: number; to: number; emphatic?: boolean};
const CONFIG: Record<string, HL[]> = {
  replay: [{x: 92, y: 252, w: 580, h: 52, from: 0.52, to: 1.0}], // Total deltas: 22
  noise: [
    {x: 96, y: 471, w: 1080, h: 52, from: 0.28, to: 0.46}, // status_code 200→401 Unauthorized
    {x: 96, y: 560, w: 920, h: 52, from: 0.46, to: 0.64}, // $.token changed
  ],
  rereplay: [{x: 92, y: 207, w: 610, h: 52, from: 0.42, to: 1.0}], // Total deltas: 3
  payoff: [{x: 82, y: 463, w: 782, h: 66, from: 0.30, to: 0.92, emphatic: true}], // $.total 46.20 → 42.00
};

export const Highlights: React.FC<{beatId: string; durationInFrames: number}> = ({beatId, durationInFrames}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const hls = CONFIG[beatId];
  if (!hls) return null;
  return (
    <>
      {hls.map((h, i) => {
        const start = h.from * durationInFrames;
        const end = h.to * durationInFrames;
        if (frame < start || frame > end) return null;
        const fade = 7;
        const opacity = interpolate(frame, [start, start + fade, end - fade, end], [0, 1, 1, 0],
          {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
        // Entrance: a spring settle that slightly overshoots 1 — the box "draws on" instead of hard-popping.
        const appear = spring({frame: frame - start, fps, config: {damping: h.emphatic ? 9 : 13, mass: 0.6}});
        const base = interpolate(appear, [0, 1], [h.emphatic ? 0.86 : 0.95, 1]);
        const breathe = h.emphatic ? 1 + 0.02 * Math.sin((frame - start) / 7) : 1;
        const glow = h.emphatic
          ? `0 0 44px ${RED}99, 0 0 14px ${RED}, inset 0 0 0 9999px ${RED}22`
          : `0 0 24px ${RED}66, inset 0 0 0 9999px ${RED}14`;
        return (
          <div key={i} style={{
            position: 'absolute', left: h.x, top: h.y, width: h.w, height: h.h,
            border: `${h.emphatic ? 4 : 3}px solid ${RED}`, borderRadius: 10, opacity,
            transform: `scale(${base * breathe})`, transformOrigin: 'center',
            boxShadow: glow,
          }} />
        );
      })}
    </>
  );
};
