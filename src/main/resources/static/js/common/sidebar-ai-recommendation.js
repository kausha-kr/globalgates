(() => {
    const INITIAL_VISIBLE_COUNT = 3;
    const MAX_RECOMMENDATION_COUNT = 10;

    const escapeHtml = (value) => String(value ?? "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");

    const normalizeHandle = (handle, email) => {
        if (handle) {
            return handle.startsWith("@") ? handle : `@${handle}`;
        }
        return email || "전문가 프로필";
    };

    const getDisplayName = (expert) => {
        return expert.memberNickname || expert.memberName || expert.memberHandle || "전문가";
    };

    const getProfileUrl = (expert) => {
        if (expert.profileUrl) {
            return expert.profileUrl;
        }
        const memberId = expert.memberId || expert.id;
        return memberId ? `/mypage?memberId=${encodeURIComponent(memberId)}` : "/mypage";
    };

    const renderEmpty = (list, title, subtitle) => {
        list.innerHTML = `
            <div class="suggestionItem suggestionItem--empty aiExpertFadeItem">
                <div class="suggestionProfile">
                    <span class="suggestionName">${escapeHtml(title)}</span>
                    <span class="sidebar-user-handle">${escapeHtml(subtitle)}</span>
                </div>
            </div>
        `;
    };

    const renderRecommendations = (card) => {
        const list = card.querySelector("[data-ai-expert-list]");
        const moreButton = card.querySelector("[data-ai-expert-more]");
        const recommendations = card.aiRecommendations || [];
        const expanded = card.dataset.aiExpanded === "true";
        const visibleCount = expanded ? recommendations.length : INITIAL_VISIBLE_COUNT;

        if (!Array.isArray(recommendations) || recommendations.length === 0) {
            renderEmpty(list, "추천 가능한 전문가가 없습니다.", "실제 등록된 전문가 기준으로 다시 확인해 주세요.");
            if (moreButton) moreButton.hidden = true;
            return;
        }

        list.innerHTML = recommendations.slice(0, visibleCount).map((expert, index) => {
            const name = getDisplayName(expert);
            const handle = normalizeHandle(expert.memberHandle, expert.memberEmail);
            const profileUrl = getProfileUrl(expert);
            const reason = expert.matchReason || "개인 수출입 정보 기반 전문가 추천";

            return `
                <a class="suggestionItem aiExpertSuggestionItem aiExpertFadeItem" href="${escapeHtml(profileUrl)}" style="--ai-index:${index}">
                    <div class="suggestionProfile">
                        <span class="suggestionName">${escapeHtml(name)}</span>
                        <span class="sidebar-user-handle">${escapeHtml(handle)}</span>
                        <span class="sidebar-user-handle aiExpertReason">${escapeHtml(reason)}</span>
                    </div>
                    <span class="aiExpertScoreBadge">AI</span>
                </a>
            `;
        }).join("");

        if (moreButton) {
            moreButton.hidden = recommendations.length <= INITIAL_VISIBLE_COUNT;
            moreButton.textContent = expanded ? "접기" : "더 보기";
            moreButton.setAttribute("aria-expanded", String(expanded));
        }
    };

    const loadAiExperts = async (card) => {
        const list = card.querySelector("[data-ai-expert-list]");
        if (!list) return;

        try {
            const response = await fetch(`/api/ai/recommendation/experts?topN=${MAX_RECOMMENDATION_COUNT}`, {
                method: "GET",
                headers: { "Accept": "application/json" },
                credentials: "include"
            });

            if (!response.ok) {
                throw new Error(`AI recommendation failed: ${response.status}`);
            }

            const data = await response.json();
            card.aiRecommendations = Array.isArray(data.recommendations) ? data.recommendations : [];
            renderRecommendations(card);
        } catch (error) {
            console.error(error);
            renderEmpty(list, "AI 추천을 불러오지 못했습니다.", "서버 연결 후 다시 확인해 주세요.");
            const moreButton = card.querySelector("[data-ai-expert-more]");
            if (moreButton) moreButton.hidden = true;
        }
    };

    const bindCardEvents = (card) => {
        const moreButton = card.querySelector("[data-ai-expert-more]");
        if (!moreButton) return;

        moreButton.addEventListener("click", () => {
            card.dataset.aiExpanded = card.dataset.aiExpanded === "true" ? "false" : "true";
            renderRecommendations(card);
        });
    };

    document.addEventListener("DOMContentLoaded", () => {
        document.querySelectorAll("[data-ai-expert-card]").forEach((card) => {
            bindCardEvents(card);
            loadAiExperts(card);
        });
    });
})();
