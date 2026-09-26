# 견적 등록 화면 React 전환 기록

## 왜 이 화면을 골랐나

견적 등록 화면은 전문가 검색, 상품 조회, 폼 입력, 태그, AI 검토, 최종 저장이 한 흐름에 들어 있습니다. 기존 JavaScript에서는 이 상태들이 여러 전역 변수와 DOM 속성에 나뉘어 있었고, 입력이 바뀌었을 때 AI 결과를 언제 무효화해야 하는지 따라가기 어려웠습니다. 단순히 화면 모양만 React로 옮기기보다 상태를 나누는 이유를 보여 주기에 적합하다고 판단했습니다.

## 바꾼 구조

- API 호출은 `src/api/estimations.js`에 모았습니다.
- 검증, 서버 payload 변환, AI 결과 문구는 `src/domain/estimationForm.js`의 순수 함수로 분리했습니다.
- 화면에서는 선택한 전문가와 상품, 폼 값, AI 검토, 저장 상태를 각각 관리합니다.
- 전문가가 바뀌면 이전 상품 선택을 지우고, 요청서가 바뀌면 이전 AI 결과도 무효화합니다.
- AI 서버가 응답하지 않거나 보완 판정을 내려도 사용자가 내용을 확인한 뒤 다시 등록할 수 있게 했습니다.

## 오류를 다룬 방식

필수 항목이 빠진 상태에서 검토나 등록을 누르면 각 입력 위치에 오류가 나타납니다. 전문가를 바꾸면 기존 상품을 그대로 보내지 않도록 상품 선택을 초기화합니다. AI 결과는 등록의 참고 정보이므로 외부 AI 서버 장애가 전체 견적 기능을 막지 않게 재확인 단계를 두었습니다.

## 확인한 결과

- Node 도메인 테스트 6개 통과
- `oxlint` 통과
- Vite 프로덕션 빌드 통과
- 데스크톱에서 전문가 선택 → 상품 선택 → 폼 작성 → AI 승인 → 등록 성공 확인
- 390×844 모바일 화면에서 메뉴, 단계, 카드가 겹치지 않는지 확인
- 브라우저 콘솔 오류 없음

## 화면 증거

### 전환 전 Thymeleaf 화면

![전환 전 견적 등록 데스크톱](evidence/estimation-register/01-before-desktop.png)

![전환 전 견적 등록 모바일](evidence/estimation-register/01-before-mobile.png)

### React 전환 후

![견적 등록 데스크톱](evidence/estimation-register/desktop.png)

![견적 등록 모바일](evidence/estimation-register/mobile.png)

별도 PostgreSQL 환경에서 로그인부터 전문가·상품 조회, 저장, 전문가 승인, 알림 생성까지 실제 API 흐름도 확인했습니다. 새 DB로 재현하면서 회원·구독 컬럼 누락과 마감일 타입 변환 문제를 발견했고 기준 DDL과 매퍼를 수정했습니다. 상세 결과는 `estimation-api-contract-case.md`와 `evidence/estimation-api/06-integration-result.txt`에 남겼습니다.
