-- Migration: 20260624000001_add_medical_dict_tables.sql

CREATE TABLE IF NOT EXISTS public.medical_diseases (
    id bigserial PRIMARY KEY,
    dic10_code varchar(20) UNIQUE NOT NULL,
    name varchar(255) NOT NULL,
    symptoms jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.medical_prescription_templates (
    id bigserial PRIMARY KEY,
    disease_id bigint NOT NULL REFERENCES public.medical_diseases(id) ON DELETE CASCADE,
    min_age_months int NOT NULL DEFAULT 0,
    max_age_months int NOT NULL DEFAULT 1200, -- 100 years
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.medical_prescription_template_items (
    id bigserial PRIMARY KEY,
    template_id bigint NOT NULL REFERENCES public.medical_prescription_templates(id) ON DELETE CASCADE,
    product_id bigint NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity int NOT NULL DEFAULT 1,
    dosage varchar(255),
    instructions text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.medical_vaccine_protocols (
    id bigserial PRIMARY KEY,
    protocol_name varchar(255) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.medical_vaccine_doses (
    id bigserial PRIMARY KEY,
    protocol_id bigint NOT NULL REFERENCES public.medical_vaccine_protocols(id) ON DELETE CASCADE,
    dose_number int NOT NULL,
    min_days_from_previous int NOT NULL DEFAULT 0,
    max_days_from_previous int,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_medical_diseases_dic10 ON public.medical_diseases(dic10_code);
CREATE INDEX IF NOT EXISTS idx_medical_pres_templates_disease ON public.medical_prescription_templates(disease_id);
CREATE INDEX IF NOT EXISTS idx_medical_pres_items_template ON public.medical_prescription_template_items(template_id);
CREATE INDEX IF NOT EXISTS idx_medical_vaccine_doses_protocol ON public.medical_vaccine_doses(protocol_id);
