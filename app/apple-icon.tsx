import { ImageResponse } from 'next/og';

export const size = { width: 180, height: 180 };
export const contentType = 'image/png';

export default function AppleIcon() {
  return new ImageResponse(
    <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#b7f34a', color: '#101612', borderRadius: 38, fontSize: 76, fontWeight: 800, fontFamily: 'Arial' }}>
      LL
    </div>,
    { ...size },
  );
}
