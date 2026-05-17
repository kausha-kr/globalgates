package com.app.globalgates.controller.admin;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@Slf4j
@RequestMapping({"/api/admin/ai", "/api/ai/admin"})
public class AdminAiRegressionController {
    private final WebClient webClient;
    private static final ParameterizedTypeReference<Map<String, Object>> MAP_RESPONSE_TYPE =
            new ParameterizedTypeReference<>() {
            };

    public AdminAiRegressionController(
            WebClient.Builder webClientBuilder,
            @Value("${ai.fastapi.base-url:http://127.0.0.1:8000}") String fastApiBaseUrl
    ) {
        this.webClient = webClientBuilder.baseUrl(fastApiBaseUrl).build();
    }

    @PostMapping("/revenue/predict")
    public Mono<Map<String, Object>> predictRevenue(@RequestBody Map<String, Object> body) {
        log.info("admin revenue prediction request: {}", body);

        return webClient.post()
                .uri("/regression/predict")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(body)
                .retrieve()
                .bodyToMono(MAP_RESPONSE_TYPE)
                .timeout(Duration.ofSeconds(8))
                .onErrorResume(error -> {
                    log.warn("admin revenue prediction failed", error);
                    Map<String, Object> fallback = new LinkedHashMap<>();
                    fallback.put("expectedMonthlyRevenue", 0);
                    fallback.put("status", "unavailable");
                    fallback.put("message", "AI 서버 연결에 실패했습니다.");
                    return Mono.just(fallback);
                });
    }
}

