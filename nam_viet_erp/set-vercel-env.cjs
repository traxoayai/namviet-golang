const { execSync } = require('child_process');
const fs = require('fs');

const envVars = {
  'VITE_SUPABASE_URL': 'https://iudkexocalqdhxuyjacu.supabase.co',
  'VITE_SUPABASE_ANON_KEY': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1ZGtleG9jYWxxZGh4dXlqYWN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxNDA5NzIsImV4cCI6MjA3NzcxNjk3Mn0.TryofMnEhsBsgiUv29mOtn7yuR55FZCYrM8Xv1wmtQg',
  'VITE_PUBLIC_API_URL': 'https://namviet-erp-backend-1051286041700.asia-southeast1.run.app',
  'VITE_WS_URL': 'wss://namviet-erp-backend-1051286041700.asia-southeast1.run.app',
  'VITE_FIREBASE_API_KEY': 'AIzaSyC9AXdldhOKBjeoWE4B_bZxLqTMDIr3i3w',
  'VITE_FIREBASE_AUTH_DOMAIN': 'nam-viet-erp.firebaseapp.com',
  'VITE_FIREBASE_PROJECT_ID': 'nam-viet-erp',
  'VITE_FIREBASE_STORAGE_BUCKET': 'nam-viet-erp.firebasestorage.app',
  'VITE_FIREBASE_MESSAGING_SENDER_ID': '966570122803',
  'VITE_FIREBASE_APP_ID': '1:966570122803:web:24f3e9c111e81a5e064d46'
};

const environments = ['production', 'preview', 'development'];

for (const [key, value] of Object.entries(envVars)) {
  for (const env of environments) {
    console.log(`Setting ${key} for ${env}...`);
    try {
      // Remove existing first, ignore if not exists
      execSync(`npx vercel env rm ${key} ${env} -y`, { stdio: 'ignore' });
    } catch (e) {}
    
    try {
      // Use cmd /c echo to avoid newline issues, but better to use node's execSync with input
      execSync(`npx vercel env add ${key} ${env}`, { input: value, stdio: ['pipe', 'ignore', 'ignore'] });
      console.log(`Successfully set ${key} for ${env}`);
    } catch (e) {
      console.error(`Failed to set ${key} for ${env}: ${e.message}`);
    }
  }
}
