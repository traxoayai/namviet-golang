export interface Campaign {
  id?: number;
  name: string;
  budget: number;
  flow_config: string;
  status?: string;
  created_at?: string;
}

export interface CampaignMetrics {
  sent_count: number;
  open_count: number;
  clicked_count: number;
  redeemed_count: number;
}

export interface Survey {
  id?: number;
  title: string;
  description: string;
  questions: any; // JSONB
  created_at?: string;
}
