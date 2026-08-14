import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Lift Log', short_name: 'Lift Log', display: 'standalone',
    start_url: '/', background_color: '#101612', theme_color: '#101612',
    icons: [{ src: '/icon.svg', sizes: 'any', type: 'image/svg+xml' }],
  };
}

