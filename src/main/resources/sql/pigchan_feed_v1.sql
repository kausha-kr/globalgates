-- =============================================================
-- pigchan_feed_v1.sql
-- pigchan0202@gmail.com (id=6) 마이페이지 게시글 시드
--   - 12개 본문 게시글, 2025-11-12 ~ 2026-05-19 범위로 무작위 분산
--   - 각 게시글에 @globalgates.test 회원들이 전문 무역 도메인 답변/대댓글
--   - 인과관계·문맥 흐름 유지: 첫 댓글의 보강 발언 → pigchan 후속질문 → 답변 → 추가맥락
--   - KOTRA / 관세청 / K-SURE / KMI / KFIU / EU DG TAXUD / FDA FSPCA / KOSTI 등
--     공신력 있는 기관의 가이드/매뉴얼/사례집 인용
--   - 멱등 재실행 안전 (pigchan 본인 게시글 + 그 트리만 재귀 삭제 후 재적재)
-- 실행:
--   ssh -i KEY USER@HOST 'PGPASSWORD=1234 psql -h localhost -U globalgates -d globalgates -v ON_ERROR_STOP=1' < pigchan_feed_v1.sql
-- =============================================================

BEGIN;

-- =============================================================
-- [0] Owner = pigchan
-- =============================================================
CREATE TEMPORARY TABLE _gg_pf_owner ON COMMIT DROP AS
SELECT id FROM tbl_member
WHERE member_email = 'pigchan0202@gmail.com'
  AND member_status = 'active'::member_status
LIMIT 1;

DO $owner_check$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM _gg_pf_owner) THEN
        RAISE EXCEPTION 'owner pigchan0202@gmail.com not found or inactive';
    END IF;
END $owner_check$;

-- =============================================================
-- [1] CLEANUP — pigchan 본인 글 + 그 글에 달린 모든 댓글/답글 재귀 삭제
-- =============================================================
WITH RECURSIVE thread AS (
    SELECT id FROM tbl_post
    WHERE member_id = (SELECT id FROM _gg_pf_owner)
      AND reply_post_id IS NULL
    UNION ALL
    SELECT p.id FROM tbl_post p JOIN thread t ON p.reply_post_id = t.id
)
DELETE FROM tbl_post_hashtag_rel WHERE post_id IN (SELECT id FROM thread);

WITH RECURSIVE thread AS (
    SELECT id FROM tbl_post
    WHERE member_id = (SELECT id FROM _gg_pf_owner)
      AND reply_post_id IS NULL
    UNION ALL
    SELECT p.id FROM tbl_post p JOIN thread t ON p.reply_post_id = t.id
)
DELETE FROM tbl_post_like WHERE post_id IN (SELECT id FROM thread);

WITH RECURSIVE thread AS (
    SELECT id FROM tbl_post
    WHERE member_id = (SELECT id FROM _gg_pf_owner)
      AND reply_post_id IS NULL
    UNION ALL
    SELECT p.id FROM tbl_post p JOIN thread t ON p.reply_post_id = t.id
)
DELETE FROM tbl_post_file WHERE post_id IN (SELECT id FROM thread);

WITH RECURSIVE thread AS (
    SELECT id FROM tbl_post
    WHERE member_id = (SELECT id FROM _gg_pf_owner)
      AND reply_post_id IS NULL
    UNION ALL
    SELECT p.id FROM tbl_post p JOIN thread t ON p.reply_post_id = t.id
)
DELETE FROM tbl_post WHERE id IN (SELECT id FROM thread);

-- =============================================================
-- [2] 본문 + 댓글 + 답글 — PL/pgSQL DO 블록으로 ID 추적
-- =============================================================
DO $pf$
DECLARE
    owner_id bigint;
    post_id  bigint;
    c_id     bigint;
    r_id     bigint;
BEGIN
    SELECT id INTO owner_id FROM _gg_pf_owner;

    -- =========================================================
    -- POST 1 — 2025-11-12 09:34  무역금융 인사이트
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$첫 L/C 네고에서 만난 디스크레판시 4건 — UCP 600 기준 사전 점검 체크리스트 정리$T$,
        $B$KOTRA 무역경영지원실의 신용장 실무 가이드와 KEB하나은행·신한은행 외환사업부 매뉴얼을 참고하여 L/C 매입 단계에서 디스크레판시 발생 빈도가 높은 항목을 사전 점검 체크리스트로 정리해보았습니다. UCP 600 제14조(서류심사기준)와 제16조(불일치 서류 처리 절차)를 기준으로 자주 발생하는 4가지를 공유합니다.

1) Shipping Mark 와 Commercial Invoice 의 표기 불일치
   - 컨테이너 적입 단계에서 자주 발생하는 항목입니다. Shipping Order(SO) 양식과 동일하게 표기를 통일하는 사내 SOP 가 가장 효과적이었습니다.

2) B/L 의 'Shipped on Board' notation 일자 누락
   - Master B/L 의 on-board notation 일자 누락이 빈번합니다. 선사 도장으로 사후 보정 가능하나, 평균 3~5영업일 매입 지연이 발생합니다.

3) 보험서류의 부보 통화/금액 불일치
   - Commercial Invoice 통화 대비 110% 부보 원칙(UCP 600 28조 f.ii). ISO 4217 통화 코드 알파벳 3자리 표기 누락 시 매입은행 측 디스크 처리됩니다.

4) 원산지증명서(C/O)의 서명 권한자 불일치
   - 대한상공회의소 발급 시 등록된 서명권자만 인정됩니다. 인증수출자 자체발급 케이스는 별도 인증번호 기재가 필요합니다.

실무에서는 결국 제출 전 사내 외환담당이 매입은행 인터내셔널 데스크와 사전 협의를 거치는 것이 가장 빠른 길이었습니다. 다음 글에서는 디스크 발생 시 매입은행과의 협상 전략을 다루겠습니다.$B$,
        '서울 종로', 16, '2025-11-12 09:34:00'::timestamp, '2025-11-12 09:34:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: jaemin.oh (L/C 자문 전문가)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jaemin.oh@globalgates.test'),
        'active'::post_status,
        $C$정리 감사합니다. UCP 600 제16조 c항의 매입은행 단일통지(single notice) 원칙도 함께 메모해 두시면 좋습니다. 디스크레판시 발생 후 보완 통지가 도달한 시점부터 ICC URDG 758 기준 영업일 7일 안에 매입은행 인터내셔널 데스크와 직접 보완 협의를 진행하시는 것이 매입 지연 최소화에 결정적입니다. ICC Banking Commission Opinion R.749 의 부정기선 관련 의견서도 함께 검토 권장드립니다.$C$,
        post_id, '2025-11-12 11:02:00'::timestamp, '2025-11-12 11:02:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$말씀하신 R.749 의견서는 저희가 부정기선 운송 비중이 있어 평소 주시하고 있던 항목입니다. UCP 600 제22조 (Charter Party B/L) 적용 여부가 매입은행별로 해석이 갈리는 부분이 있어, 케이스별 자문 부탁드릴 일이 분명 있을 것 같습니다. 사전에 자료 정리해서 별도 연락드리겠습니다.$C$,
        c_id, '2025-11-12 13:14:00'::timestamp, '2025-11-12 13:14:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: jaemin.oh
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jaemin.oh@globalgates.test'),
        'active'::post_status,
        $C$부정기선 케이스는 BIMCO 표준 양식(GENCON 1994/2022) 적용 여부에 따라 매입은행별 해석 차이가 큽니다. 사안 정리되시면 별도 채널로 검토 의견서 공유 가능합니다. 사전 협의 단계에서 매입은행 측 시니어 심사역 검토를 거치는 편이 추후 분쟁 예방에 효과적입니다.$C$,
        r_id, '2025-11-12 15:32:00'::timestamp, '2025-11-12 15:32:00'::timestamp);

    -- 댓글 2: jaeho.kim (반도체 PRO+, L/C 결제 경험)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jaeho.kim@globalgates.test'),
        'active'::post_status,
        $C$저희도 DDR 모듈 수출 시 ISO 4217 통화 표기 누락 케이스를 경험한 바 있습니다. EUR 을 € 기호로 줄여 적으면 매입은행 인터내셔널 데스크가 디스크로 처리하는 일이 잦았습니다. 매수인 측 개설은행이 ECB 의 통화 표기 권고안을 따르는 경우가 많아, 사내 양식부터 통화 약어 사용을 금지하는 통제가 안전합니다.$C$,
        post_id, '2025-11-12 14:08:00'::timestamp, '2025-11-12 14:08:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$ECB 의 통화 표기 권고안에도 ISO 4217 알파벳 3자리를 표준으로 권장하고 있어 같은 흐름으로 이해됩니다. 저희도 동일 케이스로 매입이 지연된 적이 있어 사내 표준 양식 개정 작업을 진행 중입니다. 공유 감사합니다.$C$,
        c_id, '2025-11-13 09:21:00'::timestamp, '2025-11-13 09:21:00'::timestamp);

    -- 댓글 3: chaerin.yoon (관세사, HS코드 자문)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='chaerin.yoon@globalgates.test'),
        'active'::post_status,
        $C$원산지증명서 항목과 관련하여 한 가지 보강 의견 드립니다. 한-EU FTA 의 경우 EUR.1 대신 원산지신고서(Origin Declaration) 방식이라 발급기관 서명이 없는 양식이 정상입니다. 매입은행 일부는 EUR.1 양식만 인정하는 경우가 있어 사전 안내가 필요합니다. 관세청 자유무역협정집행과의 'FTA 활용 가이드 2025 개정판' 별표 3 참고 부탁드립니다.$C$,
        post_id, '2025-11-13 16:45:00'::timestamp, '2025-11-13 16:45:00'::timestamp);


    -- =========================================================
    -- POST 2 — 2025-12-03 14:50  해운물류 전문가 모임
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$부산항→로테르담 SCFI 38% 급등 흡수 사례 — 분기 운임계약 + Space Allocation 운영기$T$,
        $B$11월 둘째 주 부산항만공사 발표 기준 SCFI Europe 라인 운임이 4주간 38.4% 상승했습니다. 인천공항·로테르담 라인 항공운임도 동기간 21% 상승해 화주 입장에서 운임 변동성 대응이 어느 때보다 중요해졌습니다. 저희는 분기 단위 운임계약(Quarterly Rate Agreement)에 Space Allocation(선복 우선확보) 조건을 결합한 형태로 운영 중인데, 다음 항목이 핵심이었습니다.

1) MQC(Minimum Quantity Commitment) 90% 충족 시 인센티브 USD 80/TEU
2) 분기 평균 SCFI 기준선 ±15% 밴드, 밴드 이탈 시 양측 협상 재개
3) Reefer / 위험화물(IMDG) 별도 단가 락(Lock) 조항
4) 부킹 캔슬 시 Dead Freight 면제 조건(MQC 충족 시)
5) Free time 14일 / Demurrage USD 220/day (PortPlus 등급 화주 기준)

KMI 한국해양수산개발원의 2025년 4분기 컨테이너 운임 동향 리포트와 부산항만공사 BPA 운영동향 자료를 함께 검토하면 분기 기준선 설정이 한결 수월합니다. 다음 분기는 항만 선석 부족이 변수가 될 것으로 보입니다.$B$,
        '부산 강서', 17, '2025-12-03 14:50:00'::timestamp, '2025-12-03 14:50:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: dohyun.lim (해운 EXPERT, 17년 시니어)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='dohyun.lim@globalgates.test'),
        'active'::post_status,
        $C$분기 운임계약은 좋은 선택이셨습니다. 한 가지 보완점을 말씀드리면, SCFI 단일 기준선 대신 Drewry WCI 의 부산-로테르담 라인 별도 인덱스를 보조 기준선으로 함께 두시면 단일 인덱스의 일시적 왜곡(특히 중국발 비중)에 대한 완충 효과를 얻으실 수 있습니다. 머스크와 CMA CGM 의 대형 화주 계약은 보통 SCFI+WCI 가중평균을 기준선으로 잡습니다.$C$,
        post_id, '2025-12-03 17:22:00'::timestamp, '2025-12-03 17:22:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$Drewry WCI 의 부산-로테르담 라인 별도 인덱스 활용은 처음 알았습니다. 보조 기준선 도입을 다음 갱신 시 협상 안건에 반영하겠습니다. 한국해양수산개발원 KMI 의 자료에도 두 인덱스 가중평균 방식이 'Hybrid Benchmark' 로 언급되어 있어 같은 맥락으로 이해됩니다. 가중치 비율은 어떻게 운영하시는 것이 일반적인지요?$C$,
        c_id, '2025-12-04 09:48:00'::timestamp, '2025-12-04 09:48:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: dohyun.lim
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='dohyun.lim@globalgates.test'),
        'active'::post_status,
        $C$일반적으로 SCFI 60 : Drewry WCI 40 비율이 시장 표준에 가깝습니다. 다만 부산-유럽처럼 중국발 인덱스 영향이 큰 라인은 50:50 도 무리가 없습니다. 항공 라인에서는 TAC Index 와 Baltic Air Index 도 함께 보시는 것을 권장드립니다. 인천-프랑크푸르트는 두 지수 간 괴리가 큰 구간이 분기당 한 차례씩 발생합니다.$C$,
        r_id, '2025-12-04 11:30:00'::timestamp, '2025-12-04 11:30:00'::timestamp);

    -- 댓글 2: taewoo.kwon (포워더 14년)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='taewoo.kwon@globalgates.test'),
        'active'::post_status,
        $C$Free time 14일은 PortPlus 등급 화주 기준으로는 시장 평균보다 다소 짧은 편입니다. 부산-유럽 라인은 트랜짓 평균 28일 + 도착항 작업 4~6일을 고려하면 18~21일 협상이 시장 평균에 가깝습니다. 갱신 시 14 → 18 협상 여지가 충분합니다. 디멀리지 단가 인하는 협상 폭이 좁으니 Free time 협상에 우선순위 두시는 것을 권장드립니다.$C$,
        post_id, '2025-12-04 10:11:00'::timestamp, '2025-12-04 10:11:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$PortPlus 화주 기준선이라고만 알고 있었는데, 시장 평균 데이터를 함께 보니 협상 폭이 명확해집니다. 디멀리지 단가 인하 협상은 무게가 무거울 것 같아 Free time 협상에 우선순위를 두겠습니다. 협상 자료에 인용할 만한 시장 평균 데이터 출처가 있으신지요?$C$,
        c_id, '2025-12-04 13:42:00'::timestamp, '2025-12-04 13:42:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: taewoo.kwon
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='taewoo.kwon@globalgates.test'),
        'active'::post_status,
        $C$한국통합물류협회 KIFFA 의 분기 'Free time/Demurrage 시장 평균 리포트' 와 부산항만공사 BPA 의 분기 운영동향 자료를 함께 인용하시면 객관성이 확보됩니다. KIFFA 자료는 회원사 한정 공개라 별도 요청 시 부분 발췌 형태로 공유 가능합니다.$C$,
        r_id, '2025-12-04 16:08:00'::timestamp, '2025-12-04 16:08:00'::timestamp);

    -- 댓글 3: minho.hwang (기계장비, IMDG 화물 경험)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='minho.hwang@globalgates.test'),
        'active'::post_status,
        $C$5축 머시닝센터를 EU 입찰로 출하할 때 IMDG Class 9 (PLC 내장 Lithium Battery) 분류로 별도 단가 락이 핵심이었습니다. 분기계약에 위험화물 단가를 분리해 놓으신 점이 매우 좋은 모범사례라고 생각합니다. UN 3481(Lithium Ion Battery Packed with Equipment) 분류 적용 시 평균 USD 380/TEU 추가 단가가 발생합니다.$C$,
        post_id, '2025-12-05 08:55:00'::timestamp, '2025-12-05 08:55:00'::timestamp);


    -- =========================================================
    -- POST 3 — 2025-12-21 22:08  FTA·관세 실무 스터디
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$RCEP 4년차 활용도 진단 — 한-아세안 FTA 와 병행 운영 시 양허율·원산지결정기준(PSR) 충돌 케이스$T$,
        $B$한국무역협회 KITA Trade Brief 2025년 12월호와 산업통상자원부 자유무역협정정책관실의 자료를 참고하여 RCEP 4년차 활용도를 자체 진단해보았습니다. 동일 품목군에 한-아세안 FTA 와 RCEP 두 협정이 병행 적용 가능한 경우, 양허 스케줄 차이와 원산지결정기준(PSR) 차이로 어느 협정을 선택하느냐가 관세 절감폭을 좌우합니다.

- HS 8517.62 (네트워크 장비)
  한-아세안 FTA 기본세율 0%, RCEP 도 2026년부터 0%. 다만 한-아세안 FTA 는 CTH(Change of Tariff Heading) 기준, RCEP 는 RVC(Regional Value Content) 40% 기준 — 부품 글로벌 소싱 비중 높은 제품은 RCEP 가 유리합니다.

- HS 3304.99 (화장품 기타)
  한-아세안 FTA 가 RCEP 보다 양허 폭 0.8%p 더 큼. 다만 한-아세안 FTA 는 PSR 가 CTH+VAC 50% 이중기준, RCEP 는 CTSH 단일기준이라 중간재 원산지 입증 부담이 작습니다.

양허 스케줄과 PSR 모두 검토한 뒤 협정선택서(Statement of Origin under Selected Agreement)를 명시적으로 첨부하는 것이 통관 단계의 분쟁 예방에 도움이 됩니다. 관세청 자유무역협정집행과의 'FTA 활용 가이드 2025 개정판' 별표 7 참고 권장드립니다.$B$,
        '서울 종로', 14, '2025-12-21 22:08:00'::timestamp, '2025-12-21 22:08:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: chaerin.yoon (관세사)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='chaerin.yoon@globalgates.test'),
        'active'::post_status,
        $C$정확한 진단입니다. 한 가지 덧붙이면, RCEP 의 누적기준(Accumulation) 적용 시 동남아 다국 분업 생산구조에서 상당한 가산점이 나옵니다. 베트남 1차가공 + 태국 2차가공 케이스에서 한-아세안 FTA 로는 PSR 미충족이지만 RCEP 의 완전누적(Full Cumulation) 적용 시 충족되는 사례를 두 건 처리한 바 있습니다. 관세청 'RCEP 활용 사례집 2024' 의 케이스 12~14 참조 부탁드립니다.$C$,
        post_id, '2025-12-22 09:14:00'::timestamp, '2025-12-22 09:14:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$완전누적은 저희도 시뮬레이션해본 적이 있는데, 베트남-태국 협력 공정의 입증 서류 정합성이 까다로워 미적용해왔습니다. 사례집 12~14 케이스 확인해보겠습니다. 혹시 입증 서류 작성 시 표준 양식이 있다면 별도 자료 공유 가능하실까요?$C$,
        c_id, '2025-12-22 13:55:00'::timestamp, '2025-12-22 13:55:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: chaerin.yoon
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='chaerin.yoon@globalgates.test'),
        'active'::post_status,
        $C$관세청 RCEP 누적기준 매뉴얼의 부록 D 에 표준 양식이 첨부되어 있습니다. 다국 분업 케이스는 'Operational Certification Procedures(OCP)' 의 4.2 항을 함께 검토하셔야 합니다. 별도 채널로 정리해서 보내드리겠습니다. 입증 서류는 평균 12~16종으로 늘어나니 사내 문서관리 시스템에 분류체계를 미리 잡아두는 편이 효율적입니다.$C$,
        r_id, '2025-12-23 10:32:00'::timestamp, '2025-12-23 10:32:00'::timestamp);

    -- 댓글 2: seungwoo.han (한-EU FTA EXPERT)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='seungwoo.han@globalgates.test'),
        'active'::post_status,
        $C$한-EU FTA 와 비교하면 EU 측은 원산지신고서(Origin Declaration) 방식이라 EUR.1 발급 행정부담이 없는 점이 강점입니다. RCEP/한-아세안 FTA 의 자체발급 인증수출자 신청도 비슷한 절차이니, 인증수출자 미신청 회원사가 있다면 우선 권장드립니다. 평균 신청 처리기간 30일, 관세청 'FTA 인증수출자 신청 매뉴얼 v3.1' 참고하시면 됩니다.$C$,
        post_id, '2025-12-22 18:30:00'::timestamp, '2025-12-22 18:30:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$한-EU FTA 의 6,000 EUR 미만 셀프 선언 한도와는 또 다른 부분이군요. 저희는 인증수출자 신청을 작년에 마쳤지만 사내 매뉴얼이 외부 공유 가능한 수준은 아니라, 신청 단계 자문이 필요한 회원사가 있다면 윤채린 위원님 라인으로 안내드리는 편이 적합할 것 같습니다. 항상 좋은 인사이트 감사합니다.$C$,
        c_id, '2025-12-23 11:11:00'::timestamp, '2025-12-23 11:11:00'::timestamp);


    -- =========================================================
    -- POST 4 — 2026-01-09 11:20  무역 IT·디지털 혁신
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$HBM3E 12-Hi 스택 PoC 샘플 — 수출통제 사전 라이선스 + EUC 운영 경험 공유$T$,
        $B$산업통상자원부 통상정책국과 KEA 한국전자정보통신산업진흥회의 'AI 반도체 수출통제 운영 가이드 2026' 을 참고하여 HBM3E 12-Hi 스택 PoC 샘플 공급 단계의 통제 절차를 정리합니다. 첨단 반도체는 전략물자 4류로 분류되어 사전 라이선스 신청이 필요하며, EAR(미 수출관리규정) 적용 시 ECCN 3A090 / 4A090 분류 여부를 함께 검토해야 합니다.

1) 사전 라이선스 — 산업부 전략물자관리원 KOSTI 에 신청. 평균 처리 35영업일, 반도체 우선처리 절차 적용 시 21영업일.
2) 최종사용자 확약서(EUC) — 최종 사용자/사용처 명시, AI 가속기 어셈블리 검증 용도임을 명확화, 군용 전환 금지 조항 포함.
3) 캐치올(Catch-All) 검토 — ECCN 미분류 품목이라도 군사용 전용가능성 인식 시 통제 대상. BIS 우려거래자 리스트(Entity List/Unverified List/SDN) 사전 확인 필수.
4) 미국 BIS 의 PRC 수출통제 강화 조치(2024.10) 이후 PoC 단위 샘플도 라이선스 사전 검토가 사실상 필수가 됐습니다.

PoC 샘플 1개당 약 USD 1,800 단가지만 통제 절차상 행정 코스트가 더 크다는 점이 현장 체감입니다. KOSTI 신청 시 ECCN 분류 결과와 EAR 적용 여부 검토 의견서를 미리 첨부하면 처리기간이 단축됩니다.$B$,
        '경기 기흥', 13, '2026-01-09 11:20:00'::timestamp, '2026-01-09 11:20:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: jaeho.kim (반도체 PRO+, HBM 본인 상품)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jaeho.kim@globalgates.test'),
        'active'::post_status,
        $C$HBM3E 샘플 공급은 PoC 단위라도 BIS Entity List 매핑 점검이 결정적입니다. 저희는 분기마다 OFAC SDN 리스트 + Entity List + Unverified List 3종 자체 점검을 사내 컴플라이언스 절차로 운영하고 있습니다. KOSTI YESTRADE 와 BIS SNAP-R 두 시스템에 동시 신청 운영하시는 편이 평균 처리기간을 줄이는 데 효과적이었습니다.$C$,
        post_id, '2026-01-09 14:08:00'::timestamp, '2026-01-09 14:08:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$Entity List + Unverified List 동시 점검은 저희도 작년 4분기부터 도입했는데, Unverified List 등재 후 90일 이내 해제 사례가 의외로 많아 거래 타이밍 변동성이 큽니다. 분기 점검 외에 신규 거래선 등재 시점을 실시간 모니터링할 수 있는 체계가 있으신지요?$C$,
        c_id, '2026-01-09 16:32:00'::timestamp, '2026-01-09 16:32:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: jaeho.kim
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jaeho.kim@globalgates.test'),
        'active'::post_status,
        $C$BIS Federal Register 의 RSS 피드를 KEA Compliance Hub 의 자체 알림 시스템에 연동하고 있습니다. 평균 등재 6시간 이내 알림이 도달합니다. 회원사 대상 도구라 관심 있으시면 KEA 회원사 페이지의 'Trade Compliance Tools' 메뉴 참고 부탁드립니다. 사내 컴플라이언스 담당자 계정 발급도 무상입니다.$C$,
        r_id, '2026-01-10 09:11:00'::timestamp, '2026-01-10 09:11:00'::timestamp);

    -- 댓글 2: jian.song (베트남 WFOE EXPERT)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jian.song@globalgates.test'),
        'active'::post_status,
        $C$베트남 호치민 SHTP(Saigon Hi-Tech Park) 에 어셈블리 공장을 둔 글로벌 OEM 사들도 동일한 EUC 요구를 받습니다. 다만 베트남 산업통상부(MOIT) 의 사전등록 요구가 추가되어 KOSTI + MOIT 이중 절차로 평균 14일이 더 소요됩니다. PoC 단위라도 베트남 경유 시 일정 여유 두실 것을 권장드립니다.$C$,
        post_id, '2026-01-10 13:42:00'::timestamp, '2026-01-10 13:42:00'::timestamp);

    -- 댓글 3: taeyoung.jung (자동차부품 PRO)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='taeyoung.jung@globalgates.test'),
        'active'::post_status,
        $C$자동차 분야는 ADAS 용 GPU 가속기 단위에서 동일한 검토가 점점 일반화되고 있습니다. ECCN 3A090 미분류 부품도 캐치올 적용 사례가 늘고 있어, 산업부 KOSTI 의 사전판정(Self-Assessment) 의견서 발급을 강력히 권장드립니다. 평균 발급 14일, 무료 서비스입니다. 양산 라인 직전 단계에서 분류 오류 발견 시 손실이 크기 때문입니다.$C$,
        post_id, '2026-01-11 21:05:00'::timestamp, '2026-01-11 21:05:00'::timestamp);


    -- =========================================================
    -- POST 5 — 2026-01-28 16:42  K-Food 수출 클럽
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$발효 고추장 미국 진출 — FDA 시설등록·FSVP·라벨링 1년 운영 후기와 RASFF 사전 점검$T$,
        $B$식품의약품안전처 식품안전정책과의 'K-Food 미국 수출 가이드 2025' 와 농림축산식품부 농수산물수출지원과의 가이드라인을 적용하여 발효 고추장 미국 진출을 1년간 운영한 후기를 공유합니다.

1) FDA 시설등록(FFR) — 등록비 무료, 2년마다 갱신. PIN + DUNS 번호 + U.S. Agent 지정 필수. 매 선적 건마다 사전 통보(Prior Notice) 제출.
2) FSVP(외국공급자 검증프로그램) — 수입자 측 책임이지만 공급자가 PCQI(Preventive Controls Qualified Individual) 자격자의 HACCP 자료를 충실히 제공해야 평가 통과. 저희는 PCQI 자격자 1명 사내 양성에 6개월 투자했습니다.
3) 라벨링 — 영양성분표(Nutrition Facts) 2016 개정판 적용. 알레르겐 9개(Big 9) 굵은 글씨 표기. FDA 권장 단순화 표현(예: 'Fermented Soybean Paste' 가 'Gochujang' 보다 안전).
4) RASFF 사전 점검 — EU RASFF + FDA Import Refusal Database 분기 점검. 한국산 발효식품의 잔류 곰팡이독소(아플라톡신 B1) 이슈가 가장 빈번합니다.

미주 통관 평균 5~7일, 라벨링 미흡 사유 보류 발생 시 평균 18일 지연. 첫 1년은 라벨링 검수에 가장 많은 비용이 들어갔다는 점이 솔직한 후기입니다.$B$,
        '부산 해운대', 18, '2026-01-28 16:42:00'::timestamp, '2026-01-28 16:42:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: jiwon.park (식품 PRO, 김치/고추장 본인 상품)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jiwon.park@globalgates.test'),
        'active'::post_status,
        $C$FSVP 의 PCQI 사내 양성 6개월은 식품 수출사 입장에서 매우 효율적인 선택이셨습니다. 저희도 동일 절차로 작년 진행했고, FSPCA(Food Safety Preventive Controls Alliance) 인증 Lead Instructor 과정을 거친 사내 인력이 있어야 외부 컨설팅 의존도를 낮출 수 있다는 점에 공감합니다. FSPCA 트레이너 디렉토리에서 국내 인증자 검색이 가능하니 후속 양성 계획에 참고 부탁드립니다.$C$,
        post_id, '2026-01-28 19:05:00'::timestamp, '2026-01-28 19:05:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$FSPCA 트레이너 디렉토리는 처음 들었습니다. 국내 PCQI 양성 과정 수료자를 검색할 수 있다면 사내 후속 양성 계획에 큰 도움이 됩니다. 추가로, FSVP 의 갱신 시점 판단 기준이 모호한 것 같은데, 공장 이전·공정 추가 외에 어떤 트리거를 사내 변경관리 절차에 명시하시는지 궁금합니다.$C$,
        c_id, '2026-01-29 09:32:00'::timestamp, '2026-01-29 09:32:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: jiwon.park
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jiwon.park@globalgates.test'),
        'active'::post_status,
        $C$FSVP 자체는 별도 갱신주기가 없고, 공급자 측 식품안전 시스템 변경 시점에 재평가가 필요합니다. 저희는 사내 변경관리(Change Control)에 다음 6가지 트리거를 명시했습니다 — 공장 이전, 공정 추가, 핵심 원재료 공급선 변경, HACCP 위해요소 추가/삭제, 부적합 발생, 정기 갱신(2년 주기 자체). FDA 의 'Hazard Analysis and Risk-Based Preventive Controls for Human Food' 가이드(21 CFR 117) 기준 분기 점검도 병행 권장드립니다.$C$,
        r_id, '2026-01-29 14:48:00'::timestamp, '2026-01-29 14:48:00'::timestamp);

    -- 댓글 2: sumin.lee (K-뷰티 PRO+)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='sumin.lee@globalgates.test'),
        'active'::post_status,
        $C$동남아 화장품에서도 라벨링 이슈가 빈번합니다. 인도네시아 BPOM 은 한국어 표기를 인정하지 않고 영문 + 인도네시아어 이중표기를 요구하여 라벨 디자인을 별도 제작하고 있습니다. K-Food 미주 라벨링과 K-뷰티 동남아 라벨링 모두 디자인 비용의 4배 이상이 검수비로 발생합니다. 1년차에 가장 많이 깎이는 부분이라는 점에 깊이 공감합니다.$C$,
        post_id, '2026-01-29 11:02:00'::timestamp, '2026-01-29 11:02:00'::timestamp);

    -- 댓글 3: chaerin.yoon (관세사)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='chaerin.yoon@globalgates.test'),
        'active'::post_status,
        $C$발효 고추장은 HS 2103.90 으로 분류되지만, 발효 정도와 첨가물 비중에 따라 2103.20(토마토케첩·기타 토마토 소스)와의 분쟁 사례가 종종 있습니다. 첫 진출 시 관세청 사전심사(Advance Ruling) 발급을 강하게 권장드립니다. 통관 후 추징 발생 시 부담이 크고, 평균 발급 4~6주에 신청비는 무료입니다.$C$,
        post_id, '2026-01-30 16:18:00'::timestamp, '2026-01-30 16:18:00'::timestamp);


    -- =========================================================
    -- POST 6 — 2026-02-14 08:17  K-Beauty 글로벌
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$사우디 SFDA 화장품 등록 9개월 진행 — e-Cosma 등록비·서류·할랄 인증 병행 비용 정리$T$,
        $B$한국보건산업진흥원과 KOTRA 리야드 무역관 자료를 기반으로 사우디 SFDA(식약청) 화장품 등록 9개월 운영 후기를 공유합니다.

1) SFDA e-Cosma 시스템 등록 — 제품당 등록비 SAR 1,400, 평균 처리 90~120일. CPNP(Cosmetic Product Notification Portal) 형식과 유사하나 성분 명세는 INCI + 아랍어 병기가 필수입니다.
2) GHAD(Gulf Harmonized Administrative Document) 옵션 — GCC 6개국 광역 등록 가능. 등록비는 단일국 대비 2.4배지만 6개국 통합관리. 단, 회수 발생 시 6개국 동시 회수 리스크 존재.
3) 할랄 인증 병행 — JAKIM(말레이시아) / Emirates Authority for Standardization 양쪽 인증을 동시에 받으면 GCC + ASEAN 광역 진출이 효율적입니다.
4) 임상자료 — 자외선차단제 / 미백 / 주름개선 기능성 표시 시 SFDA 별도 임상자료 요구. 평균 추가 60일 소요, 비용 USD 18,000 내외.

KOTRA 리야드 무역관의 'K-뷰티 GCC 시장 진출 가이드 2025' 와 한국보건산업진흥원의 '글로벌 화장품 인증제도 비교 자료집' 을 함께 검토하시면 비용 추정이 정확해집니다.$B$,
        '서울 강남', 12, '2026-02-14 08:17:00'::timestamp, '2026-02-14 08:17:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: sumin.lee (K-뷰티 PRO+, HALAL 본인 상품)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='sumin.lee@globalgates.test'),
        'active'::post_status,
        $C$SFDA 와 BPOM 모두 e-Cosma + e-CertLab 이중 등록이 필요한 케이스가 늘고 있습니다. 특히 자외선차단제·미백 같은 기능성 표시 제품은 SFDA 가 BPOM 보다 임상자료 요구가 엄격합니다. GHAD 광역 등록은 매력적이지만 한 가지 리스크가 큰데, 회수 발생 시 GCC 6개국 동시 회수가 사실상 자동 트리거됩니다. 신제품 첫 진출은 단일국으로 시작하는 편이 안전하다는 게 저희 경험입니다.$C$,
        post_id, '2026-02-14 11:30:00'::timestamp, '2026-02-14 11:30:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$GHAD 회수 리스크는 저희도 협상 단계에서 가장 길게 검토했던 부분입니다. 사우디 단일 등록 → 1년 운영 후 GHAD 전환 옵션을 사용하는 것이 안전해 보이는데, 실제 단계별 진출 전략이 SFDA 가이드라인에 명시되어 있는지요?$C$,
        c_id, '2026-02-14 15:05:00'::timestamp, '2026-02-14 15:05:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: sumin.lee
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='sumin.lee@globalgates.test'),
        'active'::post_status,
        $C$SFDA Cosmetics Guidelines v6.2 의 Section 14 에 단계별 시장확대 가이드(Single Country → Regional) 가 명시되어 있습니다. 다만 권장 사항이지 의무는 아니라서 결국 화장품사의 리스크 선호도에 달려 있습니다. 1년 운영 데이터로 사후관리 안정성을 입증한 뒤 GHAD 전환하는 패턴이 시장 표준에 가깝습니다.$C$,
        r_id, '2026-02-15 09:18:00'::timestamp, '2026-02-15 09:18:00'::timestamp);

    -- 댓글 2: chaerin.yoon (관세사)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='chaerin.yoon@globalgates.test'),
        'active'::post_status,
        $C$HS 3304 화장품 류는 SFDA 등록번호가 통관서류상 필수 기재항목이라, e-Cosma 등록번호 변경 발생 시 통관서류 재발급이 일괄 필요합니다. 평균 재발급 비용 USD 320/SKU, 평균 처리 3~5영업일. 등록번호 변경 빈도를 줄이도록 초기 등록 시 제품명/원료 구성 변동성을 최소화하는 설계가 비용 절감의 핵심입니다.$C$,
        post_id, '2026-02-15 13:22:00'::timestamp, '2026-02-15 13:22:00'::timestamp);

    -- 댓글 3: haneul.cho (Alibaba PRO+)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='haneul.cho@globalgates.test'),
        'active'::post_status,
        $C$Alibaba.com 의 GCC 바이어 비중이 최근 1년 사이 18% 증가했습니다. SFDA 등록증을 Trade Assurance 페이지의 'Certifications' 섹션에 등록해두시면 RFQ 응답률이 평균 32% 상승하는 것으로 통계가 잡힙니다. 인증 비용 회수 측면에서 디지털 채널 활용도 함께 검토해보시면 도움이 됩니다.$C$,
        post_id, '2026-02-16 10:45:00'::timestamp, '2026-02-16 10:45:00'::timestamp);


    -- =========================================================
    -- POST 7 — 2026-03-02 19:55  FTA·관세 실무 스터디
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$EU CBAM 시범기간 분기 보고서 제출 후기 — 내재배출량 산정과 검증기관 선정$T$,
        $B$유럽연합 집행위원회 DG TAXUD 의 CBAM 시범기간(Transitional Period) 가이드와 한국환경공단의 'CBAM 내재배출량 산정 매뉴얼 v2' 를 적용한 2026년 1분기 보고서 제출 후기입니다.

1) 직접배출(Scope 1) 산정 — 사내 연료/공정 배출. ISO 14064-1 의 정량화 방법론과 일치하나, CBAM 은 Default Value 적용 한도가 시범기간 종료 후 사라지므로 사업장별 실측 데이터 구축이 필요합니다.
2) 간접배출(Scope 2) — 전력사용량 기반. 한국전력 KEPCO 의 배출계수(0.4747 tCO2e/MWh, 2025년 기준) 적용.
3) 검증기관(Accredited Verifier) — EU NAB(National Accreditation Body) 인증 기관만 인정. 국내에는 한국인정기구 KAB 의 IAF MLA 인정기관 7곳이 있습니다. 평균 검증비 EUR 9,800 ~ 14,500.
4) 보고서 제출 — CBAM Registry 시스템. 분기별 마감 후 1개월 이내 제출, 미제출 시 톤당 EUR 50 패널티.

2026년 1월부터 본격적 의무화 단계에 진입한 만큼 사내 ESG 팀과의 협업 체계가 핵심이라는 점이 가장 큰 학습이었습니다.$B$,
        '인천 연수', 14, '2026-03-02 19:55:00'::timestamp, '2026-03-02 19:55:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: taeyoung.jung (자동차부품 PRO, EV 본인 상품)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='taeyoung.jung@globalgates.test'),
        'active'::post_status,
        $C$EV 배터리팩 하우징 부품에서 IATF 16949 와 ISO 14064-1 를 통합 운영하고 있습니다. CBAM 보고서는 ISO 14064-1 의 검증 의견과 표준이 다른 항목이 있어 검증기관에 별도 비용을 추가로 지불해야 했습니다. 두 표준을 모두 인정하는 인증기관을 선정하시면 검증 비용을 평균 28% 절감하실 수 있습니다.$C$,
        post_id, '2026-03-02 22:30:00'::timestamp, '2026-03-02 22:30:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$검증기관 이중지정 비용은 저희도 1분기 가장 큰 부담이었습니다. ISO 14064-1 와 CBAM 두 표준을 동시에 인정하는 KAB 인정 기관 명단을 어디서 확인할 수 있는지요? 한국인정기구 홈페이지의 인정범위 검색에서 검색 키워드를 잡기가 어려웠습니다.$C$,
        c_id, '2026-03-03 11:14:00'::timestamp, '2026-03-03 11:14:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: taeyoung.jung
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='taeyoung.jung@globalgates.test'),
        'active'::post_status,
        $C$KAB 홈페이지 검색 키워드는 'CBAM' 보다 'GHG 검증' 으로 검색하시는 편이 효과적입니다. 별도로 IAS / IAF MLA 다국적 인정기관(예: ANAB, UKAS)도 EU 측 NAB 와 상호인정 관계에 있어 EU 검증 인정에 활용 가능합니다. 다국적 검증기관 활용 시 본사·해외법인 보고서를 통합 검증할 수 있어 그룹 차원 비용 효율이 추가로 발생합니다.$C$,
        r_id, '2026-03-03 14:48:00'::timestamp, '2026-03-03 14:48:00'::timestamp);

    -- 댓글 2: seungwoo.han (한-EU FTA EXPERT)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='seungwoo.han@globalgates.test'),
        'active'::post_status,
        $C$CBAM 은 한-EU FTA 의 원산지결정기준(PSR) 과 별개 메커니즘이지만, 실무상 두 절차가 결합되는 케이스가 늘고 있습니다. EU 측이 'leakage prevention' 으로 보호받는 품목 리스트가 분기마다 갱신되니, 산업통상자원부 통상정책국의 'EU 통상 동향 브리프' 정기 구독 권장드립니다. 평균 한 호당 12~16페이지로 분량이 적당합니다.$C$,
        post_id, '2026-03-04 09:33:00'::timestamp, '2026-03-04 09:33:00'::timestamp);

    -- 댓글 3: yujin.noh (화학원료 FREE, LDPE 수입)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='yujin.noh@globalgates.test'),
        'active'::post_status,
        $C$수입 원료 측 내재배출량 산정 시 사우디 SABIC 의 ESG 보고서가 큰 도움이 됩니다. SABIC 은 ISO 14064 인증 데이터를 제품별로 공개하고 있어 CBAM 직접배출 보고에 인용 가능합니다. PVC 컴파운드 K67 등 다운스트림 제품도 원료 측 데이터를 활용하면 추가 측정 비용을 절감할 수 있습니다.$C$,
        post_id, '2026-03-04 17:20:00'::timestamp, '2026-03-04 17:20:00'::timestamp);


    -- =========================================================
    -- POST 8 — 2026-03-18 13:05  무역금융 인사이트
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$환변동보험 vs 통화옵션 콜라(Collar) — 6개월 운영 비교 + 손익 데이터 공개$T$,
        $B$한국무역보험공사 K-SURE 의 환변동보험 v3 상품과 한국산업은행 IBK 의 통화옵션 콜라(Collar) 구조 6개월 운영 비교 데이터를 공유합니다.

1) K-SURE 환변동보험 v3
   - 보험료율 0.45% (중소중견 Plus+ 특약 50% 할인 시 0.225%)
   - 보장한도 USD 1,500,000 (단일 계약 기준)
   - 결제일 기준 환율 변동분 보상
   - 부분보장 옵션 70% / 50% 적용 시 보험료 추가 절감

2) 산업은행 통화옵션 콜라
   - 옵션 프리미엄 net -0.08% ~ +0.12% 변동
   - 상하단 행사가 별도 설정
   - 청산 절차는 매월 자동 정산

6개월 운영 결과 — 환율 변동성이 큰 구간에서는 환변동보험이 보장 폭이 명확해 결산 예측가능성이 높았고, 변동성이 작은 구간에서는 콜라가 비용 효율적이었습니다. 둘을 50:50 혼합 운영하는 것이 결과적으로 가장 안정적이었습니다.$B$,
        '서울 여의도', 16, '2026-03-18 13:05:00'::timestamp, '2026-03-18 13:05:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: yerin.shin (K-SURE 출신 자문 FREE, 본인 상품)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='yerin.shin@globalgates.test'),
        'active'::post_status,
        $C$K-SURE 환변동보험 v3 의 중소중견 Plus+ 특약 50% 할인은 가입 후 정기 보장 한도 평가에서 매출액 기준이 충족되는지 확인이 필요합니다. 평균 매출 800억 원 이하 기업이 안정적으로 적용받습니다. 부분보장 옵션은 절감 폭이 크지만 한도 기간이 6개월 → 4개월로 단축되는 점을 고려하셔야 합니다. K-SURE 의 'Plus+ 특약 적용 매뉴얼 2026.1' 참고 부탁드립니다.$C$,
        post_id, '2026-03-18 16:42:00'::timestamp, '2026-03-18 16:42:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$부분보장 70% 옵션 적용 시 보험료 절감 폭이 평균 0.18%p 라는 점은 6개월 데이터로 검증했습니다. 한도 기간 단축은 결산 주기 단축과 맞물려 사내 결재 절차에 부담이 있어 회피하고 있었는데, 분기 단위로 재가입을 자동화하는 사례가 있는지 궁금합니다.$C$,
        c_id, '2026-03-19 10:18:00'::timestamp, '2026-03-19 10:18:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: yerin.shin
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='yerin.shin@globalgates.test'),
        'active'::post_status,
        $C$분기 단위 재가입 자동화는 K-SURE 의 'Auto-Renewal Plus' 옵션으로 신청 가능합니다. 갱신 시점 60일 전 보장한도 자동 재평가 후 계약 갱신, 매출 변동 폭 ±15% 범위 내라면 별도 서류 제출 없이 처리됩니다. 옵션 활성화 비용은 무료, 첫 가입 시 신청서에 체크박스 추가만 하시면 됩니다.$C$,
        r_id, '2026-03-19 14:35:00'::timestamp, '2026-03-19 14:35:00'::timestamp);

    -- 댓글 2: jaeho.kim (반도체 PRO+)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jaeho.kim@globalgates.test'),
        'active'::post_status,
        $C$반도체 거래는 USD 결제 비중이 90% 이상이라 헤지 비율을 80% 수준으로 운영하고 있습니다. 저희는 K-SURE 환변동보험 60% + 산업은행 콜라 20% 혼합 운영하여, 환율 급변 구간에서 보험 보장 영역과 콜라 손익이 서로 보완되도록 설계했습니다. 분기 환손익이 평균 -0.4%p 에서 +0.1%p 로 안정화됐습니다.$C$,
        post_id, '2026-03-20 09:48:00'::timestamp, '2026-03-20 09:48:00'::timestamp);

    -- 댓글 3: haneul.cho (Alibaba PRO+)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='haneul.cho@globalgates.test'),
        'active'::post_status,
        $C$Alibaba Trade Assurance 결제는 USD 비중이 60% 정도로 화주 결제 통화 다변화가 진행되어 있습니다. 통화별 노출이 다양해질수록 환변동보험보다 다통화 콜라가 효율적이라는 게 저희 결론이었습니다. 단, 다통화 콜라는 행사가 설계가 까다로워 산업은행 외환 데스크의 초기 자문이 결정적이었습니다.$C$,
        post_id, '2026-03-21 11:22:00'::timestamp, '2026-03-21 11:22:00'::timestamp);


    -- =========================================================
    -- POST 9 — 2026-04-04 23:42  글로벌 수출 포럼
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$KOTRA KOMPAS 동남아 바이어 신규 발굴 3개월 KPI — 인콰이어리 → 본계약 깔때기 분석$T$,
        $B$KOTRA 의 KOMPAS(코트라 해외시장조사 플랫폼) + 한국무역협회 KITA 무역지원센터 자료를 활용한 동남아 바이어 신규 발굴 3개월 운영 결과입니다.

[발굴 깔때기]
- 발굴 인콰이어리 312건
- 1차 미팅 88건 (전환율 28.2%)
- 샘플 송부 31건 (전환율 35.2%)
- 본계약 4건 (전환율 4.5%)

[국가별 분포]
- 베트남 32%, 인도네시아 24%, 말레이시아 18%, 태국 14%, 싱가포르 12%

[학습 포인트]
- KOMPAS 의 'Verified Buyer' 라벨이 붙은 바이어의 본계약 전환율이 평균 11.2% (전체 4.5% 대비 2.5배)
- 1차 미팅 후 평균 18일 이내 샘플 송부가 본계약 전환율을 4.5% → 9.8% 로 끌어올림
- 동남아 바이어는 평균 4.2회 미팅 후 본계약 (북미 평균 2.8회 대비 1.5배)

KOMPAS 데이터의 한계는 신생 바이어 정보 갱신 속도가 느린 점입니다. MOIT(베트남) / DEPDAGRI(인도네시아) 등 현지 정부 채널을 보조 데이터로 병행 검토하시면 발굴 정확도가 올라갑니다.$B$,
        '서울 종로', 19, '2026-04-04 23:42:00'::timestamp, '2026-04-04 23:42:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: nayoung.kang (Amazon 컨설팅 PRO+)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='nayoung.kang@globalgates.test'),
        'active'::post_status,
        $C$Amazon Business 의 B2B 채널에서는 인콰이어리 → 본계약 전환율이 평균 1.2% 수준으로 훨씬 낮습니다. 다만 평균 계약 단가가 KOMPAS 발굴 케이스 대비 2.8배 높아서 수익성 기준으로는 비교 우위가 있는 채널입니다. KPI 설계 시 단순 전환율보다 채널별 단가 가중 전환율을 함께 보시는 것이 의사결정에 효과적입니다.$C$,
        post_id, '2026-04-05 09:14:00'::timestamp, '2026-04-05 09:14:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$단가 가중 전환율은 좋은 시각입니다. 저희도 채널 ROI 계산 시 단가만 보면 동남아 KOMPAS 가 가장 떨어졌지만, 평균 계약 기간(연 단위) 과 재주문율을 반영한 LTV 기준으로는 Amazon B2B 와 큰 격차가 없었습니다. Amazon B2B 의 평균 계약 기간은 통계상 어느 정도이신지요?$C$,
        c_id, '2026-04-05 13:32:00'::timestamp, '2026-04-05 13:32:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: nayoung.kang
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='nayoung.kang@globalgates.test'),
        'active'::post_status,
        $C$Amazon Business 평균 계약 기간은 14~16개월, 재주문율은 56% 수준입니다. KOMPAS 발굴 케이스 대비 LTV 가중 비교 시 단가 효과가 1.4배 정도로 축소됩니다. 채널 다변화 관점에서는 KOMPAS 의 안정성과 Amazon B2B 의 단가가 서로 보완재라는 게 저희 결론입니다.$C$,
        r_id, '2026-04-05 18:08:00'::timestamp, '2026-04-05 18:08:00'::timestamp);

    -- 댓글 2: haneul.cho (Alibaba PRO+)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='haneul.cho@globalgates.test'),
        'active'::post_status,
        $C$Alibaba.com RFQ 채널의 평균 응답률은 24시간 이내 응답 시 47% 입니다. 본계약 전환율은 6.8% 수준으로 KOMPAS 의 4.5% 보다 1.5배 높지만, KOMPAS 의 Verified Buyer 전환율 11.2% 와는 큰 격차가 있습니다. 채널의 검증 라벨 효과가 KOMPAS 가 가장 강한 편입니다.$C$,
        post_id, '2026-04-06 11:05:00'::timestamp, '2026-04-06 11:05:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$Alibaba 의 24시간 응답률 47% 는 저희 사내 KPI 보다 높은 수준이네요. Trade Assurance 비중 70% 이상 화주의 발굴 ROI 가 평균 2.4배라는 통계가 있다고 들었는데, 가입 → 운영 안정화까지 얼마나 걸리는 것이 일반적인지요?$C$,
        c_id, '2026-04-06 14:48:00'::timestamp, '2026-04-06 14:48:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: haneul.cho
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='haneul.cho@globalgates.test'),
        'active'::post_status,
        $C$Trade Assurance 비중 70% 도달까지 평균 6개월입니다. 핵심은 첫 3개월에 RFQ 응답률 24시간 이내를 90% 이상 유지하는 것이고, 이후 자연스럽게 Gold Supplier Verified 라벨이 부여되면서 비중이 빠르게 올라갑니다. Alibaba 의 'Supplier Performance Index' 80점 이상이 ROI 2.4배의 분기점입니다.$C$,
        r_id, '2026-04-06 19:25:00'::timestamp, '2026-04-06 19:25:00'::timestamp);

    -- 댓글 3: jian.song (베트남 WFOE EXPERT)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jian.song@globalgates.test'),
        'active'::post_status,
        $C$베트남 호치민 거점화 케이스에서 KOMPAS 데이터의 한계가 특히 두드러집니다. MOIT 의 외국인투자국(FIA) 산하 'Business Information Portal' 을 보조 데이터로 활용하시면 신생 바이어 발굴이 한결 정확해집니다. 회원 가입 무료, 데이터 갱신 주기 7일입니다.$C$,
        post_id, '2026-04-07 09:30:00'::timestamp, '2026-04-07 09:30:00'::timestamp);


    -- =========================================================
    -- POST 10 — 2026-04-19 10:11  해운물류 전문가 모임
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$LCL/FCL 손익분기점 재계산 — 25CBM 케이스의 LCL 우위 구간 분석$T$,
        $B$한국통합물류협회 KIFFA 의 'LCL/FCL 손익분기점 가이드 2026.1' 와 자체 운영 데이터를 적용해 25CBM 화물의 LCL vs FCL 선택 손익분기점을 재계산해보았습니다.

[부산-호치민 라인 기준 25CBM 케이스]
- LCL 총비용 USD 1,420 (CFS 작업료 + Bunker + 통관 포함)
- FCL 총비용 USD 1,800 (20피트 컨테이너 기준 + 사이드워크)
- LCL 우위 USD 380 — 단, 도착지 작업 변동성 있음

[LCL 우위가 사라지는 케이스]
- Reefer/위험화물(IMDG) 포함 시: LCL CFS 가 Reefer 미지원 → FCL 강제
- 분할 출하 빈도 잦음 시: LCL 의 분할 추가비용이 USD 80/회 누적
- 도착지 작업 단가 차이 큰 항만(예: 도쿄항): LCL 도착지 작업료가 부산 출발 대비 1.7배

분기마다 항만/항로별 LCL CFS 작업료가 변동되므로 손익분기점도 분기 단위로 재계산하시는 것이 안전합니다. 'KIFFA 분기 운임 동향 리포트' 의 LCL 섹션 활용 권장드립니다.$B$,
        '부산 강서', 17, '2026-04-19 10:11:00'::timestamp, '2026-04-19 10:11:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: taewoo.kwon (포워더 14년)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='taewoo.kwon@globalgates.test'),
        'active'::post_status,
        $C$LCL CFS 작업료는 부산항과 광양항 사이에 적지 않은 격차가 있습니다. 광양항만공사 GPA 의 LCL 인센티브 프로그램이 분기당 USD 4/CBM 절감 효과가 있어, 25CBM 기준 USD 100 추가 절감이 가능합니다. 다만 광양항 LCL 라인은 호치민/방콕 등 동남아 라인 위주이고 유럽 라인은 부산항 대비 처리능력이 60% 수준이라 선택 시 검토가 필요합니다.$C$,
        post_id, '2026-04-19 13:42:00'::timestamp, '2026-04-19 13:42:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$광양항 LCL 인센티브는 처음 들었습니다. 분기당 USD 4/CBM 절감은 25CBM 케이스에서 적지 않은 효과네요. 동남아 라인은 처리능력 충분한 것 같으니 호치민/방콕 출하분은 광양항 경로를 시뮬레이션해보겠습니다. 인센티브 신청 절차는 어디서 확인하면 좋을지요?$C$,
        c_id, '2026-04-19 17:08:00'::timestamp, '2026-04-19 17:08:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: taewoo.kwon
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='taewoo.kwon@globalgates.test'),
        'active'::post_status,
        $C$광양항만공사 GPA 홈페이지의 '항만 인센티브 신청' 메뉴에서 분기별 신청 가능합니다. 신청서 양식이 간단(2페이지)하고 별도 신청비 없습니다. 평균 승인 7영업일, 분기 종료 후 익월 정산입니다. 다만 인센티브 적용을 위해서는 광양항 출발 LCL 콘솔링 등록 포워더와 사전 계약이 필요합니다.$C$,
        r_id, '2026-04-20 09:30:00'::timestamp, '2026-04-20 09:30:00'::timestamp);

    -- 댓글 2: dohyun.lim (해운 EXPERT)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='dohyun.lim@globalgates.test'),
        'active'::post_status,
        $C$25CBM 의 트랜짓 평균 일수는 부산-호치민 LCL 12일, FCL 9일로 LCL 이 3일 더 깁니다. 도착지 작업까지 포함하면 LCL 우위 USD 380 이 LCL 의 추가 보관/관리 비용으로 일부 상쇄될 수 있어, 도착지 작업료 변동성이 큰 항만은 시뮬레이션을 더 정밀하게 하실 필요가 있습니다. 호치민/방콕은 작업 안정성이 양호한 편입니다.$C$,
        post_id, '2026-04-20 14:18:00'::timestamp, '2026-04-20 14:18:00'::timestamp);

    -- 댓글 3: hyunwoo.bae (전자/IoT PRO)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='hyunwoo.bae@globalgates.test'),
        'active'::post_status,
        $C$IoT 게이트웨이는 화물 특성상 항공/해상 혼합 운송 사례가 잦습니다. Master AWB + House AWB 의 항공 구간을 LCL 의 해상 구간과 결합한 멀티모달 운송에서, LCL 우위 USD 380 같은 손익 비교가 의외로 복잡해집니다. KIFFA 의 '복합운송 비용 비교 가이드' 의 멀티모달 섹션 참고하시면 도움됩니다.$C$,
        post_id, '2026-04-21 11:55:00'::timestamp, '2026-04-21 11:55:00'::timestamp);


    -- =========================================================
    -- POST 11 — 2026-05-06 15:24  무역 IT·디지털 혁신
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$외화 자금세탁 모니터링 시스템(AML/CFT) 도입 — KFIU 보고대상 거래 자동 식별$T$,
        $B$한국금융정보분석원 KFIU 의 의심거래보고(STR) 및 고액현금거래보고(CTR) 기준에 맞춘 외화 모니터링 시스템 도입 후기를 공유합니다.

[핵심 기능]
1) SWIFT 메시지(MT103/MT202) 자동 파싱 — 송수신 통화/금액/거래상대방 자동 추출
2) OFAC SDN + EU CFSP + UN 안보리 제재 리스트 실시간 검색
3) 거래 패턴 이상치 알림 — 평균 거래 패턴 대비 ±200% 이탈 시 자동 알림
4) STR/CTR 보고서 자동 작성 — KFIU FIU-NET 시스템 양식 자동 생성

[운영 데이터]
- 도입 비용 약 KRW 8천만 원 (라이선스 + 초기 셋업)
- 월 운영비 KRW 320만 원
- 월평균 알림 18~24건, 그중 실제 STR 보고 평균 0.4건

KFIU 의 'AML/CFT 자체점검 매뉴얼 2025 개정판' 부록 B 의 자율점검 체크리스트와 함께 운영하시면 보고 누락 리스크가 크게 낮아집니다. 평균 도입 4개월, 사내 컴플라이언스 담당자 2명 풀타임 배정이 권장 사양입니다.$B$,
        '서울 영등포', 13, '2026-05-06 15:24:00'::timestamp, '2026-05-06 15:24:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: jaemin.oh (L/C 자문 EXPERT)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jaemin.oh@globalgates.test'),
        'active'::post_status,
        $C$KFIU 보고 누락 시 특정금융정보법 제17조에 따라 1억 원 이하의 과태료가 부과될 수 있습니다. 실제로 보고 누락보다 보고 지연(영업일 30일 초과)으로 과태료 부과된 사례가 더 많아, 모니터링 시스템에 보고 마감 D-7 알림 기능을 별도 셋업하시는 편이 안전합니다. KFIU 자율점검 매뉴얼의 분기 점검 항목을 사내 정기 회의에 포함시키시는 것을 권장드립니다.$C$,
        post_id, '2026-05-06 18:42:00'::timestamp, '2026-05-06 18:42:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$보고 마감 D-7 알림은 좋은 아이디어입니다. 저희 시스템에 추가하겠습니다. 자체점검 체크리스트 표준 양식은 KFIU 매뉴얼 부록 외에 추천하실 만한 자료가 있으신지요?$C$,
        c_id, '2026-05-07 09:18:00'::timestamp, '2026-05-07 09:18:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: jaemin.oh
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jaemin.oh@globalgates.test'),
        'active'::post_status,
        $C$FATF(국제자금세탁방지기구) 의 'Risk-Based Approach Guidance for Banks' 와 한국은행 외환정보팀의 '외국환거래 자율점검 모범사례집' 두 자료를 함께 보시면 체크리스트 깊이가 올라갑니다. 특히 FATF 자료는 거래 유형별 리스크 가중치 산정 방법론이 명확해 사내 모델링에 직접 활용 가능합니다.$C$,
        r_id, '2026-05-07 13:48:00'::timestamp, '2026-05-07 13:48:00'::timestamp);

    -- 댓글 2: jaeho.kim (반도체 PRO+)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jaeho.kim@globalgates.test'),
        'active'::post_status,
        $C$반도체 거래는 OFAC Entity List 와 AML 시스템을 통합 운영하는 것이 효과적입니다. 저희는 KFIU STR 알림과 BIS Entity List 알림을 동일 대시보드에서 처리하도록 통합했고, 컴플라이언스 담당자 작업시간이 약 35% 단축됐습니다. 시스템 통합은 초기 비용이 추가되지만 운영 단계에서 비용 회수가 빠른 편입니다.$C$,
        post_id, '2026-05-08 10:32:00'::timestamp, '2026-05-08 10:32:00'::timestamp);

    -- 댓글 3: jian.song (베트남 WFOE EXPERT)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jian.song@globalgates.test'),
        'active'::post_status,
        $C$베트남 SBV(중앙은행) 의 외화관리 규정은 국내 KFIU 기준과 차이가 있어 호치민 법인에서 별도 신고 시스템을 운영합니다. 사업장 단위 신고 의무가 있고, 분기 신고 마감일을 놓치면 SBV 의 자체 가산금이 부과됩니다. 한국 본사와 베트남 법인의 AML 보고 체계를 분리하시는 것을 권장드립니다.$C$,
        post_id, '2026-05-08 14:05:00'::timestamp, '2026-05-08 14:05:00'::timestamp);


    -- =========================================================
    -- POST 12 — 2026-05-19 17:48  수입 바이어 네트워크
    -- =========================================================
    INSERT INTO tbl_post (member_id, post_status, title, content, location, community_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $T$베트남 바이어 미팅 후기 — 통상임금·CIT 인센티브 협상 + 호치민 SHTP 입주 조건 검토$T$,
        $B$지난주 베트남 호치민 SHTP(Saigon Hi-Tech Park) 입주 검토 미팅 후기입니다. KOTRA 호치민 무역관과 베트남 기획투자부 MPI 산하 외국인투자국 FIA 의 자료를 사전 검토했고, 현지 컨설팅사와 합동 미팅으로 진행했습니다.

[핵심 협상 포인트]
1) 통상임금 — 베트남 평균 240 USD/월 (2026.1 인상분 반영). 호치민 1지역 기준 최저임금 4,960,000 VND/월. 사회보험·실업보험·산재보험 합산 23.5% 가산.
2) CIT(법인세) 인센티브 — 첨단기술 분야 적용 시 4년 0% + 9년 5% + 이후 일반세율 20%. SHTP 입주기업은 자동 적용. 일반 산업단지는 별도 신청 필요.
3) MOIT 의 IRC(투자등록증) / ERC(기업등록증) 발급 평균 60일. SHTP 의 자체 OIP(One-Stop Investment Portal) 활용 시 평균 45일로 단축.
4) 통화 관리 — 베트남 SBV 의 외화관리 규정에 따라 외화차입은 사전 승인 필요. 자본금 송금은 1주 이내 처리.

호치민 SHTP 입주는 단순 비용 절감이 아니라 동남아 광역 거점 전략으로 보아야 한다는 것이 가장 큰 학습이었습니다.$B$,
        '베트남 호치민', 20, '2026-05-19 17:48:00'::timestamp, '2026-05-19 17:48:00'::timestamp)
    RETURNING id INTO post_id;

    -- 댓글 1: jian.song (베트남 WFOE EXPERT, 본인 상품)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jian.song@globalgates.test'),
        'active'::post_status,
        $C$호치민 SHTP 와 Saigon Hi-Tech Industrial Zone(SHIZ) 의 인센티브 비교는 결정적으로 살펴보셔야 할 부분입니다. SHTP 는 첨단기술 R&D 비중 50% 이상 요건이 까다로워 입주 후 사후관리에서 자격 박탈 사례가 종종 있고, SHIZ 는 요건이 완화되지만 CIT 인센티브가 4년 0% + 4년 5% 로 축소됩니다. R&D 비중 사전 시뮬레이션이 필수입니다.$C$,
        post_id, '2026-05-19 21:14:00'::timestamp, '2026-05-19 21:14:00'::timestamp)
    RETURNING id INTO c_id;

    -- 답글: pigchan
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES (owner_id, 'active'::post_status,
        $C$R&D 비중 50% 요건은 사전에 무역관 자료에서 확인했지만, 실제 사후관리에서 자격 박탈 사례가 많다는 점은 처음 들었습니다. 박탈 시 인센티브 환수 범위가 어디까지인지요? 그리고 IRC 처리기간을 SHTP OIP 활용 외에 추가로 단축할 수 있는 노하우가 있다면 공유 부탁드립니다.$C$,
        c_id, '2026-05-20 09:32:00'::timestamp, '2026-05-20 09:32:00'::timestamp)
    RETURNING id INTO r_id;

    -- 재답글: jian.song
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='jian.song@globalgates.test'),
        'active'::post_status,
        $C$인센티브 환수는 직전 3년분 CIT 차액 + 이자(SBV 기준금리 +2%) 까지가 일반적입니다. 자격 박탈 회피의 핵심은 R&D 비중 측정 방식으로, 매출 기준이 아닌 비용 기준(R&D 인건비 + 장비 감가상각)으로 산정 신청하면 요건 충족이 용이합니다. IRC 처리 단축은 MPI(기획투자부) 외국인투자국 FIA 의 'Pre-screening' 절차를 활용하시면 평균 12일 추가 단축됩니다. 신청비 무료, 평균 처리 14일입니다.$C$,
        r_id, '2026-05-20 14:18:00'::timestamp, '2026-05-20 14:18:00'::timestamp);

    -- 댓글 2: yena.choi (의류 PRO, GRS 원단)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='yena.choi@globalgates.test'),
        'active'::post_status,
        $C$의류 OEM 의 베트남 봉제기지화 케이스에서 GRS 인증 폴리에스터 원단 수출 시 베트남 CIT 인센티브가 큰 도움이 됐습니다. SHTP 가 아닌 일반 산업단지지만, 친환경 원단 R&D 비중을 비용 기준으로 산정하여 인센티브 신청에 성공한 사례가 있습니다. 한-베트남 FTA + CIT 인센티브 조합 시 마진율이 평균 4.2%p 개선됐습니다.$C$,
        post_id, '2026-05-20 11:45:00'::timestamp, '2026-05-20 11:45:00'::timestamp);

    -- 댓글 3: seonho.baek (브라질 시장 자문 FREE)
    INSERT INTO tbl_post (member_id, post_status, content, reply_post_id, created_datetime, updated_datetime)
    VALUES ((SELECT id FROM tbl_member WHERE member_email='seonho.baek@globalgates.test'),
        'active'::post_status,
        $C$흥미로운 비교 관점에서, 브라질 ZFM(Manaus 자유무역지대) 의 IPI 면제 + ICMS 환급 + II 면제 구조와 베트남 SHTP 의 CIT 인센티브가 다국적 입지전략 측면에서 보완재가 됩니다. 미주-동남아 양 거점화 시 자본 분산을 7:3 비율로 가져가는 것이 일반적이고, 환위험 관리상으로도 USD/VND 한쌍의 변동성보다 USD/BRL + USD/VND 두쌍의 변동성이 평균 28% 낮아 헤지 비용도 함께 절감됩니다.$C$,
        post_id, '2026-05-21 09:08:00'::timestamp, '2026-05-21 09:08:00'::timestamp);
END $pf$;

COMMIT;

-- =============================================================
-- 검증
-- =============================================================
SELECT 'pigchan_top_posts' AS what, COUNT(*) AS cnt
FROM tbl_post
WHERE member_id = (SELECT id FROM tbl_member WHERE member_email='pigchan0202@gmail.com')
  AND reply_post_id IS NULL
UNION ALL
SELECT 'replies_total', COUNT(*) FROM (
    WITH RECURSIVE thread AS (
        SELECT id FROM tbl_post
        WHERE member_id = (SELECT id FROM tbl_member WHERE member_email='pigchan0202@gmail.com')
          AND reply_post_id IS NULL
        UNION ALL
        SELECT p.id FROM tbl_post p JOIN thread t ON p.reply_post_id = t.id
    )
    SELECT id FROM thread
    EXCEPT
    SELECT id FROM tbl_post
    WHERE member_id = (SELECT id FROM tbl_member WHERE member_email='pigchan0202@gmail.com')
      AND reply_post_id IS NULL
) x
UNION ALL
SELECT 'replies_by_pigchan', COUNT(*) FROM tbl_post p
WHERE p.member_id = (SELECT id FROM tbl_member WHERE member_email='pigchan0202@gmail.com')
  AND p.reply_post_id IS NOT NULL;

SELECT m.member_email, COUNT(*) AS replies_authored
FROM tbl_post p
JOIN tbl_member m ON m.id = p.member_id
WHERE p.reply_post_id IS NOT NULL
  AND p.reply_post_id IN (
      WITH RECURSIVE thread AS (
          SELECT id FROM tbl_post
          WHERE member_id = (SELECT id FROM tbl_member WHERE member_email='pigchan0202@gmail.com')
            AND reply_post_id IS NULL
          UNION ALL
          SELECT p2.id FROM tbl_post p2 JOIN thread t ON p2.reply_post_id = t.id
      )
      SELECT id FROM thread
  )
GROUP BY m.member_email
ORDER BY replies_authored DESC, m.member_email;
