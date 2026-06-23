import { useState, useCallback } from 'react';
import { supabase } from '@/shared/lib/supabaseClient';

interface Message {
  role: 'user' | 'assistant';
  content: string;
}

export function useAiChatSSE() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const sendMessage = useCallback(async (text: string) => {
    if (!text.trim()) return;

    // Add user message immediately
    const userMessage: Message = { role: 'user', content: text };
    setMessages(prev => [...prev, userMessage]);
    
    // Placeholder for assistant message, which will stream
    const assistantMessage: Message = { role: 'assistant', content: '' };
    setMessages(prev => [...prev, assistantMessage]);
    
    setIsLoading(true);
    setError(null);

    try {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;

      if (!token) {
        throw new Error("Vui lòng đăng nhập để sử dụng AI Chat");
      }

      const apiUrl = import.meta.env.VITE_PUBLIC_API_URL || 'https://namviet-erp-backend-1051286041700.asia-southeast1.run.app';
      
      const response = await fetch(`${apiUrl}/api/v1/ai/chat`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ message: text })
      });

      if (!response.ok) {
        throw new Error('Lỗi kết nối đến máy chủ AI');
      }

      if (!response.body) {
        throw new Error('Response body is null');
      }

      // Read the stream using TextDecoder (SSE handling)
      const reader = response.body.getReader();
      const decoder = new TextDecoder('utf-8');
      let done = false;

      while (!done) {
        const { value, done: readerDone } = await reader.read();
        done = readerDone;
        if (value) {
          const chunk = decoder.decode(value, { stream: true });
          
          // Server-Sent Events are typically formatted as "data: {content}\n\n"
          // Mảnh chunk có thể chứa nhiều event, ta cần tách chúng ra
          const lines = chunk.split('\n');
          for (const line of lines) {
            if (line.startsWith('data: ')) {
              const dataStr = line.replace('data: ', '').trim();
              if (dataStr === '[DONE]') {
                done = true;
                break;
              }
              try {
                // Giả định backend trả về JSON format {"content": "..."}
                const parsed = JSON.parse(dataStr);
                const content = parsed.content || parsed.text || dataStr;
                
                // Update the last message (the assistant's) with the new chunk
                setMessages(prev => {
                  const newMessages = [...prev];
                  const lastIndex = newMessages.length - 1;
                  newMessages[lastIndex] = {
                    ...newMessages[lastIndex],
                    content: newMessages[lastIndex].content + content
                  };
                  return newMessages;
                });
              } catch (e) {
                // Nếu không phải JSON, cộng chuỗi trực tiếp
                setMessages(prev => {
                  const newMessages = [...prev];
                  const lastIndex = newMessages.length - 1;
                  newMessages[lastIndex] = {
                    ...newMessages[lastIndex],
                    content: newMessages[lastIndex].content + dataStr
                  };
                  return newMessages;
                });
              }
            }
          }
        }
      }
    } catch (err: any) {
      setError(err.message || "Đã có lỗi xảy ra");
    } finally {
      setIsLoading(false);
    }
  }, []);

  return {
    messages,
    sendMessage,
    isLoading,
    error
  };
}
