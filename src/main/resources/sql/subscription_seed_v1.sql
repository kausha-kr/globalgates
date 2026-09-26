-- =============================================================
-- subscription_seed_v1.sql
-- GlobalGates 더미 구독/결제/뱃지 시드 (member_post_v2.sql 위에서 동작)
--
--   분포 (총 15건 구독, ~67건 결제이력)
--     - EXPERT 5명   : 월간 active, 갱신 다회 (모두 completed)
--     - PRO_PLUS 5명 : 월간 3 + 연간 2
--                       └ gaeun.moon 은 가상계좌 입금대기 (pending) 1건
--     - PRO 5명      : 월간 3 + 연간 1 + expired 1
--                       └ hyunwoo.bae 는 해지신청(quartz=false), 만료일까지 active
--     - FREE 5명     : 구독 없음
--                       └ yerin.shin/taewoo.kwon/seonho.baek 의 role 을
--                         expert → business 로 강등하여 코드 일관성 복구
--
--   결제 상태는 코드 흐름상 실제 발생 가능한 것만 사용:
--     - completed : 정상 결제 (대부분)
--     - pending   : 가상계좌 첫결제 입금대기 (입금 후 webhook 으로 completed 전환)
--   ※ failed / cancelled 는 코드에 발생 경로가 없어 의도적으로 만들지 않음.
--     갱신 실패는 결제 row 를 만들지 않고 즉시 expireSubscription() 처리됨.
--
-- 실행
--   1. (한 번만)         psql -U globalgates -d globalgates -f member_post_v2.sql
--   2. (몇 번이든 OK)    psql -U globalgates -d globalgates -f subscription_seed_v1.sql
--
-- 회원 SQL 재실행 시
--   tbl_subscription / tbl_payment_subscribe / tbl_badge 의 FK 가 회원을
--   잡고 있으면 회원 SQL 의 DELETE 가 실패합니다. 회원을 다시 시드하려면
--   먼저 이 파일의 [0] CLEANUP 섹션만 실행해서 FK 를 비워두세요.
--
-- 멱등성: 매번 깨끗하게 리셋 (DELETE → INSERT)
-- 시간 기준: 2026-05-20 (모든 active 구독의 expires_at 은 +2주 이상 미래)
-- 더미 마커: billing_key='DUMMY_BK_*', receipt_id='DUMMY_RCPT_*'
-- =============================================================

BEGIN;

-- =============================================================
-- [0] CLEANUP — @globalgates.test 회원에 매달린 구독·결제·뱃지 제거
-- =============================================================
DELETE FROM tbl_payment_subscribe
WHERE member_id IN (
    SELECT id FROM tbl_member WHERE member_email LIKE '%@globalgates.test'
);

DELETE FROM tbl_badge
WHERE member_id IN (
    SELECT id FROM tbl_member WHERE member_email LIKE '%@globalgates.test'
);

DELETE FROM tbl_subscription
WHERE member_id IN (
    SELECT id FROM tbl_member WHERE member_email LIKE '%@globalgates.test'
);

-- =============================================================
-- [1] role 일관성 복구
--     코드 흐름상 member_role='expert' 는 EXPERT 구독자에게만 부여됨
--     (SubscriptionService.java:165). 구독을 부여하지 않을 expert 후보
--     3명은 role 을 business 로 되돌려 모순 상태를 제거.
-- =============================================================
UPDATE tbl_member
SET member_role = 'business'::member_role,
    updated_datetime = now()
WHERE member_email IN (
    'yerin.shin@globalgates.test',
    'taewoo.kwon@globalgates.test',
    'seonho.baek@globalgates.test'
);

-- =============================================================
-- [2] 구독 (tbl_subscription)
--     자연키: member_email — id 하드코딩 없음
-- =============================================================

-- ---------- EXPERT 5명 (월간 80,000) ----------
-- seungwoo.han : 2025-09-15 가입, 8회 갱신, 다음 갱신일 2026-06-15
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'expert'::subscription_tier, 'monthly', 'active'::subscription_status,
       '2025-09-15 10:12:00'::timestamp, '2026-06-15 10:12:00'::timestamp,
       true, 'DUMMY_BK_seungwoo_han_001', 80000,
       '2025-09-15 10:12:00'::timestamp, '2026-05-15 10:12:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'seungwoo.han@globalgates.test';

-- dohyun.lim : 2025-10-05 가입, 다음 갱신일 2026-06-05
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'expert'::subscription_tier, 'monthly', 'active'::subscription_status,
       '2025-10-05 14:33:00'::timestamp, '2026-06-05 14:33:00'::timestamp,
       true, 'DUMMY_BK_dohyun_lim_001', 80000,
       '2025-10-05 14:33:00'::timestamp, '2026-05-05 14:33:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'dohyun.lim@globalgates.test';

-- chaerin.yoon : 2025-11-10 가입, 다음 갱신일 2026-06-10
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'expert'::subscription_tier, 'monthly', 'active'::subscription_status,
       '2025-11-10 09:05:00'::timestamp, '2026-06-10 09:05:00'::timestamp,
       true, 'DUMMY_BK_chaerin_yoon_001', 80000,
       '2025-11-10 09:05:00'::timestamp, '2026-05-10 09:05:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'chaerin.yoon@globalgates.test';

-- jaemin.oh : 2025-12-05 가입, 다음 갱신일 2026-06-05
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'expert'::subscription_tier, 'monthly', 'active'::subscription_status,
       '2025-12-05 16:48:00'::timestamp, '2026-06-05 16:48:00'::timestamp,
       true, 'DUMMY_BK_jaemin_oh_001', 80000,
       '2025-12-05 16:48:00'::timestamp, '2026-05-05 16:48:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'jaemin.oh@globalgates.test';

-- jian.song : 2026-03-12 가입(최근 가입한 expert), 다음 갱신일 2026-06-12
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'expert'::subscription_tier, 'monthly', 'active'::subscription_status,
       '2026-03-12 11:20:00'::timestamp, '2026-06-12 11:20:00'::timestamp,
       true, 'DUMMY_BK_jian_song_001', 80000,
       '2026-03-12 11:20:00'::timestamp, '2026-05-12 11:20:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'jian.song@globalgates.test';

-- ---------- PRO_PLUS 5명 (월간 50,000 / 연간 480,000) ----------
-- jaeho.kim : 연간 480,000, 2025-12-01
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'pro_plus'::subscription_tier, 'annual', 'active'::subscription_status,
       '2025-12-01 13:15:00'::timestamp, '2026-12-01 13:15:00'::timestamp,
       false, NULL, 480000,
       '2025-12-01 13:15:00'::timestamp, '2025-12-01 13:15:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'jaeho.kim@globalgates.test';

-- sumin.lee : 월간 50,000, 2025-11-08 가입, 다음 갱신일 2026-06-08
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'pro_plus'::subscription_tier, 'monthly', 'active'::subscription_status,
       '2025-11-08 19:40:00'::timestamp, '2026-06-08 19:40:00'::timestamp,
       true, 'DUMMY_BK_sumin_lee_001', 50000,
       '2025-11-08 19:40:00'::timestamp, '2026-05-08 19:40:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'sumin.lee@globalgates.test';

-- nayoung.kang : 월간 50,000, 2026-01-10 가입, 다음 갱신일 2026-06-10
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'pro_plus'::subscription_tier, 'monthly', 'active'::subscription_status,
       '2026-01-10 08:22:00'::timestamp, '2026-06-10 08:22:00'::timestamp,
       true, 'DUMMY_BK_nayoung_kang_001', 50000,
       '2026-01-10 08:22:00'::timestamp, '2026-05-10 08:22:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'nayoung.kang@globalgates.test';

-- haneul.cho : 연간 480,000, 2025-09-01 (가장 오래된 유저)
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'pro_plus'::subscription_tier, 'annual', 'active'::subscription_status,
       '2025-09-01 11:00:00'::timestamp, '2026-09-01 11:00:00'::timestamp,
       false, NULL, 480000,
       '2025-09-01 11:00:00'::timestamp, '2025-09-01 11:00:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'haneul.cho@globalgates.test';

-- gaeun.moon : ⭐ 가상계좌 입금대기 케이스
--   PRO+ 월간 신청, 가상계좌 발급받았으나 아직 미입금. 구독은 active 로 잡혀있고
--   결제 row 는 pending 상태. 입금 webhook 도착 시 completed 로 전환되는 게 정상 흐름.
--   가상계좌이므로 billing_key 없음 / quartz=false (자동갱신 불가).
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'pro_plus'::subscription_tier, 'monthly', 'active'::subscription_status,
       '2026-05-18 15:10:00'::timestamp, '2026-06-18 15:10:00'::timestamp,
       false, NULL, 50000,
       '2026-05-18 15:10:00'::timestamp, '2026-05-18 15:10:00'::timestamp
FROM tbl_member m WHERE m.member_email = 'gaeun.moon@globalgates.test';

-- ---------- PRO 5명 (월간 30,000 / 연간 300,000) ----------
-- jiwon.park : 월간 30,000, 2025-12-05 가입, 다음 갱신일 2026-06-05
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'pro'::subscription_tier, 'monthly', 'active'::subscription_status,
       '2025-12-05 17:30:00'::timestamp, '2026-06-05 17:30:00'::timestamp,
       true, 'DUMMY_BK_jiwon_park_001', 30000,
       '2025-12-05 17:30:00'::timestamp, '2026-05-05 17:30:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'jiwon.park@globalgates.test';

-- taeyoung.jung : 연간 300,000, 2026-02-10
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'pro'::subscription_tier, 'annual', 'active'::subscription_status,
       '2026-02-10 10:08:00'::timestamp, '2027-02-10 10:08:00'::timestamp,
       false, NULL, 300000,
       '2026-02-10 10:08:00'::timestamp, '2026-02-10 10:08:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'taeyoung.jung@globalgates.test';

-- yena.choi : 월간 30,000, 2025-12-18 가입, 다음 갱신일 2026-06-18
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'pro'::subscription_tier, 'monthly', 'active'::subscription_status,
       '2025-12-18 12:55:00'::timestamp, '2026-06-18 12:55:00'::timestamp,
       true, 'DUMMY_BK_yena_choi_001', 30000,
       '2025-12-18 12:55:00'::timestamp, '2026-05-18 12:55:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'yena.choi@globalgates.test';

-- minho.hwang : 월간 30,000, 2025-10-10 가입 → 2026-01-10 EXPIRED
--   2025-12-10 결제 후 다음 갱신(2026-01-10)에 실패 → expireSubscription() 호출됨.
--   갱신 실패는 payment row 를 남기지 않으므로 결제이력 3건만 남고 status=expired.
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'pro'::subscription_tier, 'monthly', 'expired'::subscription_status,
       '2025-10-10 09:15:00'::timestamp, '2026-01-10 09:15:00'::timestamp,
       false, NULL, 30000,
       '2025-10-10 09:15:00'::timestamp, '2026-01-10 09:16:00'::timestamp
FROM tbl_member m WHERE m.member_email = 'minho.hwang@globalgates.test';

-- hyunwoo.bae : 월간 30,000, 2026-03-15 가입, 해지신청(quartz=false) — 만료까지는 active
INSERT INTO tbl_subscription
    (member_id, tier, billing_cycle, status, started_at, expires_at, quartz, billing_key, amount,
     created_datetime, updated_datetime)
SELECT m.id, 'pro'::subscription_tier, 'monthly', 'active'::subscription_status,
       '2026-03-15 18:00:00'::timestamp, '2026-06-15 18:00:00'::timestamp,
       false, 'DUMMY_BK_hyunwoo_bae_001', 30000,
       '2026-03-15 18:00:00'::timestamp, '2026-05-15 18:00:30'::timestamp
FROM tbl_member m WHERE m.member_email = 'hyunwoo.bae@globalgates.test';

-- =============================================================
-- [3] 뱃지 (tbl_badge)
--     SubscriptionService:170~180 — FREE 가 아닌 구독자에게 뱃지 부여.
--     expireSubscription() 호출 시 deleteByMemberId → expired 회원은 뱃지 없음.
--     hyunwoo.bae 는 status='active' 이므로 뱃지 유지 (해지신청 뿐 아직 만료 아님).
--     gaeun.moon 도 status='active' 이므로 뱃지 부여 (입금 대기지만 구독 자체는 활성).
-- =============================================================
INSERT INTO tbl_badge (member_id, badge_type, created_datetime, updated_datetime)
SELECT s.member_id, s.tier::text::badge_type, s.started_at, s.updated_datetime
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
WHERE m.member_email LIKE '%@globalgates.test'
  AND s.status = 'active'
  AND s.tier != 'free'::subscription_tier;

-- =============================================================
-- [4] 결제이력 (tbl_payment_subscribe) — 모두 completed (gaeun.moon 의 1건만 pending)
-- =============================================================

-- ===== EXPERT 5명 =====

-- seungwoo.han : 9건 (2025-09-15 ~ 2026-05-15)
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 80000, 'completed'::payment_status, 'billing', v.receipt, v.paid_at::timestamp, v.paid_at::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
JOIN (VALUES
    ('DUMMY_RCPT_seungwoo_han_0001', '2025-09-15 10:12:30'),
    ('DUMMY_RCPT_seungwoo_han_0002', '2025-10-15 10:12:30'),
    ('DUMMY_RCPT_seungwoo_han_0003', '2025-11-15 10:12:30'),
    ('DUMMY_RCPT_seungwoo_han_0004', '2025-12-15 10:12:30'),
    ('DUMMY_RCPT_seungwoo_han_0005', '2026-01-15 10:12:30'),
    ('DUMMY_RCPT_seungwoo_han_0006', '2026-02-15 10:12:30'),
    ('DUMMY_RCPT_seungwoo_han_0007', '2026-03-15 10:12:30'),
    ('DUMMY_RCPT_seungwoo_han_0008', '2026-04-15 10:12:30'),
    ('DUMMY_RCPT_seungwoo_han_0009', '2026-05-15 10:12:30')
) AS v(receipt, paid_at) ON true
WHERE m.member_email = 'seungwoo.han@globalgates.test' AND s.billing_key = 'DUMMY_BK_seungwoo_han_001';

-- dohyun.lim : 8건 (2025-10-05 ~ 2026-05-05)
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 80000, 'completed'::payment_status, 'billing', v.receipt, v.paid_at::timestamp, v.paid_at::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
JOIN (VALUES
    ('DUMMY_RCPT_dohyun_lim_0001', '2025-10-05 14:33:30'),
    ('DUMMY_RCPT_dohyun_lim_0002', '2025-11-05 14:33:30'),
    ('DUMMY_RCPT_dohyun_lim_0003', '2025-12-05 14:33:30'),
    ('DUMMY_RCPT_dohyun_lim_0004', '2026-01-05 14:33:30'),
    ('DUMMY_RCPT_dohyun_lim_0005', '2026-02-05 14:33:30'),
    ('DUMMY_RCPT_dohyun_lim_0006', '2026-03-05 14:33:30'),
    ('DUMMY_RCPT_dohyun_lim_0007', '2026-04-05 14:33:30'),
    ('DUMMY_RCPT_dohyun_lim_0008', '2026-05-05 14:33:30')
) AS v(receipt, paid_at) ON true
WHERE m.member_email = 'dohyun.lim@globalgates.test' AND s.billing_key = 'DUMMY_BK_dohyun_lim_001';

-- chaerin.yoon : 7건 (2025-11-10 ~ 2026-05-10)
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 80000, 'completed'::payment_status, 'billing', v.receipt, v.paid_at::timestamp, v.paid_at::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
JOIN (VALUES
    ('DUMMY_RCPT_chaerin_yoon_0001', '2025-11-10 09:05:30'),
    ('DUMMY_RCPT_chaerin_yoon_0002', '2025-12-10 09:05:30'),
    ('DUMMY_RCPT_chaerin_yoon_0003', '2026-01-10 09:05:30'),
    ('DUMMY_RCPT_chaerin_yoon_0004', '2026-02-10 09:05:30'),
    ('DUMMY_RCPT_chaerin_yoon_0005', '2026-03-10 09:05:30'),
    ('DUMMY_RCPT_chaerin_yoon_0006', '2026-04-10 09:05:30'),
    ('DUMMY_RCPT_chaerin_yoon_0007', '2026-05-10 09:05:30')
) AS v(receipt, paid_at) ON true
WHERE m.member_email = 'chaerin.yoon@globalgates.test' AND s.billing_key = 'DUMMY_BK_chaerin_yoon_001';

-- jaemin.oh : 6건 (2025-12-05 ~ 2026-05-05)
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 80000, 'completed'::payment_status, 'billing', v.receipt, v.paid_at::timestamp, v.paid_at::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
JOIN (VALUES
    ('DUMMY_RCPT_jaemin_oh_0001', '2025-12-05 16:48:30'),
    ('DUMMY_RCPT_jaemin_oh_0002', '2026-01-05 16:48:30'),
    ('DUMMY_RCPT_jaemin_oh_0003', '2026-02-05 16:48:30'),
    ('DUMMY_RCPT_jaemin_oh_0004', '2026-03-05 16:48:30'),
    ('DUMMY_RCPT_jaemin_oh_0005', '2026-04-05 16:48:30'),
    ('DUMMY_RCPT_jaemin_oh_0006', '2026-05-05 16:48:30')
) AS v(receipt, paid_at) ON true
WHERE m.member_email = 'jaemin.oh@globalgates.test' AND s.billing_key = 'DUMMY_BK_jaemin_oh_001';

-- jian.song : 3건 (2026-03-12 ~ 2026-05-12), 최근 가입한 expert
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 80000, 'completed'::payment_status, 'billing', v.receipt, v.paid_at::timestamp, v.paid_at::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
JOIN (VALUES
    ('DUMMY_RCPT_jian_song_0001', '2026-03-12 11:20:30'),
    ('DUMMY_RCPT_jian_song_0002', '2026-04-12 11:20:30'),
    ('DUMMY_RCPT_jian_song_0003', '2026-05-12 11:20:30')
) AS v(receipt, paid_at) ON true
WHERE m.member_email = 'jian.song@globalgates.test' AND s.billing_key = 'DUMMY_BK_jian_song_001';

-- ===== PRO_PLUS 5명 =====

-- jaeho.kim : 연간 1건
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 480000, 'completed'::payment_status, 'card',
       'DUMMY_RCPT_jaeho_kim_0001', '2025-12-01 13:15:30'::timestamp, '2025-12-01 13:15:30'::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
WHERE m.member_email = 'jaeho.kim@globalgates.test' AND s.billing_cycle = 'annual' AND s.tier = 'pro_plus'::subscription_tier;

-- sumin.lee : 7건 (2025-11-08 ~ 2026-05-08)
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 50000, 'completed'::payment_status, 'billing', v.receipt, v.paid_at::timestamp, v.paid_at::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
JOIN (VALUES
    ('DUMMY_RCPT_sumin_lee_0001', '2025-11-08 19:40:30'),
    ('DUMMY_RCPT_sumin_lee_0002', '2025-12-08 19:40:30'),
    ('DUMMY_RCPT_sumin_lee_0003', '2026-01-08 19:40:30'),
    ('DUMMY_RCPT_sumin_lee_0004', '2026-02-08 19:40:30'),
    ('DUMMY_RCPT_sumin_lee_0005', '2026-03-08 19:40:30'),
    ('DUMMY_RCPT_sumin_lee_0006', '2026-04-08 19:40:30'),
    ('DUMMY_RCPT_sumin_lee_0007', '2026-05-08 19:40:30')
) AS v(receipt, paid_at) ON true
WHERE m.member_email = 'sumin.lee@globalgates.test' AND s.billing_key = 'DUMMY_BK_sumin_lee_001';

-- nayoung.kang : 5건 (2026-01-10 ~ 2026-05-10)
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 50000, 'completed'::payment_status, 'billing', v.receipt, v.paid_at::timestamp, v.paid_at::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
JOIN (VALUES
    ('DUMMY_RCPT_nayoung_kang_0001', '2026-01-10 08:22:30'),
    ('DUMMY_RCPT_nayoung_kang_0002', '2026-02-10 08:22:30'),
    ('DUMMY_RCPT_nayoung_kang_0003', '2026-03-10 08:22:30'),
    ('DUMMY_RCPT_nayoung_kang_0004', '2026-04-10 08:22:30'),
    ('DUMMY_RCPT_nayoung_kang_0005', '2026-05-10 08:22:30')
) AS v(receipt, paid_at) ON true
WHERE m.member_email = 'nayoung.kang@globalgates.test' AND s.billing_key = 'DUMMY_BK_nayoung_kang_001';

-- haneul.cho : 연간 1건
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 480000, 'completed'::payment_status, 'card',
       'DUMMY_RCPT_haneul_cho_0001', '2025-09-01 11:00:30'::timestamp, '2025-09-01 11:00:30'::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
WHERE m.member_email = 'haneul.cho@globalgates.test' AND s.billing_cycle = 'annual' AND s.tier = 'pro_plus'::subscription_tier;

-- gaeun.moon : ⭐ 가상계좌 입금대기 1건 (paid_at = NULL, payment_method='vbank')
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 50000, 'pending'::payment_status, 'vbank',
       'DUMMY_RCPT_gaeun_moon_0001', NULL, '2026-05-18 15:10:30'::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
WHERE m.member_email = 'gaeun.moon@globalgates.test' AND s.tier = 'pro_plus'::subscription_tier;

-- ===== PRO 5명 =====

-- jiwon.park : 6건 (2025-12-05 ~ 2026-05-05)
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 30000, 'completed'::payment_status, 'billing', v.receipt, v.paid_at::timestamp, v.paid_at::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
JOIN (VALUES
    ('DUMMY_RCPT_jiwon_park_0001', '2025-12-05 17:30:30'),
    ('DUMMY_RCPT_jiwon_park_0002', '2026-01-05 17:30:30'),
    ('DUMMY_RCPT_jiwon_park_0003', '2026-02-05 17:30:30'),
    ('DUMMY_RCPT_jiwon_park_0004', '2026-03-05 17:30:30'),
    ('DUMMY_RCPT_jiwon_park_0005', '2026-04-05 17:30:30'),
    ('DUMMY_RCPT_jiwon_park_0006', '2026-05-05 17:30:30')
) AS v(receipt, paid_at) ON true
WHERE m.member_email = 'jiwon.park@globalgates.test' AND s.billing_key = 'DUMMY_BK_jiwon_park_001';

-- taeyoung.jung : 연간 1건
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 300000, 'completed'::payment_status, 'card',
       'DUMMY_RCPT_taeyoung_jung_0001', '2026-02-10 10:08:30'::timestamp, '2026-02-10 10:08:30'::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
WHERE m.member_email = 'taeyoung.jung@globalgates.test' AND s.billing_cycle = 'annual' AND s.tier = 'pro'::subscription_tier;

-- yena.choi : 6건 (2025-12-18 ~ 2026-05-18)
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 30000, 'completed'::payment_status, 'billing', v.receipt, v.paid_at::timestamp, v.paid_at::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
JOIN (VALUES
    ('DUMMY_RCPT_yena_choi_0001', '2025-12-18 12:55:30'),
    ('DUMMY_RCPT_yena_choi_0002', '2026-01-18 12:55:30'),
    ('DUMMY_RCPT_yena_choi_0003', '2026-02-18 12:55:30'),
    ('DUMMY_RCPT_yena_choi_0004', '2026-03-18 12:55:30'),
    ('DUMMY_RCPT_yena_choi_0005', '2026-04-18 12:55:30'),
    ('DUMMY_RCPT_yena_choi_0006', '2026-05-18 12:55:30')
) AS v(receipt, paid_at) ON true
WHERE m.member_email = 'yena.choi@globalgates.test' AND s.billing_key = 'DUMMY_BK_yena_choi_001';

-- minho.hwang : 3건 completed (2025-10-10 ~ 2025-12-10). 이후 갱신실패 → expired
--   갱신 실패 시 코드(SubscriptionService:74)는 payment row 를 만들지 않고
--   바로 expireSubscription() 을 호출하므로 failed row 는 남지 않음.
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 30000, 'completed'::payment_status, 'billing', v.receipt, v.paid_at::timestamp, v.paid_at::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
JOIN (VALUES
    ('DUMMY_RCPT_minho_hwang_0001', '2025-10-10 09:15:30'),
    ('DUMMY_RCPT_minho_hwang_0002', '2025-11-10 09:15:30'),
    ('DUMMY_RCPT_minho_hwang_0003', '2025-12-10 09:15:30')
) AS v(receipt, paid_at) ON true
WHERE m.member_email = 'minho.hwang@globalgates.test'
  AND s.tier = 'pro'::subscription_tier AND s.status = 'expired'::subscription_status;

-- hyunwoo.bae : 3건 (2026-03-15 ~ 2026-05-15). 해지신청 했지만 만료일까지 정상 결제됨.
INSERT INTO tbl_payment_subscribe
    (subscription_id, member_id, amount, payment_status, payment_method, receipt_id, paid_at, created_datetime)
SELECT s.id, s.member_id, 30000, 'completed'::payment_status, 'billing', v.receipt, v.paid_at::timestamp, v.paid_at::timestamp
FROM tbl_subscription s
JOIN tbl_member m ON m.id = s.member_id
JOIN (VALUES
    ('DUMMY_RCPT_hyunwoo_bae_0001', '2026-03-15 18:00:30'),
    ('DUMMY_RCPT_hyunwoo_bae_0002', '2026-04-15 18:00:30'),
    ('DUMMY_RCPT_hyunwoo_bae_0003', '2026-05-15 18:00:30')
) AS v(receipt, paid_at) ON true
WHERE m.member_email = 'hyunwoo.bae@globalgates.test' AND s.billing_key = 'DUMMY_BK_hyunwoo_bae_001';

COMMIT;

-- =============================================================
-- 검증 — 분포가 예상대로인지 확인
-- =============================================================
SELECT 'subscriptions' AS what, COUNT(*) AS cnt
FROM tbl_subscription s JOIN tbl_member m ON m.id = s.member_id
WHERE m.member_email LIKE '%@globalgates.test'
UNION ALL SELECT 'payments', COUNT(*)
FROM tbl_payment_subscribe ps JOIN tbl_member m ON m.id = ps.member_id
WHERE m.member_email LIKE '%@globalgates.test'
UNION ALL SELECT 'badges', COUNT(*)
FROM tbl_badge b JOIN tbl_member m ON m.id = b.member_id
WHERE m.member_email LIKE '%@globalgates.test';

-- tier 분포 (admin 화면과 동일한 로직)
SELECT
  CASE
    WHEN m.member_role = 'expert' THEN 'expert'
    ELSE COALESCE(s.tier::text, 'free')
  END AS effective_tier,
  COUNT(*) AS cnt
FROM tbl_member m
LEFT JOIN LATERAL (
    SELECT tier FROM tbl_subscription
    WHERE member_id = m.id AND status = 'active'
    ORDER BY id DESC LIMIT 1
) s ON true
WHERE m.member_email LIKE '%@globalgates.test'
GROUP BY 1
ORDER BY 1;

-- 결제 상태 분포
SELECT payment_status::text AS status, COUNT(*) AS cnt
FROM tbl_payment_subscribe ps JOIN tbl_member m ON m.id = ps.member_id
WHERE m.member_email LIKE '%@globalgates.test'
GROUP BY 1 ORDER BY 1;
