import axios from 'axios';
import { supabase } from '../lib/supabaseClient';

const axiosClient = axios.create({
  baseURL: import.meta.env.VITE_PUBLIC_API_URL || 'https://namviet-erp-backend-1051286041700.asia-southeast1.run.app',
  headers: {
    'Content-Type': 'application/json',
  },
});

axiosClient.interceptors.request.use(
  async (config) => {
    // Get the current session from Supabase
    const { data: { session } } = await supabase.auth.getSession();
    
    if (session?.access_token) {
      config.headers['Authorization'] = `Bearer ${session.access_token}`;
    }
    
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

axiosClient.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    // Handle global errors here
    if (error.response?.status === 401) {
      // Token might be expired or invalid
      console.error('Unauthorized request', error);
      // Optional: Handle auto-logout or token refresh here
    }
    return Promise.reject(error);
  }
);

export default axiosClient;
