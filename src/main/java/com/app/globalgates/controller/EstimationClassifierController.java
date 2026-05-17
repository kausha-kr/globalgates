package com.app.globalgates.controller;

import com.app.globalgates.domain.EstimationClassifierResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.Map;

@RestController
@Slf4j
@RequestMapping("/api/ai/estimations")
public class EstimationClassifierController {
    private final WebClient webClient;

    public EstimationClassifierController(
            WebClient.Builder webClientBuilder,
            @Value("${ai.fastapi.base-url:http://127.0.0.1:8000}") String fastApiBaseUrl
    ) {
        this.webClient = webClientBuilder.baseUrl(fastApiBaseUrl).build();
    }

    @PostMapping("/classify")
    public Mono<EstimationClassifierResponse> classify(@RequestBody Map<String, Object> body) {
        log.info("estimation classify request: {}", body);

        return webClient.post()
                .uri("/estimation/estimation-regist")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(body)
                .retrieve()
                .bodyToMono(EstimationClassifierResponse.class)
                .timeout(Duration.ofSeconds(8))
                .onErrorResume(error -> {
                    log.warn("estimation classify failed", error);
                    return Mono.just(EstimationClassifierResponse.unavailable("AI 서버 연결에 실패했습니다."));
                });
    }
}
