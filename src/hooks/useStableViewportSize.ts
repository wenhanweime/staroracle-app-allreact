import { useEffect, useRef, useState } from 'react';

const KEYBOARD_HEIGHT_DROP = 160;
const ORIENTATION_WIDTH_DELTA = 120;

interface StableViewportSize {
  width: number;
  height: number;
  baseWidth: number;
  baseHeight: number;
}

export function useStableViewportSize(): StableViewportSize {
  const initialWidth = typeof window !== 'undefined' ? window.innerWidth : 0;
  const initialHeight = typeof window !== 'undefined' ? window.innerHeight : 0;
  const baseWidthRef = useRef(initialWidth);
  const baseHeightRef = useRef(initialHeight);
  const [size, setSize] = useState<{ width: number; height: number }>({
    width: initialWidth,
    height: initialHeight,
  });

  useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }

    const update = () => {
      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;
      const widthDelta = Math.abs(viewportWidth - baseWidthRef.current);

      if (widthDelta > ORIENTATION_WIDTH_DELTA) {
        baseWidthRef.current = viewportWidth;
        baseHeightRef.current = viewportHeight;
      } else if (viewportHeight > baseHeightRef.current) {
        baseHeightRef.current = viewportHeight;
      }

      const targetHeightBase = baseHeightRef.current || viewportHeight;
      const heightDrop = targetHeightBase - viewportHeight;
      const effectiveHeight =
        heightDrop > KEYBOARD_HEIGHT_DROP ? targetHeightBase : viewportHeight;

      setSize({
        width: viewportWidth,
        height: effectiveHeight,
      });
    };

    update();
    window.addEventListener('resize', update);

    const visualViewport = window.visualViewport;
    visualViewport?.addEventListener('resize', update);

    return () => {
      window.removeEventListener('resize', update);
      visualViewport?.removeEventListener('resize', update);
    };
  }, []);

  return {
    width: size.width,
    height: size.height,
    baseWidth: baseWidthRef.current,
    baseHeight: baseHeightRef.current,
  };
}

