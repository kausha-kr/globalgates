-- Keep member profile columns aligned with MemberMapper and OAuthMapper.
alter table tbl_member
    add column if not exists member_country varchar(255);

alter table tbl_member
    add column if not exists member_language varchar(255);
