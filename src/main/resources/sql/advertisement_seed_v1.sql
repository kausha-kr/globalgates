-- ============================================================
--  advertisement_seed_v1.sql
--  20 dummy advertisements seeded for tbl_advertisement /
--  tbl_ad_file / tbl_file / tbl_payment_advertisement.
--  Idempotent: re-applying purges previous AD-SEED rows first.
--
--  S3 image path convention: 2026/05/20/advertisement/ad_XX.jpg
--  (user will upload ad_01.jpg ~ ad_20.jpg to that prefix)
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. CLEANUP (re-run safe) ── delete in FK-safe order
-- ------------------------------------------------------------
DELETE FROM tbl_payment_advertisement
  WHERE ad_id IN (SELECT id FROM tbl_advertisement WHERE receipt_id LIKE 'AD-SEED-%');

DELETE FROM tbl_ad_file
  WHERE ad_id IN (SELECT id FROM tbl_advertisement WHERE receipt_id LIKE 'AD-SEED-%');

DELETE FROM tbl_file
  WHERE file_path LIKE '2026/05/20/advertisement/ad_%';

DELETE FROM tbl_advertisement
  WHERE receipt_id LIKE 'AD-SEED-%';

-- ------------------------------------------------------------
-- 2. STAGING: ad copy (advertiser_email driven so re-mapping is trivial)
-- ------------------------------------------------------------
CREATE TEMP TABLE _gg_ad_data (
  ord                  int          PRIMARY KEY,
  advertiser_email     varchar      NOT NULL,
  title                varchar      NOT NULL,
  headline             varchar      NOT NULL,
  description          text         NOT NULL,
  landing_url          varchar      NOT NULL,
  budget               numeric      NOT NULL,
  impression_estimate  int          NOT NULL,
  status               ad_status    NOT NULL,
  started_at           timestamp    NOT NULL,
  payment_method       varchar      NOT NULL,
  original_name        varchar      NOT NULL
) ON COMMIT DROP;

INSERT INTO _gg_ad_data VALUES
( 1, 'pigchan0202@gmail.com',
  'Pigchan Trading 종합 카탈로그 2026 — K-Premium 5,200 SKU 단일 발주',
  '단 한 곳에서 K-Beauty · K-Food · 산업소재 · 의료기기까지, 47개국 1,200 바이어 검증 셀러 큐레이션',
  $D$Pigchan Trading은 K-Beauty · K-Food · 산업소재 · 의료기기를 아우르는 20년 경력의 종합 트레이딩 파트너입니다. KOTRA 회원사 인증과 KITA 정회원 자격을 보유하고 있으며, 47개국 1,200여 바이어 네트워크를 통해 자체 실사 통과 셀러만을 큐레이션합니다. Trade Assurance 기반 에스크로 결제, K-SURE 단기수출보험 자동 부보, 한-아세안 및 RCEP FTA 원산지증명서 무상 발급을 통합 제공합니다. 단일 거래선으로 카테고리 통합 발주가 가능하며, LCL 콘솔리데이션을 통한 평균 22% 물류비 절감 트랙 레코드를 보유합니다. 신규 바이어에게는 첫 거래 0.3% 수수료 할인과 EXW 견본품 무상 제공 혜택을 적용합니다. 지금 상담을 신청하시면 카테고리 매니저가 48시간 이내 직접 회신합니다.$D$,
  'https://pigchan-trade.com/wholesale?utm_source=globalgates&utm_medium=display&utm_campaign=catalog2026',
  4500000, 720000, 'active', '2026-05-01 09:30:00', 'card',
  'pigchan_trading_catalog_2026.jpg'),

( 2, 'jaeho.kim@globalgates.test',
  'Semicom Korea — 반도체 후공정 EMC · Lead Frame · Sputtering Target',
  'IATF 16949 / ISO 9001 인증 후공정 부자재, RFQ 14일 회신 SLA 보장',
  $D$Semicom Korea는 반도체 후공정(Back-end)용 EMC, Lead Frame, Sputtering Target 소재를 OSAT 및 IDM 고객사에 직납하는 1차 협력사입니다. IATF 16949와 ISO 9001 이중 인증, 산업통상자원부 소부장 으뜸기업 지정, JEDEC MSL 1~3 등급 적합성 시험 데이터를 표준 제공합니다. RFQ 회신 14일 이내 SLA를 계약 단계에서 명문화하며, Wafer 다이싱 후 칩 단위 패키징까지 일괄 견적이 가능합니다. 미국·일본·대만 OSAT 고객사 8개사 양산 승인 이력을 통해 품질 안정성을 검증받았습니다. 신규 거래 검토 단계에서 NDA 체결 후 샘플 100pcs를 무상 제공하며, 풀패키지 라우팅 옵션 컨설팅까지 패키지로 지원합니다.$D$,
  'https://semicom-korea.com/oem-inquiry?ref=gg2026&channel=display',
  3200000, 480000, 'active', '2026-04-22 11:00:00', 'card',
  'semicom_korea_oem.jpg'),

( 3, 'sumin.lee@globalgates.test',
  'Lumiere Cosmetic — K-Beauty 글로벌 도매 (CGMP · EWG Green · Vegan Society)',
  '북미·유럽·동남아 도매 바이어 전용 도매가, MOQ 600pcs, FOB Busan 7일 출고',
  $D$Lumiere Cosmetic은 비건 인증(Vegan Society) 및 EWG Green 등급 K-Beauty 브랜드의 글로벌 도매 전문 ODM·OBM 파트너입니다. 식약처 CGMP 적합업소 인증, 미국 FDA OTC 등록, EU CPNP Notification 사전 완료 상태로 즉시 수출이 가능합니다. 북미·유럽·동남아 도매 바이어에게는 정상가 대비 평균 38% 할인된 도매가를 제공하며, MOQ 600pcs / FOB Busan 7일 출고를 표준 리드타임으로 운영합니다. 도매 계약 체결 시 영문/스페인어/베트남어 패키지 디자인 무상 커스터마이즈와 Amazon Vendor Central 등록 자료 지원이 함께 제공됩니다. 샘플 키트 신청은 영업일 기준 24시간 이내 발송됩니다.$D$,
  'https://lumiere-cosmetic.kr/wholesale-program?lang=en&utm_campaign=gg-display',
  3800000, 560000, 'active', '2026-05-05 10:15:00', 'card',
  'lumiere_kbeauty_wholesale.jpg'),

( 4, 'jiwon.park@globalgates.test',
  'Korea Food World — 김치·고추장·만두·HMR 통합 카탈로그',
  'FSVP 발효식품 · SFDA 사우디 등록 완료, 콜드체인 직송 평균 리드타임 9일',
  $D$Korea Food World는 김치·고추장·전통주·HMR·만두·라면 등 한국 식품 12개 카테고리의 글로벌 수출 전문 카탈로그를 운영합니다. 미국 FDA FSVP(외국공급자검증프로그램) 적격 공급자 인증을 보유하고 있으며, 사우디 SFDA 식품 등록과 중국 GACC 해외제조업체 등록을 사전 완료하여 통관 리스크를 사전 차단합니다. IATA CEIV Fresh 인증 콜드체인 항공 직송을 통해 부산-LA 평균 리드타임 9일, 부산-함부르크 평균 11일을 보장합니다. 한국농수산식품유통공사 aT 수출통합지원사업 매칭으로 신규 바이어 첫 발주분 항공운임의 30%까지 환급이 가능합니다. RFQ 발송 즉시 카테고리 MD가 1:1 컨설팅을 시작합니다.$D$,
  'https://kfoodworld.kr/catalog/2026-spring?ref=globalgates-feed',
  2900000, 420000, 'active', '2026-04-10 14:30:00', 'card',
  'kfoodworld_catalog_spring.jpg'),

( 5, 'taeyoung.jung@globalgates.test',
  'Ulsan AutoParts — EV 구동계 / 알루미늄 다이캐스팅 부품 글로벌 공급',
  'IATF 16949 인증, 현대·기아·GM 양산 이력 보유, EV 모터 하우징 RFQ 진행 중',
  $D$Ulsan AutoParts는 EV 구동계 핵심 부품인 모터 하우징, 인버터 케이스, 알루미늄 다이캐스팅 부품을 현대·기아·GM·Stellantis 글로벌 OEM에 양산 공급해 온 Tier 1 부품사입니다. IATF 16949 인증과 ISO 14064 탄소중립 이행계획서 등록을 완료했으며, 멕시코 몬테레이 KD 라인 직납이 가능합니다. EV 모터 하우징 신규 RFQ에 한해 3D 캐드 검토 후 5일 이내 견적 회신 SLA를 적용합니다. CBAM 시범기간 대응 탄소배출 산정서를 발급해 EU 수출 바이어의 보고 의무를 지원합니다. 시제품 사출 시 금형비의 50%를 양산 발주 후 정산하는 NRE 분할 정산 옵션도 제공합니다.$D$,
  'https://ulsan-autoparts.com/ev-driveline?ref=gg-ads',
  3500000, 510000, 'active', '2026-04-28 16:00:00', 'card',
  'ulsan_autoparts_ev.jpg'),

( 6, 'yena.choi@globalgates.test',
  'EcoFabric Korea — GRS · OEKO-TEX 친환경 원단 OEM',
  '재활용 폴리에스터 60% 이상, GRS 4.0 / OEKO-TEX STeP 인증, 유럽 패션 브랜드 18개사 납품',
  $D$EcoFabric Korea는 재활용 폴리에스터(rPET) 60% 이상 함유 원단을 GRS 4.0 / OEKO-TEX STeP / RCS 통합 인증 라인에서 생산하는 친환경 원단 OEM 전문 기업입니다. EU CSRD 공급망 실사 지침과 PEFCR 적합성 자료를 표준 제공하며, ZDHC MRSL 적합성 시험 성적서가 동봉됩니다. 유럽 패션 브랜드 18개사에 정기 납품 중이며, 함부르크 항만까지의 평균 리드타임은 32일입니다. 신규 바이어 대상 4종 컬러웨이 샘플 야드를 무상으로 제공하며, EUDR 산림훼손 규정 대응 트레이서빌리티 리포트가 자동 발급됩니다.$D$,
  'https://ecofabric.co.kr/oem-program?lang=en&utm_medium=display',
  2400000, 350000, 'active', '2026-03-30 09:00:00', 'card',
  'ecofabric_grs_oem.jpg'),

( 7, 'seungwoo.han@globalgates.test',
  'FTA Clinic — 원산지증명서 사후검증 · 자율점검 무료 진단 (관세청 출신 자문)',
  'AEO 공인업체 자문, 사후검증 적출 0건 트랙레코드 12년, 1차 진단 90분 무료',
  $D$FTA Clinic은 전 관세청 자유무역협정집행과 사무관 출신이 직접 운영하는 원산지증명서 사후검증 대응 전문 컨설팅 부띠끄입니다. AEO(수출입안전관리우수업체) 공인 컨설팅 지정 자문사로서 12년간 사후검증 적출 0건의 트랙 레코드를 유지하고 있습니다. 1차 진단(90분)은 NDA 체결 후 전액 무료로 제공되며, 한-EU · 한-미 · RCEP · 한-아세안 FTA 협정별 원산지 결정기준(HS코드 6단위 기준) 자율점검 체크리스트를 디지털 보고서로 발급합니다. 사후검증 통보를 이미 수령한 사례는 영업일 기준 2일 이내 긴급 대응 가능합니다.$D$,
  'https://fta-clinic.kr/free-assessment?promo=spring2026',
  1800000, 240000, 'active', '2026-04-18 13:20:00', 'card',
  'fta_clinic_diagnostic.jpg'),

( 8, 'chaerin.yoon@globalgates.test',
  '인천공항 특송 통관 EXPRESS — 24시간 통관 + AEO 가산점 패키지',
  '관세사 전담 통관, 통관 평균 4시간 12분, EORI / IOR 대행 일원화',
  $D$인천공항 특송 통관법인의 EXPRESS 패키지는 EMS·UPS·FedEx·DHL 화물을 통합한 일반 특송 + B/L 분할 통관 + ATA Carnet 임시통관까지 일원화한 풀스택 통관 솔루션입니다. 인천공항 자유무역지역 내 자가 보세창고를 운영하여 평균 통관 소요 4시간 12분을 기록 중이며, 24/7 야간 통관 데스크가 상시 운영됩니다. EORI(EU) / IOR(미국) / VAT 대리납부까지 단일 계약으로 처리하며, AEO 공인업체 등급 가산점 컨설팅이 포함됩니다. 본 캠페인은 기간 한정으로 종료되었으나, 후속 캠페인 안내를 받으실 수 있습니다.$D$,
  'https://icn-customs.kr/express-package?ref=globalgates',
  1500000, 180000, 'expired', '2026-02-15 08:45:00', 'card',
  'icn_customs_express.jpg'),

( 9, 'dohyun.lim@globalgates.test',
  '국제물류 무료 진단 — FCL · LCL · 항공 통합 단가 시뮬레이션',
  '40대 포워더 실시간 견적 비교, 평균 18% 운임 절감, 부킹 자동화 SaaS 무료 트라이얼',
  $D$국제물류 시니어 컨설턴트가 직접 운영하는 LogiX Hub는 40개 글로벌 포워더의 FCL / LCL / 항공 실시간 견적을 한 화면에서 비교하고 부킹까지 자동화하는 B2B SaaS 플랫폼입니다. 출고지 · POL · POD · 인코텀즈 · 화물 특성(IMDG / Reefer / OOG)을 입력하면 평균 18% 운임 절감 시뮬레이션이 30초 내 제공됩니다. 신규 가입 기업에는 60일 무료 트라이얼과 함께 시니어 컨설턴트 2시간 1:1 견적 검토가 포함됩니다. NVOCC FMC 라이선스 및 IATA 화물대리점 자격을 보유한 파트너만 노출되어 신뢰성을 확보합니다.$D$,
  'https://logix-hub.kr/free-trial?campaign=gg-spring',
  2100000, 310000, 'active', '2026-04-02 10:50:00', 'card',
  'logix_hub_trial.jpg'),

(10, 'nayoung.kang@globalgates.test',
  'Global Marketing Lab — 동남아 6개국 SNS 출시 캠페인 패키지',
  '베트남·인니·태국 KOL 매칭 + Shopee/Lazada/TikTok Shop 동시 런칭, 90일 보증',
  $D$Global Marketing Lab은 한국 브랜드의 동남아 6개국(베트남 · 인도네시아 · 태국 · 말레이시아 · 필리핀 · 싱가포르) 동시 런칭을 90일 안에 완수하는 풀스택 마케팅 부띠끄입니다. 현지 KOL 데이터베이스 2,400명을 자체 운영하며, 카테고리별 마이크로 인플루언서 매칭부터 콘텐츠 제작·번역·법규 검수까지 일괄 수행합니다. Shopee · Lazada · TikTok Shop 동시 입점, GMV(Gross Merchandise Value) 첫 90일 목표 미달 시 추가 캠페인 무상 연장 SLA를 계약서에 명문화합니다. 한국콘텐츠진흥원 KOCCA 글로벌 마케팅 지원사업 매칭으로 캠페인비의 최대 40%까지 환급 가능합니다.$D$,
  'https://globalmarketinglab.kr/sea-launch?promo=gg-2026',
  3300000, 470000, 'active', '2026-04-25 15:10:00', 'card',
  'global_marketing_lab_sea.jpg'),

(11, 'jaemin.oh@globalgates.test',
  '무역금융 · 환변동 보험 종합 컨설팅 (전 시중은행 외환사업부)',
  'K-SURE 환변동보험 Collar Plus 설계, 손익분기 환율 시뮬레이션 무료',
  $D$전 시중은행 외환사업부 전문위원이 직접 진행하는 무역금융 · 환변동 종합 컨설팅 패키지입니다. K-SURE 환변동보험 Collar Plus 구조 설계, 은행 선도환 대비 손익분기 환율 시뮬레이션, USD / EUR / JPY 다통화 헤지 비율 산정을 1:1로 진행합니다. 수출입은행 · 무역보험공사 · 시중은행 외환 부서 핵심 인맥을 활용한 한도 조정 협상 지원을 제공하며, NEGO / D/P / D/A / O/A 거래 조건별 자금 회수 일자 컨트롤 시뮬레이션이 포함됩니다. AML / CFT 의심거래보고(STR) 회피용 결제 구조 사전 점검도 함께 제공되어 KFIU 리스크를 사전 차단합니다.$D$,
  'https://tradefinance-pro.kr/fx-clinic?utm_source=gg',
  2200000, 290000, 'active', '2026-03-22 11:30:00', 'card',
  'tradefinance_fx_clinic.jpg'),

(12, 'jian.song@globalgates.test',
  '베트남·인니 동남아 진출 풀패키지 (호치민 거주 자문역 직접 진행)',
  '법인설립 · DPI 인허가 · 호치민 SHTP 입주 · 베트남 노동허가서까지 일원화',
  $D$호치민 7년 거주 자문역이 직접 진행하는 동남아 진출 풀패키지입니다. 베트남 외국인투자법인(FIE) 설립, MPI(Ministry of Planning and Investment) IRC / ERC 발급, 호치민 SHTP(사이공 첨단기술단지) 입주 신청, 노동허가서(Work Permit) 발급까지 단일 컨설턴트가 일원화 진행합니다. SBV(베트남 중앙은행) FX 송금 라인 개설 자문과 인도네시아 OSS-RBA(Risk Based Approach) 인허가 트랙도 옵션으로 결합 가능합니다. 본 캠페인은 1분기 종료되었으나 후속 패키지 안내를 신청하실 수 있습니다.$D$,
  'https://sea-entry.kr/vietnam-package?ref=gg-feed',
  2700000, 360000, 'expired', '2026-01-20 09:00:00', 'card',
  'sea_entry_vietnam.jpg'),

(13, 'hyunwoo.bae@globalgates.test',
  'EuroTech Sourcing — DACH 산업재 바이어 매칭 (함부르크 본사)',
  '독일 · 오스트리아 · 스위스 산업재 바이어 데이터베이스 1,900사, 첫 미팅까지 평균 21일',
  $D$EuroTech Sourcing은 함부르크 본사를 거점으로 DACH(독일 · 오스트리아 · 스위스) 산업재 바이어를 한국 셀러에 매칭하는 B2B 부띠끄입니다. 1,900사 규모의 자체 바이어 데이터베이스에서 셀러 제품군·MOQ·인증 보유 여부에 따라 우선순위 매칭을 진행하며, 첫 화상 미팅까지의 평균 소요 시간은 21일입니다. EU CE Machinery Directive 2006/42/EC, EN ISO 12100 적합성 사전 검토와 EU DG TAXUD 통관 요건 사전 점검이 패키지에 포함됩니다. 함부르크 항만 보세창고를 통한 EU 역내 콘솔리데이션 옵션과 ATA Carnet 임시통관 자문도 결합 가능합니다.$D$,
  'https://eurotech-source.eu/kr-sellers?utm_campaign=gg-display',
  2600000, 380000, 'active', '2026-04-12 17:25:00', 'card',
  'eurotech_dach_matching.jpg'),

(14, 'yujin.noh@globalgates.test',
  'Incheon Chemical — 산업화학 원료 수입대행 (KGMP · REACH 등록 일괄)',
  '유럽 REACH / 미국 TSCA / 한국 화평법 등록 대행, MSDS 다국어 번역 무상',
  $D$Incheon Chemical은 산업화학 원료 및 식품첨가물 수입대행 전문 종합상사입니다. 유럽 REACH 사전 등록 / SVHC 통보, 미국 EPA TSCA Section 5 / 6 등록, 한국 환경부 화평법(K-REACH) 일괄 등록 서비스를 단일 계약으로 제공합니다. MSDS(SDS) 영문·중문·일문·베트남어 번역 및 GHS 라벨 디자인이 무상 포함됩니다. KGMP / cGMP 적격 공급자 풀에서 셀러를 큐레이션하며, 컨테이너 단위 분할 수입 시 평균 19% 물류비 절감 시뮬레이션을 제공합니다. 신규 거래 검토 단계에서 1차 진단 60분과 샘플 200g 무상 제공이 포함됩니다.$D$,
  'https://incheon-chem.com/import-program?lang=en',
  1900000, 260000, 'active', '2026-03-15 14:00:00', 'card',
  'incheon_chemical_import.jpg'),

(15, 'minho.hwang@globalgates.test',
  'Changwon MachineWorks — CNC 정밀가공 / 5축 가공 글로벌 OEM',
  '항공기 부품 AS9100 인증, 5축 가공 ±0.005mm, 시제품 7일 인도',
  $D$Changwon MachineWorks는 5축 CNC 정밀가공과 항공기 부품 가공 전문 OEM 기업입니다. AS9100D 항공품질경영시스템, ISO 9001:2015, NADCAP 비파괴검사 인증을 보유하고 있으며, 가공 공차 ±0.005mm를 표준 보장합니다. 시제품은 도면 검토 후 7일 이내 인도 가능하며, 양산 단계에서는 멕시코 케레타로 · 미국 휴스턴 위탁 가공 라인을 통해 현지 납기 단축 옵션을 제공합니다. 항공·우주·의료기기·반도체 장비용 가공 부품 견적이 가능하며, 도면 NDA 체결 후 가공성(DFM) 리포트를 무상 발급합니다. 신규 바이어 첫 양산 발주분에 한해 금형/지그 비용 30% 할인을 적용합니다.$D$,
  'https://changwon-mw.com/quote?ref=gg-2026',
  2500000, 320000, 'active', '2026-04-05 10:00:00', 'card',
  'changwon_mw_5axis.jpg'),

(16, 'yerin.shin@globalgates.test',
  '수출보험 종합 진단 (전 K-SURE 인수심사역 직접 검토)',
  '단기수출보험 · 환변동 · K-SURE Plus+ 특약 통합 설계, 한도 증액 평균 +37%',
  $D$전 K-SURE(한국무역보험공사) 인수심사역이 직접 진행하는 수출보험 종합 진단 패키지입니다. 단기수출보험(L), 중장기수출보험, K-SURE Plus+ 특약, 환변동보험, 농수산물패키지보험까지 5종을 통합 설계하여 보장 공백을 사전에 차단합니다. 인수심사 시 핵심 평가 지표(바이어 신용등급 · 결제조건 · 환위험노출)를 사전 점검하여 한도 증액 사유서를 작성하며, 트랙 레코드 기준 평균 한도 증액률은 +37%입니다. 보험사고 발생 시 보험금 청구서 작성 대행 및 추심(코리아크레딧뷰로 / 코페이스) 연계도 함께 지원합니다. 1차 진단은 NDA 체결 후 무료 제공.$D$,
  'https://k-sure-clinic.kr/diagnostic?promo=gg-display',
  2000000, 280000, 'active', '2026-04-15 13:40:00', 'card',
  'ksure_clinic_diagnostic.jpg'),

(17, 'taewoo.kwon@globalgates.test',
  '포워더 통합 견적 ForwarderPro — FCL · LCL · 항공 · 특송 4-in-1 견적',
  '120개 포워더 견적 동시 비교, 부킹 자동화, 평균 16% 운임 절감 보증',
  $D$ForwarderPro는 글로벌 120개 포워더의 FCL · LCL · 항공 · 특송 견적을 단일 인터페이스에서 동시 비교하는 B2B 견적 통합 플랫폼입니다. 부킹 자동화 API를 통해 B/L 발행 · ETA 추적 · DEM/DET 알림까지 일원화하며, IATA 화물대리점 자격과 NVOCC FMC 라이선스 보유 파트너만 노출됩니다. 평균 16% 운임 절감 시뮬레이션을 회원 가입 즉시 제공하고, 신규 가입 90일 차 회수 이력이 없는 경우 멤버십 비용 100% 환불 SLA가 적용됩니다. 본 캠페인은 종료되었으며 후속 캠페인이 곧 시작됩니다.$D$,
  'https://forwarder-pro.kr/quote-engine?ref=globalgates',
  1700000, 220000, 'expired', '2025-12-28 11:00:00', 'card',
  'forwarderpro_quote.jpg'),

(18, 'haneul.cho@globalgates.test',
  'Digital Trade Hub — B2B 디지털 무역 SaaS (월 ₩99,000부터)',
  '바이어 매칭 · 견적관리 · 인보이스 · L/C 추적까지 단일 대시보드',
  $D$Digital Trade Hub는 중소 수출 기업을 위한 B2B 무역 SaaS 통합 대시보드입니다. KOTRA 바이어코리아 · KITA TradeNAVI · Alibaba RFQ를 한 화면에 통합하고, 견적·인보이스·패킹리스트·B/L·L/C 진행 상황을 추적할 수 있습니다. 월 ₩99,000부터 시작하며, 14일 무료 트라이얼과 데이터 마이그레이션 무상 지원이 포함됩니다. 본 광고는 일부 표현이 자체 가이드라인을 위반했다는 신고 접수로 검토 중이며, 캠페인 메시지는 곧 갱신될 예정입니다. 문의는 영업일 기준 12시간 이내 회신됩니다.$D$,
  'https://digitaltradehub.io/pricing?ref=gg-feed',
  1400000, 190000, 'reported', '2026-04-08 16:30:00', 'card',
  'digital_trade_hub_saas.jpg'),

(19, 'siwoo.yang@globalgates.test',
  'Daejeon Fresh Farm — 딸기 · 샤인머스캣 콜드체인 항공직송 도매',
  'IATA CEIV Fresh 인증, 부산-홍콩 38시간 도어투도어, 1차 산지 검품 영상 제공',
  $D$Daejeon Fresh Farm은 충청·논산 산지에서 출하한 딸기(설향·금실) · 샤인머스캣 · 토마토 · 멜론을 글로벌 도매 바이어에 콜드체인 항공직송하는 신선농산물 수출 전문 농장형 종합상사입니다. IATA CEIV Fresh 인증 콜드체인 항공 전용 라인을 활용하여 부산-홍콩 도어투도어 38시간, 부산-싱가포르 46시간을 기록 중입니다. 산지 직송 1차 검품 영상을 바이어에게 실시간 공유하여 품질 분쟁을 사전 차단하며, aT 한국농수산식품유통공사 수출 통합지원사업 매칭으로 항공운임의 최대 30%까지 사후 환급이 가능합니다. 신규 바이어 첫 거래분에 한해 EXW 샘플 4kg 무상 제공.$D$,
  'https://daejeon-fresh.kr/wholesale-export?utm_source=gg',
  2300000, 330000, 'active', '2026-04-20 07:30:00', 'card',
  'daejeon_fresh_coldchain.jpg'),

(20, 'gaeun.moon@globalgates.test',
  'HealthGlobal Med — 의료기기 RA 글로벌 등록 패키지 (FDA · CE · PMDA)',
  '510(k) · MDR · PMDA 사전심사 일괄 진행, 평균 등록 기간 -28% 단축',
  $D$HealthGlobal Med는 의료기기 글로벌 RA(Regulatory Affairs) 등록 전문 부띠끄입니다. 미국 FDA 510(k) Premarket Notification, EU MDR Class IIa/IIb CE 인증, 일본 PMDA 사전심사, 사우디 SFDA MDMA 등록을 단일 컨설턴트가 일관 진행하여 등록 기간을 평균 28% 단축합니다. ISO 13485 품질경영시스템 구축 및 CSR 적합성 시험 데이터 큐레이션, 임상시험계획서(IDE / IND) 사전 검토가 포함됩니다. 본 캠페인은 3월 기준 종료되었으며, 5월 후속 캠페인 안내를 위한 사전 예약을 받고 있습니다. NDA 체결 후 1차 진단 90분은 무상 제공됩니다.$D$,
  'https://healthglobal-ra.kr/global-registration?ref=gg-display',
  1600000, 210000, 'expired', '2026-01-10 12:00:00', 'card',
  'healthglobal_ra_package.jpg');

-- ------------------------------------------------------------
-- 3. INSERT: ads + files + ad_file links + payments
-- ------------------------------------------------------------
DO $ad_seed$
DECLARE
  rec RECORD;
  v_advertiser_id bigint;
  v_ad_id         bigint;
  v_file_id       bigint;
  v_receipt       varchar;
  v_path          varchar;
BEGIN
  FOR rec IN SELECT * FROM _gg_ad_data ORDER BY ord LOOP
    SELECT id INTO v_advertiser_id
      FROM tbl_member
     WHERE member_email = rec.advertiser_email;

    IF v_advertiser_id IS NULL THEN
      RAISE EXCEPTION 'advertiser not found: %', rec.advertiser_email;
    END IF;

    v_receipt := 'AD-SEED-' || lpad(rec.ord::text, 3, '0');
    v_path    := '2026/05/20/advertisement/ad_' || lpad(rec.ord::text, 2, '0') || '.jpg';

    -- ad row
    INSERT INTO tbl_advertisement
      (advertiser_id, title, headline, description, landing_url,
       budget, impression_estimate, receipt_id, status, started_at,
       created_datetime, updated_datetime)
    VALUES
      (v_advertiser_id, rec.title, rec.headline, rec.description, rec.landing_url,
       rec.budget, rec.impression_estimate, v_receipt, rec.status, rec.started_at,
       rec.started_at - interval '1 day', rec.started_at)
    RETURNING id INTO v_ad_id;

    -- file row (S3 banner)
    INSERT INTO tbl_file
      (original_name, file_name, file_path, file_size, content_type, created_datetime)
    VALUES
      (rec.original_name, v_path, v_path, 320000, 'image', rec.started_at - interval '1 day')
    RETURNING id INTO v_file_id;

    -- ad ↔ file link  (tbl_ad_file.id = tbl_file.id per FK in view definition)
    INSERT INTO tbl_ad_file (id, ad_id) VALUES (v_file_id, v_ad_id);

    -- payment (1 completed payment per ad equal to budget)
    INSERT INTO tbl_payment_advertisement
      (ad_id, member_id, amount, payment_status, payment_method,
       receipt_id, paid_at, created_datetime)
    VALUES
      (v_ad_id, v_advertiser_id, rec.budget, 'completed', rec.payment_method,
       v_receipt, rec.started_at, rec.started_at - interval '1 hour');
  END LOOP;
END
$ad_seed$;

-- ------------------------------------------------------------
-- 4. VERIFICATION (visible before COMMIT drops _gg_ad_data)
-- ------------------------------------------------------------
\echo
\echo '=== Advertisement seed summary ==='
SELECT status, COUNT(*) AS cnt, SUM(budget)::bigint AS total_budget
  FROM tbl_advertisement
 WHERE receipt_id LIKE 'AD-SEED-%'
 GROUP BY status
 ORDER BY status;

\echo
\echo '=== Per-advertiser totals ==='
SELECT m.member_email,
       COUNT(*) AS ad_count,
       SUM(a.budget)::bigint AS budget_sum
  FROM tbl_advertisement a
  JOIN tbl_member m ON m.id = a.advertiser_id
 WHERE a.receipt_id LIKE 'AD-SEED-%'
 GROUP BY m.member_email
 ORDER BY budget_sum DESC;

\echo
\echo '=== Files & payments integrity ==='
SELECT
  (SELECT COUNT(*) FROM tbl_advertisement       WHERE receipt_id LIKE 'AD-SEED-%') AS ads,
  (SELECT COUNT(*) FROM tbl_file                WHERE file_path  LIKE '2026/05/20/advertisement/ad_%') AS files,
  (SELECT COUNT(*) FROM tbl_ad_file af
     WHERE af.ad_id IN (SELECT id FROM tbl_advertisement WHERE receipt_id LIKE 'AD-SEED-%')) AS ad_file_links,
  (SELECT COUNT(*) FROM tbl_payment_advertisement
     WHERE receipt_id LIKE 'AD-SEED-%') AS payments,
  (SELECT SUM(amount)::bigint FROM tbl_payment_advertisement
     WHERE receipt_id LIKE 'AD-SEED-%' AND payment_status = 'completed') AS paid_total;

COMMIT;
