# 자격증명 교체 체크리스트

Git 기록에서 값은 제거했지만 이미 공개됐던 값은 다시 사용할 수 없습니다. 아래 항목은 각 서비스 콘솔에서 기존 값을 폐기하고 새 값을 발급한 뒤, 배포 환경변수만 갱신해야 합니다. 새 값은 Git이나 노션에 적지 않습니다.

## 우선 처리

- [ ] AWS access key 폐기, 새 IAM 키 발급, S3 권한 최소화
- [ ] Google Maps API key 폐기, 새 키에 HTTP referrer와 API 제한 적용
- [ ] DB 계정 비밀번호 변경 및 외부 접속 기록 확인
- [ ] JWT secret 교체 후 기존 로그인 토큰 무효화
- [ ] TLS 인증서와 private key 새로 발급

## 외부 서비스

- [ ] 메일 계정 또는 앱 비밀번호 교체
- [ ] 문자 API key와 secret 교체
- [ ] Bootpay application ID와 private key 교체
- [ ] Kakao OAuth client ID와 secret 교체
- [ ] Naver OAuth client ID와 secret 교체
- [ ] Facebook OAuth client ID와 secret 교체
- [ ] Google OAuth client ID와 secret 교체

## 교체 후 확인

- [ ] 로컬 `.env` 또는 배포 환경변수에 새 값 등록
- [ ] 로그인, 메일, 문자, 지도, 결제, 파일 업로드 기능 확인
- [ ] GitHub secret scanning 알림 확인 및 해결 처리
- [ ] AWS, Google, OAuth 공급자의 최근 사용 기록 확인
- [ ] `git grep`과 별도 secret scanner로 공개 브랜치 재검사

## 현재 상태

- 공개 `master`와 `codex/react-refactor`는 정리된 이력으로 교체 완료
- GitHub에서 새로 복제한 이력은 루트 커밋부터 시작
- 원본 이력은 로컬 복구 번들에만 보관하며 다시 푸시하지 않음
- 공급자 콘솔에서 수행하는 폐기·재발급은 계정 소유자 확인 필요
