package com.app.globalgates.controller;

import com.app.globalgates.auth.CustomUserDetails;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@Slf4j
@RequestMapping("/api/ai/llm")
public class AiLlmController {
    private static final ParameterizedTypeReference<Map<String, Object>> MAP_RESPONSE_TYPE =
            new ParameterizedTypeReference<>() {
            };

    private final WebClient webClient;

    public AiLlmController(
            WebClient.Builder webClientBuilder,
            @Value("${ai.fastapi.base-url:http://127.0.0.1:8000}") String fastApiBaseUrl
    ) {
        this.webClient = webClientBuilder.baseUrl(fastApiBaseUrl).build();
    }

    @PostMapping("/chat/recommendations")
    public Mono<Map<String, Object>> recommendChatSentences(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestBody(required = false) Map<String, Object> body
    ) {
        Map<String, Object> payload = new LinkedHashMap<>();
        if (body != null) {
            payload.putAll(body);
        }
        if (userDetails != null) {
            payload.putIfAbsent("memberId", userDetails.getId());
            payload.putIfAbsent("memberRole", userDetails.getMemberRole() != null ? userDetails.getMemberRole().getValue() : null);
        }

        return webClient.post()
                .uri("/llm/chat/recommendations")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(payload)
                .retrieve()
                .bodyToMono(MAP_RESPONSE_TYPE)
                .timeout(Duration.ofSeconds(15))
                .onErrorResume(error -> {
                    log.warn("AI LLM chat recommendation failed", error);
                    Map<String, Object> fallback = new LinkedHashMap<>();
                    fallback.put("recommendations", List.of(
                            "\uD655\uC778\uD588\uC2B5\uB2C8\uB2E4. \uC790\uC138\uD788 \uC0B4\uD3B4\uBCF4\uACE0 \uB2E4\uC2DC \uB9D0\uC500\uB4DC\uB9AC\uACA0\uC2B5\uB2C8\uB2E4.",
                            "\uACF5\uC720\uD574\uC8FC\uC154\uC11C \uAC10\uC0AC\uD569\uB2C8\uB2E4. \uD655\uC778 \uD6C4 \uB2F5\uBCC0\uB4DC\uB9AC\uACA0\uC2B5\uB2C8\uB2E4.",
                            "\uC88B\uC2B5\uB2C8\uB2E4. \uD544\uC694\uD55C \uB0B4\uC6A9 \uC815\uB9AC\uD574\uC11C \uB2E4\uC2DC \uC5F0\uB77D\uB4DC\uB9AC\uACA0\uC2B5\uB2C8\uB2E4."
                    ));
                    fallback.put("source", "spring_fallback");
                    fallback.put("status", "ai_unavailable");
                    fallback.put("message", "AI \uC11C\uBC84 \uC5F0\uACB0\uC774 \uC5B4\uB824\uC6CC \uAE30\uBCF8 \uCD94\uCC9C\uBB38\uC7A5\uC744 \uD45C\uC2DC\uD569\uB2C8\uB2E4.");
                    return Mono.just(fallback);
                });
    }
}
