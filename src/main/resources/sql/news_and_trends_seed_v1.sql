-- ============================================================================
-- globalgates seed: 일반 뉴스(20건) + 탐색하기 실시간 검색어(14키워드, 40+row)
--   - news_type = 'general' 만 (속보 emergency 제외)
--   - tbl_search_history: search_count 합산이 ranking 기준 (SearchHistoryMapper.xml)
--   - 모두 idempotent: marker 기반 cleanup → 재삽입
--
-- author : claude (admin_id = pigchan0202@gmail.com, member id 동적 조회)
-- date   : 2026-05-20
-- target : ubuntu@43.201.228.177  globalgates / globalgates
-- ============================================================================

BEGIN;

-- ============================================================================
-- 0. CLEANUP (idempotent re-run)
-- ============================================================================
-- 뉴스: news_source_url 의 ?seed=GG2026Q2 마커로 식별
--       cascade FK (tbl_news_like / tbl_news_bookmark / tbl_news_reply) 모두 ON DELETE CASCADE → 안전
DELETE FROM tbl_news WHERE news_source_url LIKE '%?seed=GG2026Q2%';

-- 검색 히스토리: seed 키워드 14종 정확히 매칭하여 삭제
DELETE FROM tbl_search_history
WHERE search_keyword IN (
    'CBAM 규제',
    '반도체 수출규제',
    'K-뷰티 수출',
    '베트남 진출',
    'HS코드 조회',
    '인코텀즈 2020',
    '환율 헤지',
    'FTA 원산지증명서',
    '동남아 시장',
    '통관 컨설팅',
    '신용장 발행',
    '무역금융',
    'K-SURE 수출보험',
    '콜드체인 항공직송'
);

-- ============================================================================
-- 1. 일반 뉴스 20건 (news_type='general')
--    카테고리 분포: trade 6 / market 5 / policy 5 / technology 3 / etc 1
--    published_at  : 최근 2~3주, 자연스러운 시간 분산
--    source_url    : 실재하는 무역·통상 도메인 + ?seed=GG2026Q2 마커
-- ============================================================================

-- admin_id 는 시드 작성자(=프로젝트 오너) pigchan0202@gmail.com 으로 고정
DO $news_seed$
DECLARE
    v_admin_id BIGINT;
BEGIN
    SELECT id INTO v_admin_id
    FROM tbl_member
    WHERE member_email = 'pigchan0202@gmail.com';

    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'admin member (pigchan0202@gmail.com) not found';
    END IF;

    -- (1) trade
    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '2026년 1분기 對美 수출 8.5% 증가… 반도체·전기차가 견인',
            '산업통상자원부에 따르면 2026년 1분기 對미국 수출액이 전년 동기 대비 8.5% 증가한 374억 달러로 집계됐다. 메모리 반도체 단가 회복과 현지 생산 전기차 부품 수요 확대가 주된 동인으로 분석된다. 무역업계는 IRA 핵심광물 요건 단계적 강화에도 불구하고 2분기 성장세가 이어질 것으로 전망했다.',
            'https://www.kita.net/research/totalTradeStat?seed=GG2026Q2',
            'trade'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '2 days' - (random() * INTERVAL '3 hours'));

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            'K-뷰티 동남아 6대 시장 진출 가속… 베트남·태국 매출 두 자릿수 성장',
            '대한화장품협회 집계 기준 1분기 對동남아 화장품 수출이 전년 동기 대비 23.4% 증가한 4억8천만 달러를 기록했다. 베트남·태국·인도네시아 3개국이 전체 성장세의 71%를 차지했으며, 더모코스메틱·선케어 카테고리가 매출 견인 라인업으로 부상했다.',
            'https://www.kotra.or.kr/bigdata/visualization?seed=GG2026Q2',
            'trade'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '4 days');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '對베트남 무역수지 흑자 245억 달러 돌파… 6년 연속 최대 흑자국',
            '한국무역협회 통계에 따르면 對베트남 무역수지가 245.7억 달러 흑자를 기록하며 6년 연속 단일 국가 기준 최대 흑자를 유지했다. 반도체·디스플레이 중간재 수출이 전체 수출의 38%를 차지했고, 한-베 산업협력 펀드 출범으로 중장기 협력 기반이 강화됐다는 평가다.',
            'https://stat.kita.net/stat/cstat/peri/CountryImpExpList.screen?seed=GG2026Q2',
            'trade'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '5 days' - INTERVAL '6 hours');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '한-EU FTA 발효 14년차… 對EU 누적 수출 5,300억 달러 돌파',
            '한국과 EU 간 자유무역협정(FTA) 발효 14년차 누적 수출액이 5,302억 달러를 돌파했다. 자동차·자동차부품·기계류·전기차 배터리가 누적 수출의 절반 이상을 차지했고, 친환경·디지털 통상 챕터 신설 협상이 하반기 본격화될 전망이다.',
            'https://www.fta.go.kr/eu/main/?seed=GG2026Q2',
            'trade'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '7 days');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '中 광군제 K-푸드 매출 전년比 38% 급증… 라면·김·치즈 ‘빅3’ 견조',
            '11월 광군제 기간 중국 주요 이커머스 플랫폼에서 K-푸드 거래액이 전년 동기 대비 38.2% 증가한 4.1억 위안으로 집계됐다. 라면·조미김·치즈 3개 품목군이 전체 매출의 64%를 점유했고, 라이브커머스 활용 브랜드 매출이 비활용 대비 평균 2.7배 높았다.',
            'https://www.kotra.or.kr/cn/news?seed=GG2026Q2',
            'trade'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '8 days');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '對호주 친환경 자동차 수출 전년比 47% 증가… 광물협력 시너지',
            '한-호주 핵심광물 협력 협정 체결 1년차에 對호주 친환경차 수출이 전년 동기 대비 47.1% 증가한 12.4억 달러를 기록했다. 리튬·니켈 등 배터리 핵심광물 수입 비중이 31%로 상승하며, 양국 간 ‘광물-완성차’ 순환 공급망이 본격 가동되고 있다.',
            'https://www.motie.go.kr/kor/policy/trade?seed=GG2026Q2',
            'trade'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '10 days');

    -- (2) market
    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '美 연준 0.25%p 금리 인하… 원달러 환율 1,310원대 진입',
            '미 연방준비제도가 5월 FOMC에서 기준금리를 0.25%p 인하하며 원달러 환율이 1,313원까지 하락했다. 무역업계는 수입원가 부담 완화를 환영하는 한편, 1,300원선 안착 여부에 따라 2분기 수출 단가 협상 전략을 재검토하고 있다.',
            'https://www.bok.or.kr/portal/main/contents.do?seed=GG2026Q2',
            'market'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '1 day' - INTERVAL '2 hours');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '컨테이너 운임 SCFI 1,420포인트… 5주 연속 하락세',
            '상하이컨테이너운임지수(SCFI)가 1,420포인트로 5주 연속 하락하며 1분기 고점 대비 28% 하락했다. 미주 서안·유럽 노선 슬랏 공급 확대가 주된 요인으로, 화주들은 하반기 장기계약(SC) 단가 재협상 기회로 활용하는 분위기다.',
            'https://newsroom.globalgates.io/shipping/scfi?seed=GG2026Q2',
            'market'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '3 days');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '호치민-부산 항공운임 kg당 4.8달러 안정세… 콜드체인 수요 견조',
            '호치민-부산 항공화물 운임이 kg당 4.8달러 박스권에서 안정세를 보이고 있다. K-식품·화장품 콜드체인 수요가 견조한 가운데, 항공사 신규 화물기 투입으로 슬랏 공급도 동반 확대되며 운임 변동성이 1분기 대비 절반 수준으로 축소됐다.',
            'https://newsroom.globalgates.io/logistics/air-cargo?seed=GG2026Q2',
            'market'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '6 days' - INTERVAL '8 hours');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '두바이유 78달러 박스권… 무역업계 비용 예측 가능성 확대',
            'OPEC+ 감산 연장 합의와 동시에 미국 셰일오일 생산 회복이 맞물리며 두바이유가 배럴당 76~80달러 박스권을 형성했다. 변동성 축소로 무역기업의 분기별 물류·생산 원가 시뮬레이션 정확도가 개선됐다는 평가다.',
            'https://www.opec.org/opec_web/en/data?seed=GG2026Q2',
            'market'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '9 days');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '위안화 약세 지속… 對中 수출기업 환차손 관리 비상',
            '위안화/달러 환율이 7.31위안까지 약세를 보이며 對중국 수출기업의 환차손 관리 수요가 급증했다. K-SURE 환변동보험 가입 건수가 전월 대비 41% 증가했고, 무역금융 상담 창구에는 선물환·옵션 헤지 문의가 평소 대비 2배 이상 유입되고 있다.',
            'https://www.ksure.or.kr/news/?seed=GG2026Q2',
            'market'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '11 days');

    -- (3) policy
    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '관세청, AEO 인증기업 신속통관 우대 확대 시행',
            '관세청은 6월 1일부로 AEO(수출입안전관리 우수기업) 인증기업에 대한 신속통관 우대 범위를 확대한다고 발표했다. 무작위 검사 면제율을 기존 70%에서 85%로 상향하고, 통관심사 시간을 평균 2.4시간에서 1.1시간으로 단축할 계획이다.',
            'https://www.customs.go.kr/kcs/cm/cntnts/cntntsView.do?seed=GG2026Q2',
            'policy'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '1 day' - INTERVAL '14 hours');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '산업부, ‘2026 K-소부장 글로벌화’ 1조 2천억 예산 편성',
            '산업통상자원부가 ‘2026 K-소부장 글로벌화 전략’ 일환으로 1조 2천억 원 규모 예산안을 확정했다. 반도체·이차전지·바이오 3대 분야 중소·중견기업의 해외 진출 R&D, 인증, 마케팅을 전 주기 지원한다.',
            'https://www.motie.go.kr/kor/article/policyContents?seed=GG2026Q2',
            'policy'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '4 days' - INTERVAL '5 hours');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            'EU CBAM 2단계 보고서 제출 마감 임박… 철강업계 점검 분주',
            'EU 탄소국경조정제도(CBAM) 2단계 분기 보고서 제출 마감이 7월 31일로 다가오면서 철강·알루미늄 업계가 배출량 산정 시스템 재점검에 분주하다. 실측 데이터 기반 보고가 본격화되는 만큼 공급망 협력사 단위까지 일관된 배출계수 관리가 핵심 과제로 떠올랐다.',
            'https://taxation-customs.ec.europa.eu/cbam?seed=GG2026Q2',
            'policy'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '6 days');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '식약처, 화장품 GMP 동남아 5개국 상호인정 추진',
            '식품의약품안전처가 베트남·태국·인도네시아·말레이시아·필리핀 5개국과 화장품 GMP(우수제조기준) 상호인정 협상을 본격화한다. 협정 체결 시 K-뷰티 수출기업은 현지 등록 절차가 평균 6개월에서 1.5개월로 단축될 것으로 예상된다.',
            'https://www.mfds.go.kr/brd/m_99/list.do?seed=GG2026Q2',
            'policy'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '8 days' - INTERVAL '10 hours');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '美 IRA 핵심광물 요건 강화… 배터리 수출기업 공급망 재편 가속',
            '미국 IRA(인플레이션감축법) 시행세칙 개정으로 배터리 핵심광물의 ‘우려국가 외 조달’ 요건이 2027년 80%로 상향된다. 국내 배터리 셀·소재 기업은 호주·캐나다·인도네시아 광산 지분투자와 정제·전구체 단계 내재화를 동시에 진행하며 공급망 재편에 속도를 내고 있다.',
            'https://home.treasury.gov/policy-issues/inflation-reduction-act?seed=GG2026Q2',
            'policy'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '12 days');

    -- (4) technology
    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            'HS코드 자동분류 AI ‘관세Bot’ 정확도 96% 달성',
            '관세청·국립관세무역연구원이 공동 개발한 HS코드 자동분류 AI ‘관세Bot’이 검증 데이터셋 기준 96.3% 분류 정확도를 달성했다. 통관단가 협상·FTA 원산지 판정에 직접 활용 가능한 수준으로, 7월 중 무료 공개 API 형태로 중소 무역기업에 개방될 예정이다.',
            'https://unipass.customs.go.kr/clip/index.do?seed=GG2026Q2',
            'technology'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '2 days' - INTERVAL '11 hours');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '무역서류 OCR 인식률 99.2%… 신용장 처리시간 70% 단축',
            '국책 핀테크 사업 ‘디지털 무역서류 인식기’가 인보이스·B/L·신용장 등 12종 무역서류에서 평균 OCR 인식률 99.2%를 기록했다. 은행 신용장 검토·심사 자동화에 적용 시 처리시간이 평균 4.8일에서 1.4일로 단축될 것으로 분석된다.',
            'https://newsroom.globalgates.io/fintech/ocr?seed=GG2026Q2',
            'technology'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '5 days');

    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '블록체인 원산지증명 파일럿, 한-아세안 5개국 확대',
            '한국 관세청 주도 블록체인 기반 원산지증명서(C/O) 파일럿이 한-아세안 5개국(베트남·태국·말레이시아·인도네시아·필리핀)으로 확대된다. 변조 위험 0%·검증시간 평균 38초로 기존 종이 C/O 대비 처리 효율이 95% 개선되는 것으로 측정됐다.',
            'https://asean.org/our-communities/economic-community?seed=GG2026Q2',
            'technology'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '13 days');

    -- (5) etc
    INSERT INTO tbl_news (admin_id, news_title, news_content, news_source_url, news_category, news_type, published_at)
    VALUES (v_admin_id,
            '코트라, ‘2026 글로벌 진출전략 컨퍼런스’ 6월 코엑스 개최',
            '대한무역투자진흥공사(KOTRA)가 6월 24~25일 서울 코엑스에서 ‘2026 글로벌 진출전략 컨퍼런스’를 개최한다. 22개국 무역관장·해외 바이어 380여명이 참여하며, K-소부장·K-푸드·K-뷰티 3개 트랙 1:1 상담회와 진출 전략 세미나가 동시 운영된다.',
            'https://www.kotra.or.kr/conference/2026?seed=GG2026Q2',
            'etc'::news_category_type, 'general'::news_type,
            NOW() - INTERVAL '15 days');

    RAISE NOTICE 'tbl_news: 20 general news rows inserted (admin_id=%)', v_admin_id;
END $news_seed$;

-- ============================================================================
-- 2. 탐색하기 실시간 검색어 (search_count 합산 ranking)
--    무역 전문 키워드 14종을 다양한 member_id 에 분산하여 자연스러운 분포 시뮬레이션
--
--    예상 TOP 10:
--       1) CBAM 규제             15
--       2) 반도체 수출규제       14
--       3) K-뷰티 수출           13
--       4) 베트남 진출           12
--       5) HS코드 조회           11
--       6) 인코텀즈 2020         10
--       7) 환율 헤지              9
--       8) FTA 원산지증명서       8
--       8) 동남아 시장            8   (동률)
--      10) 통관 컨설팅            7
--
--    11~14위는 화면 미노출 (top 10 limit) - 분포의 자연스러움을 위해 함께 시드
-- ============================================================================

DO $trends_seed$
DECLARE
    v_ids BIGINT[];
    v_n   INT;
BEGIN
    -- 멤버 id 풀: 가입 순서 기준 정렬, 동적으로 22명 모두 활용
    SELECT array_agg(id ORDER BY id) INTO v_ids FROM tbl_member;
    v_n := array_length(v_ids, 1);

    IF v_n IS NULL OR v_n < 5 THEN
        RAISE EXCEPTION 'tbl_member 가 너무 적습니다 (n=%) — 시드 불가', v_n;
    END IF;

    -- 헬퍼: 1-based index 가 풀 크기를 초과하면 mod 로 wrap
    -- (idx 가 22보다 큰 케이스는 거의 없지만 안전장치)

    -- 키워드별 (member_offset, count) 분포 삽입
    INSERT INTO tbl_search_history (member_id, search_keyword, search_count, created_datetime)
    SELECT v_ids[((m - 1) % v_n) + 1],
           kw,
           cnt,
           NOW() - (random() * INTERVAL '5 days') - (random() * INTERVAL '12 hours')
    FROM (VALUES
        -- 1위 (총 15): CBAM 규제
        (1,  'CBAM 규제', 5),
        (2,  'CBAM 규제', 4),
        (3,  'CBAM 규제', 3),
        (4,  'CBAM 규제', 3),
        -- 2위 (총 14): 반도체 수출규제
        (5,  '반도체 수출규제', 4),
        (6,  '반도체 수출규제', 4),
        (7,  '반도체 수출규제', 3),
        (8,  '반도체 수출규제', 3),
        -- 3위 (총 13): K-뷰티 수출
        (9,  'K-뷰티 수출', 5),
        (10, 'K-뷰티 수출', 4),
        (11, 'K-뷰티 수출', 4),
        -- 4위 (총 12): 베트남 진출
        (12, '베트남 진출', 5),
        (13, '베트남 진출', 4),
        (14, '베트남 진출', 3),
        -- 5위 (총 11): HS코드 조회
        (15, 'HS코드 조회', 4),
        (16, 'HS코드 조회', 3),
        (17, 'HS코드 조회', 2),
        (18, 'HS코드 조회', 2),
        -- 6위 (총 10): 인코텀즈 2020
        (19, '인코텀즈 2020', 4),
        (20, '인코텀즈 2020', 3),
        (21, '인코텀즈 2020', 3),
        -- 7위 (총 9): 환율 헤지
        (22, '환율 헤지', 3),
        (1,  '환율 헤지', 3),
        (2,  '환율 헤지', 3),
        -- 8위 동률 (총 8): FTA 원산지증명서
        (3,  'FTA 원산지증명서', 3),
        (4,  'FTA 원산지증명서', 3),
        (5,  'FTA 원산지증명서', 2),
        -- 8위 동률 (총 8): 동남아 시장
        (6,  '동남아 시장', 3),
        (7,  '동남아 시장', 3),
        (8,  '동남아 시장', 2),
        -- 10위 (총 7): 통관 컨설팅
        (9,  '통관 컨설팅', 3),
        (10, '통관 컨설팅', 2),
        (11, '통관 컨설팅', 2),
        -- 11위 이하 (참고로 함께 시드)
        (12, '신용장 발행', 2),
        (13, '신용장 발행', 2),
        (14, '신용장 발행', 2),
        (15, '무역금융', 2),
        (16, '무역금융', 2),
        (17, '무역금융', 1),
        (18, 'K-SURE 수출보험', 2),
        (19, 'K-SURE 수출보험', 1),
        (20, 'K-SURE 수출보험', 1),
        (21, '콜드체인 항공직송', 1),
        (22, '콜드체인 항공직송', 1),
        (1,  '콜드체인 항공직송', 1)
    ) AS t(m, kw, cnt);

    RAISE NOTICE 'tbl_search_history: 43 rows / 14 keywords inserted (member pool size=%)', v_n;
END $trends_seed$;

COMMIT;

-- ============================================================================
-- 3. 검증 (회복 후 결과 확인용 — 주석 처리)
-- ============================================================================
-- SELECT id, news_type, news_category, LEFT(news_title, 40) AS title, published_at
--   FROM tbl_news ORDER BY published_at DESC;
-- SELECT rank() over (order by sum(search_count) desc) AS ranking,
--        search_keyword, sum(search_count) AS total_count
--   FROM tbl_search_history GROUP BY search_keyword ORDER BY ranking LIMIT 10;
