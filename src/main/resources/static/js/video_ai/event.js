document.addEventListener('DOMContentLoaded', () => {
    'use strict';

    // 1. 샘플 회의 데이터
    const meetings = [
        {
            id: 'rec-001',
            title: '프로젝트 킥오프 회의',
            date: '2024-03-15',
            handle: '@kim_pm',
            audioUrl: '',
            summaryTitle: '프로젝트 킥오프 회의 요약',
            summaryText: '1. 프로젝트 일정 확인\n- 3월 말까지 MVP 완성 목표\n- QA 기간 1주일 추가 필요\n\n2. 디자인 리뷰\n- 메인 페이지 UI 수정 사항 논의\n- 모바일 반응형 대응 필요\n\n3. 다음 회의\n- 3월 20일 오전 10시'
        },
        {
            id: 'rec-002',
            title: 'Spring Security 강의',
            date: '2024-03-10',
            handle: '@lee_dev',
            audioUrl: '',
            summaryTitle: 'Spring Security 강의 요약',
            summaryText: 'Spring Boot 보안 설정 강의\n\n1. JWT 토큰 기반 인증\n2. Spring Security 필터 체인\n3. CORS 설정 방법\n4. CSRF 보호 전략'
        },
        {
            id: 'rec-003',
            title: '기술 면접 인터뷰',
            date: '2024-03-08',
            handle: '@park_hr',
            audioUrl: '',
            summaryTitle: '기술 면접 인터뷰 요약',
            summaryText: '후보자 기술 면접 내용\n\n- Java/Spring 경력 3년\n- MSA 프로젝트 경험\n- 커뮤니케이션 우수\n\n결론: 2차 면접 진행 권장'
        }
    ];

    // 2. 상태 관리 변수
    let currentMeeting = null;
    let expandedMeetingId = null;

    // 3. DOM 요소 참조
    const fab = document.getElementById('vaiFab');
    const dropdown = document.getElementById('vaiDropdown');
    const meetingToggle = document.getElementById('vaiMeetingToggle');
    const meetingChevron = document.getElementById('vaiMeetingChevron');
    const meetingList = document.getElementById('vaiMeetingList');

    const audioPanel = document.getElementById('vaiAudioPanel');
    const audioPlayer = document.getElementById('vaiAudioPlayer');
    const audioTitle = document.getElementById('vaiAudioTitle');
    const audioBack = document.getElementById('vaiAudioBack');
    const audioClose = document.getElementById('vaiAudioClose');

    const summaryPanel = document.getElementById('vaiSummaryPanel');
    const summaryTitle = document.getElementById('vaiSummaryTitle');
    const summaryText = document.getElementById('vaiSummaryText');
    const summaryBack = document.getElementById('vaiSummaryBack');
    const summaryClose = document.getElementById('vaiSummaryClose');

    const chatPanel = document.getElementById('vaiChatPanel');
    const chatTitle = document.getElementById('vaiChatTitle');
    const chatMessages = document.getElementById('vaiChatMessages');
    const chatTextarea = document.querySelector('.vai-chat-textarea');
    const chatSendBtn = document.getElementById('vaiChatSend');
    const chatBack = document.getElementById('vaiChatBack');
    const chatClose = document.getElementById('vaiChatClose');

    // 4. 회의 목록 렌더링
    function renderMeetings() {
        let html = '';
        for (let i = 0; i < meetings.length; i++) {
            const m = meetings[i];
            html +=
                '<div class="vai-meeting-item" data-id="' + m.id + '">' +
                '  <div class="vai-meeting-row">' +
                '    <div class="vai-meeting-info">' +
                '      <span class="vai-meeting-title">' + m.title + '</span>' +
                '      <div class="vai-meeting-meta">' +
                '        <span>' + m.date + '</span>' +
                '        <span class="vai-meeting-dot">&middot;</span>' +
                '        <span class="vai-meeting-handle">' + m.handle + '</span>' +
                '      </div>' +
                '    </div>' +
                '    <div class="vai-meeting-chevron">' +
                '      <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">' +
                '        <path d="M8.59 16.59L13.17 12 8.59 7.41 10 6l6 6-6 6-1.41-1.41z"></path>' +
                '      </svg>' +
                '    </div>' +
                '  </div>' +
                '  <div class="vai-sub-actions">' +
                '    <div class="vai-sub-action" data-action="audio">' +
                '      <div class="vai-sub-action-icon">' +
                '        <svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor"><path d="M8 5v14l11-7z"></path></svg>' +
                '      </div>' +
                '      <span class="vai-sub-action-label">오디오 재생</span>' +
                '    </div>' +
                '    <div class="vai-sub-action" data-action="summary">' +
                '      <div class="vai-sub-action-icon">' +
                '        <svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor"><path d="M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zM6 20V4h7v5h5v11H6zm2-6h8v2H8v-2zm0-4h8v2H8v-2zm0 8h5v2H8v-2z"></path></svg>' +
                '      </div>' +
                '      <span class="vai-sub-action-label">요약본 보기</span>' +
                '    </div>' +
                '    <div class="vai-sub-action" data-action="chat">' +
                '      <div class="vai-sub-action-icon">' +
                '        <svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor"><path d="M20.93 11.94c0-4.6-3.95-8.42-8.93-8.42s-8.93 3.82-8.93 8.42c-.01.83.13 1.6.33 2.29.1.34.21.65.3.94.1.3.18.55.25.79.13.48.19.94.11 1.46-.08.6-.27 1.23-.58 1.91 1.3.39 2.62.06 4.12-.61l.47-.21.44.25c1.1.61 1.87 1.11 3.49 1.11 4.98 0 8.93-3.63 8.93-8.18z"></path></svg>' +
                '      </div>' +
                '      <span class="vai-sub-action-label">AI에게 질문</span>' +
                '    </div>' +
                '  </div>' +
                '</div>';
        }
        meetingList.innerHTML = html;
        bindMeetingEvents();
    }

    // 5. ID로 회의 데이터 검색
    function findMeeting(id) {
        for (let i = 0; i < meetings.length; i++) {
            if (meetings[i].id === id) return meetings[i];
        }
        return null;
    }

    // 6. 회의 항목 클릭 이벤트 바인딩
    function bindMeetingEvents() {
        // 6-1. 회의 행 클릭시 서브액션 토글
        const rows = meetingList.querySelectorAll('.vai-meeting-row');
        rows.forEach(function (row) {
            row.addEventListener('click', function (e) {
                e.stopPropagation();
                const item = row.closest('.vai-meeting-item');
                const id = item.getAttribute('data-id');
                const subActions = item.querySelector('.vai-sub-actions');
                const chevron = item.querySelector('.vai-meeting-chevron');

                if (expandedMeetingId === id) {
                    subActions.classList.remove('open');
                    chevron.classList.remove('expanded');
                    expandedMeetingId = null;
                    currentMeeting = null;
                } else {
                    collapseAllSubActions(true);
                    subActions.classList.add('open');
                    chevron.classList.add('expanded');
                    expandedMeetingId = id;
                    currentMeeting = findMeeting(id);
                }
            });
        });

        // 6-2. 서브액션 버튼 클릭시 패널 열기
        const subActions = meetingList.querySelectorAll('.vai-sub-action');
        subActions.forEach(function (btn) {
            btn.addEventListener('click', function (e) {
                e.stopPropagation();
                const action = btn.getAttribute('data-action');
                if (!currentMeeting) return;

                if (action === 'audio') {
                    openAudio();
                } else if (action === 'summary') {
                    openSummary();
                } else if (action === 'chat') {
                    openChat();
                }
            });
        });
    }

    // 7. 모든 서브액션 접기
    function collapseAllSubActions(instant) {
        const allSubs = meetingList.querySelectorAll('.vai-sub-actions');
        const allChevrons = meetingList.querySelectorAll('.vai-meeting-chevron');
        allSubs.forEach(function (s) {
            if (instant) s.classList.add('no-transition');
            s.classList.remove('open');
            if (instant) {
                s.offsetHeight;
                s.classList.remove('no-transition');
            }
        });
        allChevrons.forEach(function (c) { c.classList.remove('expanded'); });
        expandedMeetingId = null;
    }

    // 8. 모든 패널 닫기
    function closeAllPanels() {
        audioPanel.classList.remove('open');
        summaryPanel.classList.remove('open');
        chatPanel.classList.remove('open');
        audioPlayer.pause();
    }

    // 9. 드롭다운 포함 전체 닫기
    function closeEverything() {
        dropdown.classList.remove('open');
        meetingList.classList.remove('open');
        meetingChevron.classList.remove('expanded');
        collapseAllSubActions();
        closeAllPanels();
    }

    // 10. 패널에서 드롭다운으로 복귀
    function backToDropdown() {
        closeAllPanels();
        dropdown.classList.add('open');
    }

    // 11. FAB 버튼 클릭시 드롭다운 토글
    fab.addEventListener('click', function (e) {
        e.stopPropagation();
        if (dropdown.classList.contains('open')) {
            closeEverything();
        } else {
            closeAllPanels();
            dropdown.classList.add('open');
        }
    });

    // 12. 회의 목록 아코디언 토글
    meetingToggle.addEventListener('click', function (e) {
        e.stopPropagation();
        const isOpen = meetingList.classList.contains('open');
        if (isOpen) {
            meetingList.classList.remove('open');
            meetingChevron.classList.remove('expanded');
            collapseAllSubActions();
        } else {
            meetingList.classList.add('open');
            meetingChevron.classList.add('expanded');
        }
    });

    // 13. 오디오 패널 열기
    function openAudio() {
        audioTitle.textContent = currentMeeting.title + ' - 오디오';
        if (currentMeeting.audioUrl) {
            audioPlayer.src = currentMeeting.audioUrl;
        } else {
            audioPlayer.removeAttribute('src');
        }
        dropdown.classList.remove('open');
        closeAllPanels();
        audioPanel.classList.add('open');
    }

    // 14. 요약본 패널 열기
    function openSummary() {
        summaryTitle.textContent = currentMeeting.summaryTitle;
        summaryText.textContent = currentMeeting.summaryText;
        dropdown.classList.remove('open');
        closeAllPanels();
        summaryPanel.classList.add('open');
    }

    // 15. AI 채팅 패널 열기
    function openChat() {
        chatTitle.textContent = currentMeeting.title + ' - AI 질문';
        resetChat();
        dropdown.classList.remove('open');
        closeAllPanels();
        chatPanel.classList.add('open');
        setTimeout(function () { chatTextarea.focus(); }, 100);
    }

    // 16. 각 패널 뒤로가기 버튼
    audioBack.addEventListener('click', function (e) { e.stopPropagation(); backToDropdown(); });
    summaryBack.addEventListener('click', function (e) { e.stopPropagation(); backToDropdown(); });
    chatBack.addEventListener('click', function (e) { e.stopPropagation(); backToDropdown(); });

    // 17. 각 패널 닫기 버튼
    audioClose.addEventListener('click', function (e) { e.stopPropagation(); closeEverything(); });
    summaryClose.addEventListener('click', function (e) { e.stopPropagation(); closeEverything(); });
    chatClose.addEventListener('click', function (e) { e.stopPropagation(); closeEverything(); });

    // 18. 외부 클릭시 전체 닫기
    document.addEventListener('click', function (e) {
        const container = document.getElementById('vaiContainer');
        if (!container.contains(e.target)) {
            closeEverything();
        }
    });

    // 19. ESC 키 입력시 전체 닫기
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') closeEverything();
    });

    // 20. 채팅 초기화
    function resetChat() {
        chatMessages.innerHTML =
            '<div class="vai-chat-empty">' +
            '  <svg viewBox="0 0 24 24" width="32" height="32" fill="rgb(139,152,165)">' +
            '    <path d="M20.93 11.94c0-4.6-3.95-8.42-8.93-8.42s-8.93 3.82-8.93 8.42c-.01.83.13 1.6.33 2.29.1.34.21.65.3.94.1.3.18.55.25.79.13.48.19.94.11 1.46-.08.6-.27 1.23-.58 1.91 1.3.39 2.62.06 4.12-.61l.47-.21.44.25c1.1.61 1.87 1.11 3.49 1.11 4.98 0 8.93-3.63 8.93-8.18z"></path>' +
            '  </svg>' +
            '  <span>이 녹음에 대해 질문해보세요</span>' +
            '</div>';
    }

    // 21. 채팅 메시지 추가
    function addMessage(text, type) {
        const empty = chatMessages.querySelector('.vai-chat-empty');
        if (empty) empty.remove();

        const div = document.createElement('div');
        div.className = 'vai-msg ' + (type === 'user' ? 'vai-msg-user' : 'vai-msg-ai');
        div.textContent = text;
        chatMessages.appendChild(div);
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }

    // 22. 채팅 메시지 전송
    function sendMessage() {
        const text = chatTextarea.value.trim();
        if (!text) return;
        addMessage(text, 'user');
        chatTextarea.value = '';
        chatTextarea.style.height = 'auto';
        setTimeout(function () {
            addMessage('녹음 내용을 분석하고 있습니다...', 'ai');
        }, 800);
    }

    // 23. 채팅 전송 버튼 클릭
    chatSendBtn.addEventListener('click', function (e) { e.stopPropagation(); sendMessage(); });

    // 24. 채팅 입력창 엔터키 전송
    chatTextarea.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
    });

    // 25. 채팅 입력창 높이 자동 조절
    chatTextarea.addEventListener('input', function () {
        this.style.height = 'auto';
        this.style.height = Math.min(this.scrollHeight, 100) + 'px';
    });

    // 26. 초기 렌더링 실행
    renderMeetings();

});
