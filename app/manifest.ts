import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    id: '/', name: 'Lift Log', short_name: 'Lift Log', display: 'standalone',
    start_url: '/', scope: '/', orientation: 'portrait-primary',
    background_color: '#101612', theme_color: '#101612',
    categories: ['health', 'fitness', 'lifestyle'],
    icons: [
      { src: '/icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any' },
      { src: '/icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'maskable' },
    ],
  };
}
