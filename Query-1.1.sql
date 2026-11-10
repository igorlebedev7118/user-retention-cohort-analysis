WITH users_clean AS (
  SELECT
    u.user_id,
    u.promo_signup_flag,
    u.signup_datetime,

    to_date(
      (
        CASE
          WHEN length(
            split_part(
              regexp_replace(split_part(trim(u.signup_datetime), ' ', 1), '[./]', '-', 'g'),
              '-', 3
            )
          ) = 2
            THEN '20' || split_part(
              regexp_replace(split_part(trim(u.signup_datetime), ' ', 1), '[./]', '-', 'g'),
              '-', 3
            )
          ELSE split_part(
            regexp_replace(split_part(trim(u.signup_datetime), ' ', 1), '[./]', '-', 'g'),
            '-', 3
          )
        END
      )
      || '-' ||
      lpad(split_part(regexp_replace(split_part(trim(u.signup_datetime), ' ', 1), '[./]', '-', 'g'), '-', 2), 2, '0')
      || '-' ||
      lpad(split_part(regexp_replace(split_part(trim(u.signup_datetime), ' ', 1), '[./]', '-', 'g'), '-', 1), 2, '0')
    , 'YYYY-MM-DD')::timestamp AS signup_ts
  FROM public.cohort_users_raw u
),

events_clean AS (
  SELECT
    e.event_id,
    e.user_id,
    e.event_type,
    e.revenue,
    e.event_datetime,

    to_date(
      (
        CASE
          WHEN length(
            split_part(
              regexp_replace(split_part(trim(e.event_datetime), ' ', 1), '[./]', '-', 'g'),
              '-', 3
            )
          ) = 2
            THEN '20' || split_part(
              regexp_replace(split_part(trim(e.event_datetime), ' ', 1), '[./]', '-', 'g'),
              '-', 3
            )
          ELSE split_part(
            regexp_replace(split_part(trim(e.event_datetime), ' ', 1), '[./]', '-', 'g'),
            '-', 3
          )
        END
      )
      || '-' ||
      lpad(split_part(regexp_replace(split_part(trim(e.event_datetime), ' ', 1), '[./]', '-', 'g'), '-', 2), 2, '0')
      || '-' ||
      lpad(split_part(regexp_replace(split_part(trim(e.event_datetime), ' ', 1), '[./]', '-', 'g'), '-', 1), 2, '0')
    , 'YYYY-MM-DD')::timestamp AS event_ts
  FROM public.cohort_events_raw e
),

joined AS (
  SELECT
    u.user_id,
    u.promo_signup_flag,
    u.signup_ts,
    e.event_id,
    e.event_type,
    e.revenue,
    e.event_ts,

    date_trunc('month', u.signup_ts)::date AS cohort_month,
    date_trunc('month', e.event_ts)::date AS activity_month,

    
    EXTRACT(
      MONTH FROM age(
        date_trunc('month', e.event_ts),
        date_trunc('month', u.signup_ts)
      )
    )::int AS month_offset

  FROM users_clean u
  JOIN events_clean e
    ON e.user_id = u.user_id
  WHERE
    u.signup_ts IS NOT NULL
    AND e.event_ts IS NOT NULL
    AND e.event_type IS NOT NULL
    AND e.event_type <> 'test_event'
)

SELECT
  promo_signup_flag,
  cohort_month,
  month_offset,
  COUNT(DISTINCT user_id) AS users_total
FROM joined
WHERE activity_month BETWEEN DATE '2025-01-01' AND DATE '2025-06-01'
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;
