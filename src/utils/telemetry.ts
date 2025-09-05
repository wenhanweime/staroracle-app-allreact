interface TelemetryEvent {
  name: string;
  props?: Record<string, any>;
  ts?: number;
}

let enabled = false;

export const setTelemetryEnabled = (v: boolean) => {
  enabled = v;
};

export const recordEvent = (name: string, props?: Record<string, any>) => {
  if (!enabled) return;
  const evt: TelemetryEvent = { name, props, ts: Date.now() };
  // 轻量实现：先打印，为后续接入埋点服务预留
  console.log('[telemetry]', evt);
};

