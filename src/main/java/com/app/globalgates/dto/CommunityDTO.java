package com.app.globalgates.dto;

import com.app.globalgates.domain.CommunityVO;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.io.Serializable;

@Getter
@Setter
@ToString
@EqualsAndHashCode(of = "id")
@NoArgsConstructor
public class CommunityDTO implements Serializable {

    private Long id;
    private Long creatorId;
    @Size(min = 3, max = 30, message = "커뮤니티 이름은 3~30자여야 합니다.")
    private String communityName;
    @Size(max = 500, message = "설명은 500자 이하여야 합니다.")
    private String description;
    private String communityStatus;
    private Long categoryId;
    private String categoryName;
    private int memberCount;
    private int postCount;
    private String coverFilePath;
    private String createdDatetime;
    private String updatedDatetime;
    private boolean isJoined;
    private String myRole;

    public CommunityVO toCommunityVO() {
        return CommunityVO.builder()
                .id(id)
                .creatorId(creatorId)
                .communityName(communityName)
                .description(description)
                .communityStatus(communityStatus)
                .categoryId(categoryId)
                .build();
    }
}
