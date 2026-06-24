-- Migration: 20260625000000_add_marketing_tables.sql

CREATE TABLE IF NOT EXISTS public.jobs (
    id bigserial PRIMARY KEY,
    job_type varchar(255) NOT NULL,
    payload jsonb NOT NULL,
    status varchar(50) NOT NULL DEFAULT 'pending', -- pending, processing, completed, failed
    run_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.marketing_campaigns (
    id bigserial PRIMARY KEY,
    name varchar(255) NOT NULL,
    budget numeric NOT NULL DEFAULT 0,
    spent numeric NOT NULL DEFAULT 0,
    flow_config jsonb,
    status varchar(50) NOT NULL DEFAULT 'draft', -- draft, running, paused, completed
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.marketing_campaign_metrics (
    id bigserial PRIMARY KEY,
    campaign_id bigint NOT NULL REFERENCES public.marketing_campaigns(id) ON DELETE CASCADE,
    sent_count int NOT NULL DEFAULT 0,
    open_count int NOT NULL DEFAULT 0,
    clicked_count int NOT NULL DEFAULT 0,
    redeemed_count int NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.marketing_surveys (
    id bigserial PRIMARY KEY,
    name varchar(255) NOT NULL,
    form_config jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_jobs_status_run_at ON public.jobs(status, run_at);
CREATE INDEX IF NOT EXISTS idx_marketing_metrics_campaign ON public.marketing_campaign_metrics(campaign_id);
