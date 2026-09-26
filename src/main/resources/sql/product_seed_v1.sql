-- =============================================================
-- product_seed_v1.sql
-- GlobalGates 더미 상품 시드 (상품 + 카테고리 + 이미지 + 해시태그)
-- (member_post_v2.sql 위에서 동작 — 자연키 lookup 패턴)
--
-- 분포 (총 25개 상품)
--   - EXPERT 5명     : 각 1개 자문 서비스 (5건)
--   - PRO_PLUS 5명   : 자문 1 + 화장품 2 + 반도체 2 + 의료 1 (7건)
--   - PRO 5명        : 식품 2 + 자동차 1 + 의류 1 + 기계 1 + 전자 1 (6건)
--   - FREE 5명       : 화학 2 + 농산물 2 + 자문 3 (7건)
--
-- 실행 순서
--   1. (한 번만) member_post_v2.sql
--   2. (한 번만 또는 갱신 시) subscription_seed_v1.sql
--   3. (몇 번이든 OK) product_seed_v1.sql   ← 이 파일
--
-- S3 사전 업로드 (총 14장 — 일부 상품은 이미지 없음, fallback 로고 표시)
--   2026/05/20/product/product_06.jpg, 08, 09, 12, 13, 14, 15, 16, 17, 19, 21, 22, 23, 25
--   이미지 없는 상품: 01,02,03,04,05,07,10,11,18,20,24
--
-- 더미 마커
--   카테고리, 해시태그는 운영 데이터 가능성이 있어 보존 (NOT EXISTS)
--   상품·이미지는 @globalgates.test 회원 기준으로 식별·삭제
-- =============================================================

BEGIN;

-- =============================================================
-- [0] CLEANUP — @globalgates.test 회원의 상품·이미지 제거
--     일반 게시글(회원 SQL이 만든 25개)은 건드리지 않음
-- =============================================================

-- 내가 만든 상품 post id 모으기
CREATE TEMP TABLE _gg_product_posts(post_id BIGINT PRIMARY KEY) ON COMMIT DROP;
INSERT INTO _gg_product_posts (post_id)
SELECT pp.id FROM tbl_post_product pp
JOIN tbl_post p ON p.id = pp.id
WHERE p.member_id IN (SELECT id FROM tbl_member WHERE member_email LIKE '%@globalgates.test');

-- 상품 이미지 file id 모으기 (tbl_file row 삭제용)
CREATE TEMP TABLE _gg_product_files(file_id BIGINT PRIMARY KEY) ON COMMIT DROP;
INSERT INTO _gg_product_files (file_id)
SELECT DISTINCT pf.file_id
FROM tbl_post_file pf
WHERE pf.post_id IN (SELECT post_id FROM _gg_product_posts);

-- FK 순서대로 삭제
DELETE FROM tbl_post_product_rel
WHERE post_id           IN (SELECT post_id FROM _gg_product_posts)
   OR product_post_id   IN (SELECT post_id FROM _gg_product_posts);
DELETE FROM tbl_post_hashtag_rel
WHERE post_id IN (SELECT post_id FROM _gg_product_posts);
DELETE FROM tbl_post_file
WHERE post_id IN (SELECT post_id FROM _gg_product_posts);
DELETE FROM tbl_file
WHERE id IN (SELECT file_id FROM _gg_product_files);
DELETE FROM tbl_post_product
WHERE id IN (SELECT post_id FROM _gg_product_posts);
DELETE FROM tbl_post
WHERE id IN (SELECT post_id FROM _gg_product_posts);

-- =============================================================
-- [1] 카테고리 — 운영 DB에 이미 있으면 보존
-- =============================================================
INSERT INTO tbl_category (category_name)
SELECT v.name FROM (VALUES
    ('반도체'),
    ('화장품'),
    ('식품'),
    ('자동차부품'),
    ('의류'),
    ('화학원료'),
    ('기계장비'),
    ('전자/IoT'),
    ('농산물'),
    ('의료기기'),
    ('무역서비스')
) AS v(name)
WHERE NOT EXISTS (
    SELECT 1 FROM tbl_category c WHERE c.category_name = v.name
);

-- =============================================================
-- [2] 상품 게시글 (tbl_post + tbl_post_product)
--     CTE 패턴: post INSERT → RETURNING id → 같은 id로 post_product INSERT
-- =============================================================
WITH product_data(
    seq, email, title, content, price, stock,
    category_name, location, s3_key, original_name
) AS (
    VALUES
    -- ===== EXPERT 5명 (자문 서비스) =====
    (1,  'seungwoo.han@globalgates.test',
     '한-EU FTA 활용 자문 패키지 (3개월)',
     'EU 수출 기업을 위한 한-EU FTA 종합 자문 서비스입니다. HS코드별 양허율 분석, 원산지결정기준(PSR) 적용, 인증수출자 지정 신청 대행을 포함합니다. CBAM 대응 사전 진단 1회 무료 제공. 평균 자문 기간 12주, 주 1회 정기 미팅으로 진행됩니다.',
     1500000, 99, '무역서비스', '서울 종로',
     '2026/05/20/product/product_01.jpg', 'product_fta_consulting.jpg'),

    (2,  'dohyun.lim@globalgates.test',
     '글로벌 해상·항공 운송 최적화 자문',
     '17년 경력 시니어 컨설턴트의 1:1 운송 최적화 자문 서비스입니다. 항로별 운임 벤치마크, 포워더 협상 전략, 위험화물(IMDG/IATA DGR) 운영 매뉴얼 제공. 부산항·인천공항·로테르담 라인 핸들링 경험을 바탕으로 한 실무 가이드 포함.',
     800000, 99, '무역서비스', '부산 중구',
     '2026/05/20/product/product_02.jpg', 'product_logistics_consulting.jpg'),

    (3,  'chaerin.yoon@globalgates.test',
     'HS코드 분류 자문 + 사전심사 대행',
     '관세사가 직접 진행하는 HS코드 분류 자문 + 사전심사(Advance Ruling) 신청 대행 서비스입니다. 복합기능 제품, 신소재, 액세서리·부분품 등 분쟁 우려 품목 특화. 결과 발급까지 평균 4~6주 소요, 통관 후 추징 리스크 사전 차단.',
     350000, 99, '무역서비스', '인천 중구',
     '2026/05/20/product/product_03.jpg', 'product_hscode_consulting.jpg'),

    (4,  'jaemin.oh@globalgates.test',
     'L/C 네고 자문 + 디스크레판시 대응',
     '시중은행 외환사업부 13년 경력 전문위원의 L/C 네고 자문 서비스입니다. UCP 600·URC 522 기반 서류 사전 점검, 디스크레판시 발생 시 매입은행 협상 대응, 포페이팅·D/A·D/P 솔루션 자문 포함.',
     500000, 99, '무역서비스', '서울 여의도',
     '2026/05/20/product/product_04.jpg', 'product_lc_consulting.jpg'),

    (5,  'jian.song@globalgates.test',
     '베트남 WFOE 법인 설립 자문',
     '호치민 거주 11년 컨설턴트의 베트남 100% 외투법인(WFOE) 설립 종합 자문입니다. DPI 등록부터 IRC·ERC 발급까지 풀프로세스 대행. 평균 처리 기간 60~90일, 인허가·세무·노무 사후관리 3개월 패키지 포함.',
     3000000, 20, '무역서비스', '베트남 호치민',
     '2026/05/20/product/product_05.jpg', 'product_vietnam_wfoe.jpg'),

    -- ===== PRO_PLUS 5명 =====
    (6,  'jaeho.kim@globalgates.test',
     'DDR5 32GB DRAM 모듈 (DDR5-4800)',
     '서버용 RDIMM 32GB DDR5-4800 모듈입니다. JEDEC 표준 준수, ECC 지원. 북미·유럽 OEM 어카운트 검증 완료 제품. MOQ 100개, 리드타임 6주. ICP(자율준수프로그램) 적용 품목으로 대중 수출 시 라이선스 사전 검토 필요.',
     165000, 500, '반도체', '경기 기흥',
     '2026/05/20/product/product_06.jpg', 'product_ddr5_module.jpg'),

    (7,  'jaeho.kim@globalgates.test',
     'HBM3E 12-Hi 스택 (PoC 샘플)',
     'AI 가속기용 HBM3E 12-Hi 스택 샘플입니다. 36GB 용량, 9.2Gbps 대역폭. 차세대 GPU 어셈블리 검증용으로 PoC 단위 공급 가능. 첨단 반도체 수출통제 대상 — 사전 라이선스 필수, 최종사용자 확약서 요구.',
     2400000, 30, '반도체', '경기 기흥',
     '2026/05/20/product/product_07.jpg', 'product_hbm3e_stack.jpg'),

    (8,  'sumin.lee@globalgates.test',
     '비건 시카 세럼 30ml (MOQ 3,000pcs)',
     '동남아 시장 대응 비건 시카 세럼 30ml입니다. EVE VEGAN 인증, 저자극 포뮬러. 베트남·인도네시아 디스트리뷰터 신규 발굴 중. MOQ 3,000개, 인도네시아 BPOM·말레이시아 NPRA 인증 별도 진행 필요.',
     8500, 3000, '화장품', '서울 강남',
     '2026/05/20/product/product_08.jpg', 'product_vegan_serum.jpg'),

    (9,  'sumin.lee@globalgates.test',
     '데일리 마스크팩 50매 (HALAL 인증)',
     'JAKIM HALAL 인증 데일리 마스크팩 50매 박스입니다. GCC·동남아 무슬림 시장 타깃. 사우디 SFDA·UAE ECAS 등록 완료. Shopee 라이브커머스 채널 ROAS 평균 320% 검증 완료된 제품.',
     12000, 1500, '화장품', '서울 강남',
     '2026/05/20/product/product_09.jpg', 'product_halal_maskpack.jpg'),

    (10, 'nayoung.kang@globalgates.test',
     'Amazon US 진출 컨설팅 패키지 (3개월)',
     'Amazon 미국 진출 90일 풀패키지 컨설팅입니다. LLC 설립·EIN·W-8BEN-E, Brand Registry, FNSKU 라벨링·FBA 입고, A+ 콘텐츠, PPC 운영(ACOS 30% 이하 유지)까지 풀스택 운영 대행. 초기 검증 리뷰 100건 확보 KPI 보장.',
     2500000, 20, '무역서비스', '서울 성수',
     '2026/05/20/product/product_10.jpg', 'product_amazon_consulting.jpg'),

    (11, 'haneul.cho@globalgates.test',
     'Alibaba Gold Supplier 풀패키지 운영',
     'Alibaba.com Gold Supplier 등급 + Verified Supplier 인증 풀세팅 + 6개월 운영 대행 패키지입니다. 다국어 미니사이트, RFQ 24시간 응답률 100%, Trade Assurance 비중 70% 달성 KPI 보장. 컨설팅 사례 매출 5배 성장 검증.',
     1800000, 30, '무역서비스', '서울 마포',
     '2026/05/20/product/product_11.jpg', 'product_alibaba_package.jpg'),

    (12, 'gaeun.moon@globalgates.test',
     '가정용 전자혈압계 (FDA 510(k))',
     '미국 FDA 510(k) 승인 완료 가정용 전자혈압계입니다. EU CE-MDR, 일본 PMDA 등록 완료. Bluetooth 연동 앱 포함, IEC 60601-1 의료기기 안전기준 준수. North America 채널 유통 가능, 24개월 무상 AS 제공.',
     45000, 800, '의료기기', '서울 송파',
     '2026/05/20/product/product_12.jpg', 'product_blood_pressure.jpg'),

    -- ===== PRO 5명 =====
    (13, 'jiwon.park@globalgates.test',
     '포기김치 1kg (수출용 진공포장)',
     '동남아·일본 수출용 포기김치 1kg 진공포장 제품입니다. HACCP·HALAL(말레이시아 JAKIM) 인증 완료. 콜드체인 유통 0~4℃ 유지, 유통기한 90일. 일본 후생노동성 잔류농약 기준 적합. 평균 인증 취득 6개월 단축 패키지 적용.',
     9500, 5000, '식품', '부산 해운대',
     '2026/05/20/product/product_13.jpg', 'product_kimchi_export.jpg'),

    (14, 'jiwon.park@globalgates.test',
     '발효 고추장 500g (FDA·HACCP)',
     '미국 시장 진출용 발효 고추장 500g 제품입니다. FDA 시설등록·FSVP 대응 완료, HACCP 인증. RASFF 이슈 사전 점검 완료, 라벨링 다국어(영·일·중) 번역 제공. 평균 미주 통관 5~7일.',
     6800, 4000, '식품', '부산 해운대',
     '2026/05/20/product/product_14.jpg', 'product_gochujang.jpg'),

    (15, 'taeyoung.jung@globalgates.test',
     'EV 배터리팩 하우징 (현대 NE PE)',
     '현대 NE PE(전기차 플랫폼) 적용 EV 배터리팩 하우징 부품입니다. IATF 16949 품질대응, ISO 14064 탄소배출량 산정체계 적용. 헝가리·폴란드 현지 EV 공장 직납 가능. CBAM 보고 의무 대응 준비 완료.',
     280000, 100, '자동차부품', '울산 북구',
     '2026/05/20/product/product_15.jpg', 'product_ev_housing.jpg'),

    (16, 'yena.choi@globalgates.test',
     'GRS 인증 재활용 폴리에스터 원단',
     '유럽 SPA 브랜드 OEM 표준 인증 원단입니다. GRS(Global Recycled Standard) + OEKO-TEX STANDARD 100 + BCI Cotton 동시 인증. 2026년 EU ESPR 디지털 제품여권(DPP) 대응 사전 준비 완료. 야드 단위 견적 가능.',
     4500, 8000, '의류', '대구 동구',
     '2026/05/20/product/product_16.jpg', 'product_grs_fabric.jpg'),

    (17, 'minho.hwang@globalgates.test',
     '5축 머시닝센터 MX-500',
     '동유럽 시장 진출용 5축 머시닝센터 MX-500입니다. CE 적합성 + Machinery Directive 2006/42/EC 준수, EU EORI 번호 확보. ISO 9001/14001 사내심사원 자격 보유 엔지니어가 직접 설치·운영교육 제공. 폴란드·체코 시장 검증 완료.',
     145000000, 5, '기계장비', '경남 창원',
     '2026/05/20/product/product_17.jpg', 'product_machining_center.jpg'),

    (18, 'hyunwoo.bae@globalgates.test',
     '스마트홈 IoT 게이트웨이 (CE/RoHS)',
     '독일·네덜란드 가전 바이어 대응 스마트홈 IoT 게이트웨이입니다. CE·RoHS·EPR(폐기물 회수) 등록 완료, A등급 에너지 효율 인증. Matter 표준 지원, AI 음성 어시스턴트 연동. 24개월 무상 AS, 평균 ASP 89,000원으로 마진율 안정적.',
     89000, 600, '전자/IoT', '광주 광산',
     '2026/05/20/product/product_18.jpg', 'product_iot_gateway.jpg'),

    -- ===== FREE 5명 =====
    (19, 'yujin.noh@globalgates.test',
     'LDPE 수입 원료 (사우디산, 25MT 단위)',
     '사우디 SABIC 직수입 LDPE 원료입니다. 25MT 컨테이너 단위 공급, 6개월 선물환 헤지 운영 중. 부산항 도착 기준 견적 제공, 통관·내륙운송 별도. 환변동 헤지 + K-SURE 환변동보험 병행 활용으로 환차손 최소화.',
     1650000, 25, '화학원료', '인천 연수',
     '2026/05/20/product/product_19.jpg', 'product_ldpe_resin.jpg'),

    (20, 'yujin.noh@globalgates.test',
     'PVC 컴파운드 K67 (싱가포르)',
     '싱가포르 트레이더 직거래 PVC 컴파운드 K67 그레이드입니다. 20MT 단위, 사이클 평균 8주. 통화옵션 콜라(Collar) 구조 40% 헤지 운영. 한국수출입은행 무역금융 솔루션 연계 가능, 최소 거래 단위 1컨테이너부터.',
     1420000, 30, '화학원료', '인천 연수',
     '2026/05/20/product/product_20.jpg', 'product_pvc_compound.jpg'),

    (21, 'siwoo.yang@globalgates.test',
     '설향 딸기 2kg (홍콩 항공 직송)',
     '대전 유성 자체농장 산지직송 설향 딸기 2kg 박스입니다. 산지 예냉(0~2℃) 6시간 의무, 인천공항 보세창고 2시간 이내 적재, 항공기내 +4℃ 정온 유지. 컨테이너 데이터로거 전 구간 부착. 농식품부 수출 유망주체 선정 농장.',
     38000, 200, '농산물', '대전 유성',
     '2026/05/20/product/product_21.jpg', 'product_strawberry.jpg'),

    (22, 'siwoo.yang@globalgates.test',
     '컬러 파프리카 1kg (네덜란드 수출)',
     '네덜란드 수출 검역 통과 컬러 파프리카 1kg 팩(빨강·노랑 혼합)입니다. SPS 협정 잔류농약 기준 적합, 콜드체인 5~8℃ 유지. 유럽 EFSA 식품안전 기준 적합성 검증 완료. 주 2회 항공편 정기 출하.',
     8500, 1000, '농산물', '대전 유성',
     '2026/05/20/product/product_22.jpg', 'product_paprika.jpg'),

    (23, 'yerin.shin@globalgates.test',
     '수출보험 가입 자문 (K-SURE 출신)',
     '한국무역보험공사 출신 전문위원의 수출보험 가입 자문 서비스입니다. 단기수출보험(선적후)·환변동보험·중소중견 Plus+ 특약(보험료 50% 할인) 등 자사 수출구조 진단 후 최적 상품 조합 제안. 가입 후 보험금 청구 단계까지 풀서포트.',
     250000, 99, '무역서비스', '서울 강서',
     '2026/05/20/product/product_23.jpg', 'product_export_insurance.jpg'),

    (24, 'taewoo.kwon@globalgates.test',
     'FCL/LCL 견적·예약 서비스',
     '14년 경력 포워더의 FCL·LCL·항공 통합 견적 서비스입니다. 5월 SCFI 기준 상해-유럽 라인 +12% 동향 반영, 분기 단위 운임 계약 + 선복 우선 확보(Space Allocation) 동시 진행. 위험화물(IMO/IATA DGR), Reefer 정온 콘테이너 핸들링 전문.',
     50000, 999, '무역서비스', '부산 강서',
     '2026/05/20/product/product_24.jpg', 'product_freight_service.jpg'),

    (25, 'seonho.baek@globalgates.test',
     '브라질 시장 진출 자문 (ICMS 포함)',
     'KOTRA 상파울루·멕시코시티 9년 근무 경력의 브라질 시장 진출 자문 서비스입니다. II(수입관세)·IPI·PIS/COFINS·ICMS(7~25%) 다층 조세구조 분석, 산타카타리나·에스피리투산투 주 활용 스킴 자문 포함. 현지 세무 자문사 매칭.',
     1800000, 20, '무역서비스', '서울 영등포',
     '2026/05/20/product/product_25.jpg', 'product_brazil_market.jpg')
),
inserted_posts AS (
    INSERT INTO tbl_post (member_id, post_status, title, content, location)
    SELECT m.id, 'active'::post_status, pd.title, pd.content, pd.location
    FROM product_data pd
    JOIN tbl_member m ON m.member_email = pd.email
    ORDER BY pd.seq
    RETURNING id, title
)
INSERT INTO tbl_post_product (id, product_category_id, product_price, product_stock)
SELECT ip.id, c.id, pd.price, pd.stock
FROM product_data pd
JOIN inserted_posts ip ON ip.title = pd.title
JOIN tbl_category c ON c.category_name = pd.category_name;

-- =============================================================
-- [3] 상품 이미지 (tbl_file + tbl_post_file)
--     이미지가 없는 상품(01,02,03,04,05,07,10,11,18,20,24)은 의도적으로 제외.
--     화면에서는 post-detailed.html 의 fallback 로고가 노출됨.
-- =============================================================
WITH product_image_data(email, post_title, original_name, s3_key) AS (
    VALUES
    ('jaeho.kim@globalgates.test',     'DDR5 32GB DRAM 모듈 (DDR5-4800)',               'product_ddr5_module.jpg',          '2026/05/20/product/product_06.jpg'),
    ('sumin.lee@globalgates.test',     '비건 시카 세럼 30ml (MOQ 3,000pcs)',            'product_vegan_serum.jpg',          '2026/05/20/product/product_08.jpg'),
    ('sumin.lee@globalgates.test',     '데일리 마스크팩 50매 (HALAL 인증)',             'product_halal_maskpack.jpg',       '2026/05/20/product/product_09.jpg'),
    ('gaeun.moon@globalgates.test',    '가정용 전자혈압계 (FDA 510(k))',                'product_blood_pressure.jpg',       '2026/05/20/product/product_12.jpg'),
    ('jiwon.park@globalgates.test',    '포기김치 1kg (수출용 진공포장)',                'product_kimchi_export.jpg',        '2026/05/20/product/product_13.jpg'),
    ('jiwon.park@globalgates.test',    '발효 고추장 500g (FDA·HACCP)',                  'product_gochujang.jpg',            '2026/05/20/product/product_14.jpg'),
    ('taeyoung.jung@globalgates.test', 'EV 배터리팩 하우징 (현대 NE PE)',               'product_ev_housing.jpg',           '2026/05/20/product/product_15.jpg'),
    ('yena.choi@globalgates.test',     'GRS 인증 재활용 폴리에스터 원단',               'product_grs_fabric.jpg',           '2026/05/20/product/product_16.jpg'),
    ('minho.hwang@globalgates.test',   '5축 머시닝센터 MX-500',                         'product_machining_center.jpg',     '2026/05/20/product/product_17.jpg'),
    ('yujin.noh@globalgates.test',     'LDPE 수입 원료 (사우디산, 25MT 단위)',          'product_ldpe_resin.jpg',           '2026/05/20/product/product_19.jpg'),
    ('siwoo.yang@globalgates.test',    '설향 딸기 2kg (홍콩 항공 직송)',                'product_strawberry.jpg',           '2026/05/20/product/product_21.jpg'),
    ('siwoo.yang@globalgates.test',    '컬러 파프리카 1kg (네덜란드 수출)',             'product_paprika.jpg',              '2026/05/20/product/product_22.jpg'),
    ('yerin.shin@globalgates.test',    '수출보험 가입 자문 (K-SURE 출신)',              'product_export_insurance.jpg',     '2026/05/20/product/product_23.jpg'),
    ('seonho.baek@globalgates.test',   '브라질 시장 진출 자문 (ICMS 포함)',             'product_brazil_market.jpg',        '2026/05/20/product/product_25.jpg')
),
inserted_files AS (
    INSERT INTO tbl_file (original_name, file_name, file_path, file_size, content_type)
    SELECT pid.original_name, pid.s3_key, pid.s3_key, 256000, 'image'::file_content_type
    FROM product_image_data pid
    RETURNING id, file_path
)
INSERT INTO tbl_post_file (post_id, file_id)
SELECT p.id, f.id
FROM product_image_data pid
JOIN tbl_member m ON m.member_email = pid.email
JOIN tbl_post p ON p.member_id = m.id AND p.title = pid.post_title
JOIN inserted_files f ON f.file_path = pid.s3_key
JOIN tbl_post_product pp ON pp.id = p.id;

-- =============================================================
-- [4] 해시태그 매핑 (기존 해시태그 재활용 — 회원 SQL이 만든 40개)
-- =============================================================
INSERT INTO tbl_post_hashtag_rel (post_id, hashtag_id)
SELECT DISTINCT p.id, h.id
FROM tbl_post p
JOIN tbl_post_product pp ON pp.id = p.id
JOIN tbl_member m ON m.id = p.member_id
JOIN tbl_post_hashtag h ON
    (p.title LIKE '%한-EU FTA%'        AND h.tag_name IN ('FTA','수출','관세','유럽수출'))
 OR (p.title LIKE '%해상·항공 운송%'   AND h.tag_name IN ('물류','컨테이너운임','FCL','LCL'))
 OR (p.title LIKE '%HS코드 분류%'      AND h.tag_name IN ('관세','통관','수출'))
 OR (p.title LIKE '%L/C 네고%'         AND h.tag_name IN ('LC','수출'))
 OR (p.title LIKE '%베트남 WFOE%'      AND h.tag_name IN ('베트남시장','수출','RCEP'))
 OR (p.title LIKE '%DDR5%'             AND h.tag_name IN ('반도체','수출','무역'))
 OR (p.title LIKE '%HBM3E%'            AND h.tag_name IN ('HBM','반도체','수출'))
 OR (p.title LIKE '%비건 시카 세럼%'   AND h.tag_name IN ('K뷰티','화장품수출','수출'))
 OR (p.title LIKE '%마스크팩%'         AND h.tag_name IN ('K뷰티','HALAL','화장품수출','중동시장'))
 OR (p.title LIKE '%Amazon US 진출%'   AND h.tag_name IN ('아마존수출','미주수출','수출'))
 OR (p.title LIKE '%Alibaba Gold%'     AND h.tag_name IN ('알리바바','수출'))
 OR (p.title LIKE '%전자혈압계%'       AND h.tag_name IN ('의료기기수출','FDA','미주수출'))
 OR (p.title LIKE '%포기김치%'         AND h.tag_name IN ('K푸드','수출','HACCP','HALAL'))
 OR (p.title LIKE '%발효 고추장%'      AND h.tag_name IN ('K푸드','FDA','HACCP','미주수출'))
 OR (p.title LIKE '%EV 배터리팩%'      AND h.tag_name IN ('전기차부품','자동차부품','수출','CBAM'))
 OR (p.title LIKE '%재활용 폴리에스터%' AND h.tag_name IN ('의류수출','유럽수출','수출'))
 OR (p.title LIKE '%5축 머시닝센터%'   AND h.tag_name IN ('기계장비수출','유럽수출','CE인증'))
 OR (p.title LIKE '%IoT 게이트웨이%'   AND h.tag_name IN ('유럽수출','수출','CE인증'))
 OR (p.title LIKE '%LDPE%'             AND h.tag_name IN ('석유화학','수입','환헤지'))
 OR (p.title LIKE '%PVC%'              AND h.tag_name IN ('석유화학','수입','환헤지'))
 OR (p.title LIKE '%설향 딸기%'        AND h.tag_name IN ('K푸드','수출','콜드체인','인천공항'))
 OR (p.title LIKE '%컬러 파프리카%'    AND h.tag_name IN ('K푸드','유럽수출','콜드체인'))
 OR (p.title LIKE '%수출보험 가입%'    AND h.tag_name IN ('수출보험','수출','환헤지'))
 OR (p.title LIKE '%FCL/LCL 견적%'     AND h.tag_name IN ('FCL','LCL','물류','컨테이너운임'))
 OR (p.title LIKE '%브라질 시장 진출%' AND h.tag_name IN ('수출','관세'))
WHERE m.member_email LIKE '%@globalgates.test'
ON CONFLICT DO NOTHING;

COMMIT;

-- =============================================================
-- 검증 — 분포가 예상대로인지 확인
-- =============================================================
SELECT 'products'      AS what, COUNT(*) AS cnt
FROM tbl_post_product pp
JOIN tbl_post p ON p.id = pp.id
JOIN tbl_member m ON m.id = p.member_id
WHERE m.member_email LIKE '%@globalgates.test'
UNION ALL SELECT 'product_files', COUNT(*)
FROM tbl_post_file pf
JOIN tbl_post p ON p.id = pf.post_id
JOIN tbl_post_product pp ON pp.id = p.id
JOIN tbl_member m ON m.id = p.member_id
WHERE m.member_email LIKE '%@globalgates.test'
UNION ALL SELECT 'product_hashtag_rels', COUNT(*)
FROM tbl_post_hashtag_rel hr
JOIN tbl_post p ON p.id = hr.post_id
JOIN tbl_post_product pp ON pp.id = p.id
JOIN tbl_member m ON m.id = p.member_id
WHERE m.member_email LIKE '%@globalgates.test';

SELECT c.category_name, COUNT(*) AS cnt
FROM tbl_post_product pp
JOIN tbl_category c ON c.id = pp.product_category_id
JOIN tbl_post p ON p.id = pp.id
JOIN tbl_member m ON m.id = p.member_id
WHERE m.member_email LIKE '%@globalgates.test'
GROUP BY c.category_name
ORDER BY cnt DESC, c.category_name;

SELECT m.member_email, COUNT(*) AS products
FROM tbl_post_product pp
JOIN tbl_post p ON p.id = pp.id
JOIN tbl_member m ON m.id = p.member_id
WHERE m.member_email LIKE '%@globalgates.test'
GROUP BY m.member_email
ORDER BY products DESC, m.member_email;
