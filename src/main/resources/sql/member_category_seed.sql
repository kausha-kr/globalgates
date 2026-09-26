-- 멤버(id 7~26) ↔ 카테고리 매핑 시드
-- 사용법: psql -U globalgates -d globalgates -f member_category_seed.sql
-- 특징:
--   * tbl_member 에는 category 컬럼이 없음. M:N 관계 테이블에 INSERT.
--   * category_name 으로 JOIN → 환경별 category id 차이에 안전.
--   * BEGIN/COMMIT + 사전 DELETE 로 멱등(반복 실행 가능).

BEGIN;

-- 7~26 범위 기존 매핑 제거 (멱등성)
DELETE FROM tbl_member_category_rel WHERE member_id BETWEEN 7 AND 26;

INSERT INTO tbl_member_category_rel (member_id, category_id)
SELECT v.member_id, c.id
FROM (VALUES
    -- 7 김재호: Semicom Korea 해외영업 → 수출, IT, 반도체
    (7,  '수출'), (7,  'IT'), (7,  '반도체'),
    -- 8 이수민: Lumiere Cosmetic → 수출, 화장품
    (8,  '수출'), (8,  '화장품'),
    -- 9 박지원: Korea Food World 수출 → 수출, 식품, 가공식품
    (9,  '수출'), (9,  '식품'), (9,  '가공식품'),
    -- 10 정태영: Ulsan AutoParts → 수출, 자동차, 자동차부품
    (10, '수출'), (10, '자동차'), (10, '자동차부품'),
    -- 11 최예나: EcoFabric 수출 MD → 수출, 섬유/의류
    (11, '수출'), (11, '섬유/의류'),
    -- 12 한승우: FTA 컨설턴트 → 관세, FTA
    (12, '관세'), (12, 'FTA'),
    -- 13 윤채린: 관세사 인천공항 통관 → 관세, 통관
    (13, '관세'), (13, '통관'),
    -- 14 임도현: 국제물류 → 물류
    (14, '물류'),
    -- 15 강나영: Global Marketing → 무역서비스
    (15, '무역서비스'),
    -- 16 오재민: 무역금융 → 금융, 무역금융
    (16, '금융'), (16, '무역금융'),
    -- 17 송지안: 동남아 자문 호치민 → 무역서비스, 동남아
    (17, '무역서비스'), (17, '동남아'),
    -- 18 배현우: EuroTech 함부르크 → 수입, 유럽
    (18, '수입'), (18, '유럽'),
    -- 19 노유진: Chemical 원료수입 → 수입, 원자재, 화학원료
    (19, '수입'), (19, '원자재'), (19, '화학원료'),
    -- 20 황민호: MachineWorks 해외영업 → 수출, 기계/장비
    (20, '수출'), (20, '기계/장비'),
    -- 21 신예린: 수출보험 K-SURE → 금융, 보험
    (21, '금융'), (21, '보험'),
    -- 22 권태우: 포워더 FCL/LCL/항공 → 물류, 해운, 항공
    (22, '물류'), (22, '해운'), (22, '항공'),
    -- 23 조하늘: Digital Trade Hub → IT, 플랫폼
    (23, 'IT'), (23, '플랫폼'),
    -- 24 양시우: Fresh Farm 수출 → 수출, 식품, 농산물
    (24, '수출'), (24, '식품'), (24, '농산물'),
    -- 25 문가은: HealthGlobal Med RA → 의료기기
    (25, '의료기기'),
    -- 26 백선호: 중남미 통상 KOTRA → 미주, 무역서비스
    (26, '미주'), (26, '무역서비스')
) AS v(member_id, cat_name)
JOIN tbl_category c ON c.category_name = v.cat_name;

-- 검증: 멤버별 매핑된 카테고리 리스트
SELECT m.id,
       m.member_nickname,
       string_agg(c.category_name, ', ' ORDER BY c.id) AS categories
FROM tbl_member m
LEFT JOIN tbl_member_category_rel r ON r.member_id = m.id
LEFT JOIN tbl_category c ON c.id = r.category_id
WHERE m.id BETWEEN 7 AND 26
GROUP BY m.id, m.member_nickname
ORDER BY m.id;

COMMIT;
