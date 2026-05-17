package com.app.globalgates.controller;

import com.app.globalgates.auth.CustomUserDetails;
import com.app.globalgates.dto.EstimationExpertDTO;
import com.app.globalgates.service.EstimationService;
import com.app.globalgates.service.S3Service;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.io.IOException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@Slf4j
@RequestMapping("/api/ai/recommendation")
public class AiRecommendationController {
    private static final ParameterizedTypeReference<Map<String, Object>> MAP_RESPONSE_TYPE =
            new ParameterizedTypeReference<>() {
            };

    private final WebClient webClient;
    private final EstimationService estimationService;
    private final S3Service s3Service;

    public AiRecommendationController(
            WebClient.Builder webClientBuilder,
            EstimationService estimationService,
            S3Service s3Service,
            @Value("${ai.fastapi.base-url:http://127.0.0.1:8000}") String fastApiBaseUrl
    ) {
        this.webClient = webClientBuilder.baseUrl(fastApiBaseUrl).build();
        this.estimationService = estimationService;
        this.s3Service = s3Service;
    }

    @GetMapping("/experts")
    public Mono<Map<String, Object>> recommendExperts(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestParam(defaultValue = "8") int topN
    ) {
        int limit = normalizeTopN(topN);
        return requestRecommendation(buildPayload(userDetails, null, limit), userDetails, limit);
    }

    @PostMapping("/experts")
    public Mono<Map<String, Object>> recommendExperts(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody(required = false) Map<String, Object> body
    ) {
        int limit = normalizeTopN(parseTopN(body != null ? body.get("topN") : null, 8));
        return requestRecommendation(buildPayload(userDetails, body, limit), userDetails, limit);
    }

    private Mono<Map<String, Object>> requestRecommendation(Map<String, Object> payload,
                                                            CustomUserDetails userDetails,
                                                            int topN) {
        log.info("AI expert recommendation request: {}", payload);

        return webClient.post()
                .uri("/recommendation/experts")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(payload)
                .retrieve()
                .bodyToMono(MAP_RESPONSE_TYPE)
                .timeout(Duration.ofSeconds(8))
                .onErrorResume(error -> {
                    log.warn("AI expert recommendation failed. Falling back to real expert members.", error);
                    Map<String, Object> fallback = new LinkedHashMap<>();
                    fallback.put("status", "ai_unavailable");
                    fallback.put("message", "AI 추천 기준을 불러오지 못해 실제 전문가 목록 기준으로 추천합니다.");
                    return Mono.just(fallback);
                })
                .map(aiResponse -> buildRealExpertResponse(aiResponse, userDetails, topN));
    }

    private Map<String, Object> buildRealExpertResponse(Map<String, Object> aiResponse,
                                                        CustomUserDetails userDetails,
                                                        int topN) {
        List<Map<String, Object>> recommendations = new ArrayList<>();
        Long loginMemberId = userDetails != null ? userDetails.getId() : null;

        try {
            List<EstimationExpertDTO> experts = estimationService.getExpertsForRequest(1, loginMemberId, null);
            experts.stream()
                    .limit(topN)
                    .forEach(expert -> recommendations.add(toRecommendation(expert)));
        } catch (RuntimeException error) {
            log.warn("real expert recommendation lookup failed", error);
        }

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("recommendations", recommendations);
        response.put("status", recommendations.isEmpty() ? "empty" : "ok");
        response.put("source", "real_expert_members");
        response.put("message", recommendations.isEmpty()
                ? "추천 가능한 실제 전문가가 없습니다."
                : "실제 등록된 전문가 회원을 기준으로 추천했습니다.");
        if (aiResponse != null && aiResponse.get("metrics") != null) {
            response.put("metrics", aiResponse.get("metrics"));
        }
        return response;
    }

    private Map<String, Object> toRecommendation(EstimationExpertDTO expert) {
        Map<String, Object> recommendation = new LinkedHashMap<>();
        recommendation.put("id", expert.getId());
        recommendation.put("memberId", expert.getId());
        recommendation.put("memberName", expert.getMemberName());
        recommendation.put("memberNickname", expert.getMemberNickname());
        recommendation.put("memberHandle", expert.getMemberHandle());
        recommendation.put("memberEmail", expert.getMemberEmail());
        recommendation.put("memberProfileFileName", toPresignedUrlOrOriginal(expert.getMemberProfileFileName()));
        recommendation.put("profileUrl", "/mypage?memberId=" + expert.getId());
        recommendation.put("matchReason", "개인 수출입 정보 기반 전문가 추천");
        return recommendation;
    }

    private String toPresignedUrlOrOriginal(String filePath) {
        if (filePath == null || filePath.isBlank()) {
            return filePath;
        }

        try {
            return s3Service.getPresignedUrl(filePath, Duration.ofMinutes(10));
        } catch (IOException e) {
            log.warn("AI expert recommendation presigned URL failed. filePath={}", filePath, e);
            return filePath;
        }
    }

    private Map<String, Object> buildPayload(CustomUserDetails userDetails, Map<String, Object> body, int topN) {
        Map<String, Object> payload = new LinkedHashMap<>();
        if (body != null) {
            payload.putAll(body);
        }

        payload.put("topN", normalizeTopN(topN));
        if (userDetails != null) {
            payload.putIfAbsent("userId", userDetails.getId());
            payload.putIfAbsent("userRegion", defaultText(userDetails.getMemberRegion(), "Korea"));
            payload.putIfAbsent("interestCategory1", roleCategory(userDetails));
            payload.putIfAbsent("interestCategory2", "logistics");
            payload.putIfAbsent("interestTags", buildInterestTags(userDetails));
        } else {
            payload.putIfAbsent("userRegion", "Korea");
            payload.putIfAbsent("interestCategory1", "logistics");
            payload.putIfAbsent("interestCategory2", "daily_goods");
            payload.putIfAbsent("interestTags", "export import customs logistics trade");
        }
        return payload;
    }

    private int normalizeTopN(int topN) {
        return Math.max(1, Math.min(topN, 10));
    }

    private int parseTopN(Object value, int fallback) {
        if (value instanceof Number number) {
            return number.intValue();
        }
        if (value instanceof String text) {
            try {
                return Integer.parseInt(text);
            } catch (NumberFormatException ignored) {
                return fallback;
            }
        }
        return fallback;
    }

    private String roleCategory(CustomUserDetails userDetails) {
        if (userDetails.getMemberRole() == null) {
            return "logistics";
        }
        return switch (userDetails.getMemberRole()) {
            case EXPERT -> "logistics";
            case BUSINESS -> "daily_goods";
            case ADMIN -> "software";
        };
    }

    private String buildInterestTags(CustomUserDetails userDetails) {
        String bio = defaultText(userDetails.getMemberBio(), "");
        String region = defaultText(userDetails.getMemberRegion(), "Korea");
        String role = userDetails.getMemberRole() != null ? userDetails.getMemberRole().getValue() : "business";
        return String.join(" ", "export", "import", "customs", "logistics", region, role, bio).trim();
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
