-- Presentation dummy data for Hamin's scope:
-- 1) Estimation request list
-- 2) Expert dashboard summary and activity list
-- 3) Admin member/post/report/stat pages
--
-- Assumes core DDL and shared member/product seed data have already been applied.
-- This file is intentionally idempotent-ish: repeated execution avoids duplicate rows
-- by checking stable emails, titles, and reasons.

-- ------------------------------------------------------------
-- 0. Demo accounts used by this scenario
-- ------------------------------------------------------------

insert into tbl_member (
    member_name, member_email, member_password,
    member_nickname, member_handle, member_phone,
    member_bio, member_region, member_status, member_role,
    created_datetime, updated_datetime, last_login_at
)
select '전문가A', 'expert_a@test.com',
       '$2a$10$qBTl1KlLJQ.MuuPGMNqo6.kXpPQ/WjtMeFoPihuTSolrCJ1iIgIqe',
       '전문가A', '@expert_a', '01011112222',
       '발표용 견적 상담 전문가 계정입니다. 상품 검토, 수출 견적, 통관 리스크 상담을 담당합니다.',
       '서울', 'active', 'expert',
       now() - interval '45 days', now(), now() - interval '30 minutes'
where not exists (select 1 from tbl_member where member_email = 'expert_a@test.com');

update tbl_member
set member_password = '$2a$10$qBTl1KlLJQ.MuuPGMNqo6.kXpPQ/WjtMeFoPihuTSolrCJ1iIgIqe',
    member_status = 'active',
    member_role = 'expert',
    updated_datetime = now()
where member_email = 'expert_a@test.com';

insert into tbl_member (
    member_name, member_email, member_password,
    member_nickname, member_handle, member_phone,
    member_bio, member_region, member_status, member_role,
    created_datetime, updated_datetime, last_login_at
)
values
    ('한솔무역', 'demo_buyer_01@test.com', '$2a$10$qBTl1KlLJQ.MuuPGMNqo6.kXpPQ/WjtMeFoPihuTSolrCJ1iIgIqe',
     '한솔무역', '@demo_buyer_01', '01070000001',
     '생활소비재를 일본과 베트남으로 수출하는 중소 무역사입니다.', '경기', 'active', 'business',
     now() - interval '32 days', now(), now() - interval '2 hours'),
    ('동해푸드', 'demo_buyer_02@test.com', '$2a$10$qBTl1KlLJQ.MuuPGMNqo6.kXpPQ/WjtMeFoPihuTSolrCJ1iIgIqe',
     '동해푸드', '@demo_buyer_02', '01070000002',
     'K-Food 냉동식품과 가공식품 수출 상담을 준비 중입니다.', '부산', 'active', 'business',
     now() - interval '24 days', now(), now() - interval '5 hours'),
    ('그린패키지', 'demo_buyer_03@test.com', '$2a$10$qBTl1KlLJQ.MuuPGMNqo6.kXpPQ/WjtMeFoPihuTSolrCJ1iIgIqe',
     '그린패키지', '@demo_buyer_03', '01070000003',
     '친환경 포장재와 종이 완충재를 유럽 시장에 공급합니다.', '대전', 'active', 'business',
     now() - interval '18 days', now(), now() - interval '1 day'),
    ('케이뷰티랩', 'demo_buyer_04@test.com', '$2a$10$qBTl1KlLJQ.MuuPGMNqo6.kXpPQ/WjtMeFoPihuTSolrCJ1iIgIqe',
     '케이뷰티랩', '@demo_buyer_04', '01070000004',
     '화장품 샘플 수출과 해외 인증 비용 견적을 비교하고 있습니다.', '서울', 'active', 'business',
     now() - interval '11 days', now(), now() - interval '3 days')
on conflict (member_email) do update
set member_password = excluded.member_password,
    member_status = 'active',
    member_role = excluded.member_role,
    updated_datetime = now();

-- Admin demo account normalization.
update tbl_member
set member_password = '$2a$10$qBTl1KlLJQ.MuuPGMNqo6.kXpPQ/WjtMeFoPihuTSolrCJ1iIgIqe',
    member_status = 'active',
    member_role = 'admin',
    updated_datetime = now()
where member_email = 'admin@globalgates.com';

-- Subscription mix for admin member chart/filter.
insert into tbl_subscription (member_id, tier, billing_cycle, status, started_at, expires_at, created_datetime, updated_datetime)
select m.id, s.tier::subscription_tier, 'monthly', 'active', now() - s.started_ago, now() + interval '30 days', now() - s.started_ago, now()
from (
    values
        ('demo_buyer_01@test.com', 'pro', interval '20 days'),
        ('demo_buyer_02@test.com', 'pro_plus', interval '15 days'),
        ('demo_buyer_03@test.com', 'free', interval '10 days')
) as s(email, tier, started_ago)
join tbl_member m on m.member_email = s.email
where not exists (
    select 1
    from tbl_subscription sub
    where sub.member_id = m.id
      and sub.status = 'active'
      and sub.tier = s.tier::subscription_tier
);

-- ------------------------------------------------------------
-- 1. Expert activity list
--    InquiryActivityMapper reads posts from members followed by the expert.
-- ------------------------------------------------------------

insert into tbl_follow (follower_id, following_id, created_datetime)
select expert.id, buyer.id, now() - s.ago
from tbl_member expert
join (
    values
        ('demo_buyer_01@test.com', interval '14 days'),
        ('demo_buyer_02@test.com', interval '12 days'),
        ('demo_buyer_03@test.com', interval '8 days'),
        ('demo_buyer_04@test.com', interval '5 days')
) as s(email, ago) on true
join tbl_member buyer on buyer.member_email = s.email
where expert.member_email = 'expert_a@test.com'
  and not exists (
      select 1
      from tbl_follow f
      where f.follower_id = expert.id
        and f.following_id = buyer.id
  );

insert into tbl_post (member_id, post_status, title, content, location, created_datetime, updated_datetime)
select m.id, 'active', p.title, p.content, p.location, now() - p.ago, now() - p.ago
from (
    values
        ('demo_buyer_01@test.com', '베트남 바이어 미팅 준비 체크리스트',
         '다음 주 호치민 바이어 미팅 전 샘플 단가표와 물류 조건을 정리하고 있습니다. 견적서에는 FOB와 CIF 조건을 나눠 비교할 예정입니다.',
         '서울', interval '6 hours'),
        ('demo_buyer_02@test.com', '냉동식품 수출 포장 테스트 결과',
         '드라이아이스 사용량을 줄이기 위해 보냉 박스와 아이스팩 조합을 테스트했습니다. 36시간 운송 기준 온도 유지 결과가 안정적입니다.',
         '부산', interval '1 day'),
        ('demo_buyer_03@test.com', '친환경 포장재 EU 납품 문의 증가',
         '재활용 종이 완충재와 종이테이프 문의가 늘었습니다. CBAM과 별개로 포장재 인증 서류 요청도 많아지고 있습니다.',
         '대전', interval '2 days'),
        ('demo_buyer_04@test.com', '화장품 샘플 통관 서류 준비',
         '인도네시아 샘플 발송용 성분표, MSDS, 인보이스를 준비 중입니다. 현지 등록 전 샘플 통관 기준을 다시 확인하고 있습니다.',
         '서울', interval '3 days')
) as p(email, title, content, location, ago)
join tbl_member m on m.member_email = p.email
where not exists (
    select 1
    from tbl_post existing
    where existing.member_id = m.id
      and existing.title = p.title
);

-- Some engagement for expert summary.
insert into tbl_post_like (member_id, post_id, created_datetime)
select liker.id, post.id, now() - s.ago
from (
    values
        ('demo_buyer_01@test.com', '스테인리스 텀블러 500ml', interval '5 days'),
        ('demo_buyer_02@test.com', '친환경 패키지 박스 50세트', interval '4 days'),
        ('demo_buyer_03@test.com', '스테인리스 텀블러 500ml', interval '2 days')
) as s(liker_email, post_title, ago)
join tbl_member liker on liker.member_email = s.liker_email
join tbl_post post on post.title = s.post_title
where not exists (
    select 1
    from tbl_post_like pl
    where pl.member_id = liker.id
      and pl.post_id = post.id
);

-- ------------------------------------------------------------
-- 2. Estimation request list and expert dashboard summary
-- ------------------------------------------------------------

insert into tbl_estimation (
    requester_id, receiver_id, product_id, title, content,
    location, deadline, status, created_datetime, updated_datetime
)
select requester.id,
       receiver.id,
       product.id,
       e.title,
       e.content,
       e.location,
       current_date + e.deadline_after,
       e.status::estimation_status,
       now() - e.created_ago,
       now() - e.updated_ago
from (
    values
        ('demo_buyer_01@test.com', 'expert_a@test.com', '스테인리스 텀블러 500ml',
         '베트남 판촉용 텀블러 1,000개 수출 견적',
         '베트남 호치민 유통사에 납품할 판촉용 텀블러 1,000개 견적이 필요합니다. 로고 인쇄, 개별 포장, CIF 호치민 조건으로 단가와 납기 확인 부탁드립니다.',
         '베트남 호치민', 14, 'requesting', interval '2 hours', interval '2 hours'),
        ('demo_buyer_02@test.com', 'expert_a@test.com', '프리미엄 원두 커피 1kg',
         '일본 카페 체인 납품용 원두 샘플 견적',
         '일본 오사카 카페 체인에 보낼 원두 샘플과 초도 물량 300kg 견적 요청입니다. 식품 표시사항, 원산지 증명, 항공/해상 운임을 함께 비교해 주세요.',
         '일본 오사카', 10, 'approve', interval '1 day', interval '6 hours'),
        ('demo_buyer_03@test.com', 'expert_a@test.com', '친환경 패키지 박스 50세트',
         'EU 납품용 친환경 포장재 단가 검토',
         '독일 바이어가 FSC 인증 포장재를 요구합니다. 5,000세트 기준 단가, 인증서 제공 가능 여부, 납품 리드타임을 확인하고 싶습니다.',
         '독일 함부르크', 21, 'approve', interval '3 days', interval '1 day'),
        ('demo_buyer_04@test.com', 'expert_a@test.com', '스테인리스 텀블러 500ml',
         '화장품 샘플 키트 동봉 사은품 견적',
         '동남아 전시회에서 배포할 샘플 키트용 사은품 견적입니다. 예산 초과 여부와 현지 반입 제한 사항까지 검토해 주세요.',
         '태국 방콕', 7, 'reject', interval '5 days', interval '4 days'),
        ('demo_buyer_01@test.com', 'choi@test.com', null,
         'HS코드 사전심사 컨설팅 견적',
         '복합 소재 제품의 HS코드 분류가 애매해서 사전심사 컨설팅 견적이 필요합니다. 예상 소요 기간과 준비 서류를 알고 싶습니다.',
         '서울', 12, 'requesting', interval '7 days', interval '7 days')
) as e(requester_email, receiver_email, product_title, title, content, location, deadline_after, status, created_ago, updated_ago)
join tbl_member requester on requester.member_email = e.requester_email
join tbl_member receiver on receiver.member_email = e.receiver_email
left join lateral (
    select p.id
    from tbl_post p
    where p.title = e.product_title
      and p.post_status = 'active'
    order by p.created_datetime desc, p.id desc
    limit 1
) product on true
where not exists (
    select 1
    from tbl_estimation existing
    where existing.title = e.title
);

insert into tbl_estimation_tag (tag_name)
values
    ('수출견적'),
    ('통관'),
    ('식품인증'),
    ('친환경포장'),
    ('물류비교'),
    ('HS코드')
on conflict (tag_name) do nothing;

insert into tbl_estimation_tag_rel (estimation_id, tag_id)
select est.id, tag.id
from (
    values
        ('베트남 판촉용 텀블러 1,000개 수출 견적', '수출견적'),
        ('베트남 판촉용 텀블러 1,000개 수출 견적', '물류비교'),
        ('일본 카페 체인 납품용 원두 샘플 견적', '식품인증'),
        ('일본 카페 체인 납품용 원두 샘플 견적', '통관'),
        ('EU 납품용 친환경 포장재 단가 검토', '친환경포장'),
        ('HS코드 사전심사 컨설팅 견적', 'HS코드')
) as r(estimation_title, tag_name)
join tbl_estimation est on est.title = r.estimation_title
join tbl_estimation_tag tag on tag.tag_name = r.tag_name
where not exists (
    select 1
    from tbl_estimation_tag_rel existing
    where existing.estimation_id = est.id
      and existing.tag_id = tag.id
);

-- ------------------------------------------------------------
-- 3. Admin page data: reports and visible status variety
-- ------------------------------------------------------------

update tbl_member
set member_status = 'inactive',
    updated_datetime = now() - interval '2 days'
where member_email = 'demo_buyer_04@test.com';

insert into tbl_report (reporter_id, target_id, target_type, reason, status, created_datetime, updated_datetime)
select reporter.id, target.id, r.target_type::report_target_type, r.reason, r.status::report_status,
       now() - r.created_ago, now() - r.updated_ago
from (
    values
        ('demo_buyer_01@test.com', 'post', '친환경 포장재 EU 납품 문의 증가',
         '홍보성 게시글로 보여 검토 요청', 'pending', interval '3 hours', interval '3 hours'),
        ('demo_buyer_02@test.com', 'post', '화장품 샘플 통관 서류 준비',
         '동일 내용 반복 게시 의심', 'applied', interval '2 days', interval '1 day'),
        ('demo_buyer_03@test.com', 'member', 'demo_buyer_04@test.com',
         '거래 응답 지연 및 연락 두절 신고', 'rejected', interval '4 days', interval '3 days')
) as r(reporter_email, target_type, target_key, reason, status, created_ago, updated_ago)
join tbl_member reporter on reporter.member_email = r.reporter_email
join lateral (
    select p.id
    from tbl_post p
    where r.target_type = 'post'
      and p.title = r.target_key
    union all
    select m.id
    from tbl_member m
    where r.target_type = 'member'
      and m.member_email = r.target_key
) target on true
where not exists (
    select 1
    from tbl_report existing
    where existing.reporter_id = reporter.id
      and existing.target_id = target.id
      and existing.target_type = r.target_type::report_target_type
      and existing.reason = r.reason
);

-- Quick verification queries for presenters.
-- select member_email, member_status, member_role from tbl_member where member_email like 'demo_buyer_%@test.com' or member_email = 'expert_a@test.com';
-- select title, status, created_datetime from tbl_estimation where receiver_id = (select id from tbl_member where member_email = 'expert_a@test.com') order by created_datetime desc;
-- select target_type, reason, status from tbl_report order by created_datetime desc limit 10;
