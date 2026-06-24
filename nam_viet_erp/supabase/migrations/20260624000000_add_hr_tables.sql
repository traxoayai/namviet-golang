-- Migration: 20260624000000_add_hr_tables.sql

CREATE TABLE IF NOT EXISTS public.hr_contracts (
    id bigserial PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    contract_type varchar(255) NOT NULL,
    base_salary numeric NOT NULL DEFAULT 0,
    start_date date NOT NULL,
    end_date date,
    kpi_target text,
    status varchar(50) NOT NULL DEFAULT 'active',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.hr_work_shifts (
    id bigserial PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    shift_name varchar(100) NOT NULL,
    date date NOT NULL,
    start_time time NOT NULL,
    end_time time NOT NULL,
    status varchar(50) NOT NULL DEFAULT 'pending',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.hr_attendances (
    id bigserial PRIMARY KEY,
    shift_id bigint NOT NULL REFERENCES public.hr_work_shifts(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    check_in_time timestamptz,
    check_in_ip varchar(45),
    check_in_lat numeric,
    check_in_lng numeric,
    distance_from_branch numeric,
    is_valid_location boolean,
    check_out_time timestamptz,
    check_out_ip varchar(45),
    check_out_lat numeric,
    check_out_lng numeric,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.hr_payrolls (
    id bigserial PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    month int NOT NULL,
    year int NOT NULL,
    base_salary numeric NOT NULL DEFAULT 0,
    kpi_bonus numeric NOT NULL DEFAULT 0,
    commission numeric NOT NULL DEFAULT 0,
    total_salary numeric NOT NULL DEFAULT 0,
    status varchar(50) NOT NULL DEFAULT 'draft',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_hr_contracts_user_id ON public.hr_contracts(user_id);
CREATE INDEX IF NOT EXISTS idx_hr_work_shifts_user_id_date ON public.hr_work_shifts(user_id, date);
CREATE INDEX IF NOT EXISTS idx_hr_attendances_shift_id ON public.hr_attendances(shift_id);
CREATE INDEX IF NOT EXISTS idx_hr_payrolls_user_id_month_year ON public.hr_payrolls(user_id, month, year);
