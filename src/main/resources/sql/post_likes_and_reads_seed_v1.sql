-- ============================================================================
-- globalgates seed: 모든 게시글의 좋아요 + 조회수 임의 분포 (인기순/최신순 검증용)
--   - tbl_post_like        : root 게시글(reply_post_id IS NULL) 355건에 분포 삽입
--                            + 댓글(reply) 일부에도 분포 삽입 → 댓글 좋아요 자연스러움
--   - tbl_post.post_read_count : active 게시글 전체 4712건에 임의 분포 UPDATE
--
--   분포 전략 (id 기반 결정적 패턴 + random 노이즈)
--     id % 17 == 0  → 슈퍼 인기 (좋아요 18~22 / 조회수 3,000~9,000)
--     id %  7 == 0  → 인기      (좋아요 12~18 / 조회수 1,200~4,000)
--     id %  3 == 0  → 보통      (좋아요  5~12 / 조회수   400~1,500)
--     else          → 평범      (좋아요  0~ 6 / 조회수    20~  500)
--
-- author : claude
-- date   : 2026-05-20
-- ============================================================================

BEGIN;

-- ============================================================================
-- 0. CLEANUP
-- ============================================================================
-- 기존 좋아요 5건뿐 (검증 결과) — 인기순 테스트 일관성을 위해 전부 비우고 새로 시드
TRUNCATE TABLE tbl_post_like RESTART IDENTITY CASCADE;

-- ============================================================================
-- 1. 좋아요 분포 — root 게시글
-- ============================================================================
--   각 게시글마다 멤버 22명 중 N명이 좋아요 한 것으로 시뮬레이션
--   N : 위 분포 표 기준, 멤버 풀에서 OFFSET 무작위 추출
-- ============================================================================
DO $likes_seed$
DECLARE
    v_ids   BIGINT[];
    v_n     INT;
    p       RECORD;
    target  INT;
    i       INT;
    chosen  BIGINT;
BEGIN
    SELECT array_agg(id ORDER BY id) INTO v_ids FROM tbl_member;
    v_n := array_length(v_ids, 1);

    IF v_n IS NULL OR v_n < 5 THEN
        RAISE EXCEPTION 'tbl_member too small (n=%)', v_n;
    END IF;

    -- root 게시글 + 댓글 모두 좋아요 분포 적용
    FOR p IN
        SELECT id FROM tbl_post WHERE post_status = 'active' ORDER BY id
    LOOP
        target := CASE
            WHEN p.id % 17 = 0 THEN 18 + (random() * 4)::int   -- 18~22
            WHEN p.id %  7 = 0 THEN 12 + (random() * 6)::int   -- 12~18
            WHEN p.id %  3 = 0 THEN  5 + (random() * 7)::int   --  5~12
            ELSE                       (random() * 6)::int     --  0~ 6
        END;
        target := LEAST(target, v_n);   -- 멤버 수 캡

        -- 무작위 멤버 N명을 (id 기반 시드 + 랜덤) 추출, 중복 없이
        IF target > 0 THEN
            INSERT INTO tbl_post_like (member_id, post_id, created_datetime)
            SELECT m_id,
                   p.id,
                   NOW() - (random() * INTERVAL '21 days')
            FROM (
                SELECT v_ids[gs] AS m_id
                FROM generate_series(1, v_n) gs
                ORDER BY md5((p.id::text || ':' || gs::text))  -- post id 별 결정적 셔플
                LIMIT target
            ) picks;
        END IF;
    END LOOP;

    RAISE NOTICE 'tbl_post_like seed done';
END $likes_seed$;

-- ============================================================================
-- 2. 조회수 (post_read_count) — active 게시글 전체
-- ============================================================================
UPDATE tbl_post
   SET post_read_count = CASE
        WHEN id % 17 = 0 THEN 3000 + (random() * 6000)::int   --  3,000 ~ 9,000
        WHEN id %  7 = 0 THEN 1200 + (random() * 2800)::int   --  1,200 ~ 4,000
        WHEN id %  3 = 0 THEN  400 + (random() * 1100)::int   --    400 ~ 1,500
        ELSE                    20 + (random() *  480)::int   --     20 ~   500
   END
 WHERE post_status = 'active';

COMMIT;

-- ============================================================================
-- 3. 검증 쿼리 (참고용 — 주석 처리)
-- ============================================================================
-- SELECT v.id, LEFT(v.post_title, 30) AS title, v.like_count, v.post_read_count
--   FROM view_post_feed v
--  ORDER BY v.like_count DESC LIMIT 10;
--
-- SELECT v.id, LEFT(v.post_title, 30) AS title, v.like_count, v.post_read_count, v.created_datetime
--   FROM view_post_feed v
--  ORDER BY v.created_datetime DESC LIMIT 10;
