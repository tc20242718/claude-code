---
name: remotion
description: Use when the user wants to create programmatic videos, animated demos, motion graphics, or data-driven video content using Remotion (React-based video framework).
---

# Remotion Video Creation Skill

## What is Remotion

Remotion lets you create videos using React components. Every frame is a React render. You write components, Remotion renders them to MP4.

## Project Setup

```bash
npm create video@latest
cd my-video
npm install
npm start  # Opens preview at localhost:3000
```

## Core Concepts

### Composition
Defines a video clip: dimensions, duration, fps.

```tsx
// src/Root.tsx
import {Composition} from 'remotion';
import {MyVideo} from './MyVideo';

export const RemotionRoot = () => (
  <Composition
    id="MyVideo"
    component={MyVideo}
    durationInFrames={150}  // 5 seconds at 30fps
    fps={30}
    width={1920}
    height={1080}
  />
);
```

### useCurrentFrame + interpolate
Drive animations from the current frame number.

```tsx
import {useCurrentFrame, interpolate} from 'remotion';

export const MyVideo = () => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [0, 30], [0, 1]);
  const x = interpolate(frame, [0, 60], [-500, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  return <div style={{opacity, transform: `translateX(${x}px)`}}>Hello</div>;
};
```

### spring
Physics-based animation (natural, bouncy motion).

```tsx
import {spring, useCurrentFrame, useVideoConfig} from 'remotion';

const {fps} = useVideoConfig();
const scale = spring({frame, fps, from: 0, to: 1});
```

## Common Video Types

### Product Demo / Walkthrough
- Use `<Sequence>` to time sections
- Animate screenshots with `interpolate`
- Add text callouts with spring animations

### Data Visualization
- Animate chart bars/lines with `interpolate`
- Drive number counters: `Math.round(interpolate(frame, [0, 60], [0, targetValue]))`

### Slide Deck Video
- Each slide is a `<Sequence>` with entry/exit animations
- Text animates word-by-word using `<TransitionSeries>`

## Rendering

```bash
# Render to MP4
npx remotion render src/index.ts MyVideo out/video.mp4

# With custom props
npx remotion render src/index.ts MyVideo out/video.mp4 --props='{"title":"My Title"}'

# Render a still (single frame)
npx remotion still src/index.ts MyVideo --frame=30 out/thumbnail.png
```

## Workflow

When asked to create a video:
1. Clarify: duration, dimensions, style, content/data
2. Generate `Root.tsx` with the composition definition
3. Generate the main component with frame-driven animations
4. Provide the render command
5. List any additional npm packages needed
