export const UNIFORM_DEG_PER_MS = 0.0005; // 360deg / (0.0005 deg/ms) = 720000 ms = 720 s = 12 min

export const fullRotationSeconds = () => Math.max(1, Math.round((360 / UNIFORM_DEG_PER_MS) / 1000));
