package com.app.globalgates.domain;

import lombok.Data;

import java.util.List;

@Data
public class EstimationClassifierResponse {
    private String isEstimation;
    private String prediction;
    private Double probability;
    private List<String> classes;
    private String status;
    private String message;

    public static EstimationClassifierResponse unavailable(String message) {
        EstimationClassifierResponse response = new EstimationClassifierResponse();
        response.setIsEstimation("unavailable");
        response.setPrediction("unavailable");
        response.setProbability(null);
        response.setClasses(List.of("approve", "reject"));
        response.setStatus("unavailable");
        response.setMessage(message);
        return response;
    }
}
