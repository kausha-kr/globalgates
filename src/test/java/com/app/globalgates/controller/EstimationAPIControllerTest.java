package com.app.globalgates.controller;

import com.app.globalgates.auth.CustomUserDetails;
import com.app.globalgates.dto.EstimationDTO;
import com.app.globalgates.dto.MemberDTO;
import com.app.globalgates.service.EstimationService;
import com.app.globalgates.service.S3Service;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class EstimationAPIControllerTest {

    @Mock
    private EstimationService estimationService;

    @Mock
    private S3Service s3Service;

    @InjectMocks
    private EstimationAPIController estimationAPIController;

    @Test
    void write_overridesRequesterIdWithAuthenticatedMember() {
        EstimationDTO request = EstimationDTO.builder()
                .requesterId(999L)
                .receiverId(22L)
                .productId(31L)
                .title("팝업 스토어 패키지 제작")
                .content("패키지 3종과 인쇄 원본이 필요합니다.")
                .build();

        MemberDTO loginMember = new MemberDTO();
        loginMember.setId(7L);
        CustomUserDetails userDetails = new CustomUserDetails(loginMember, "member@example.com");

        estimationAPIController.write(request, userDetails);

        ArgumentCaptor<EstimationDTO> captor = ArgumentCaptor.forClass(EstimationDTO.class);
        verify(estimationService).write(captor.capture());
        assertEquals(7L, captor.getValue().getRequesterId());
        assertEquals(22L, captor.getValue().getReceiverId());
        assertEquals(31L, captor.getValue().getProductId());
    }

    @Test
    void write_rejectsUnauthenticatedRequestBeforeSaving() {
        EstimationDTO request = EstimationDTO.builder()
                .requesterId(999L)
                .receiverId(22L)
                .title("인증 없는 요청")
                .build();

        assertThrows(AccessDeniedException.class, () -> estimationAPIController.write(request, null));
        verify(estimationService, never()).write(request);
    }
}
