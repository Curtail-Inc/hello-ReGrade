import {AbsoluteFill, Series} from 'remotion';
import {Episode} from './schema';
import {Beat} from './Beat';
export const Video: React.FC<Episode> = ({beats}) => (
  <AbsoluteFill>
    <Series>
      {beats.map((b) => (
        <Series.Sequence key={b.id} durationInFrames={Math.max(1, b.durationFrames)}>
          <Beat clip={b.clip} />
        </Series.Sequence>
      ))}
    </Series>
  </AbsoluteFill>
);
