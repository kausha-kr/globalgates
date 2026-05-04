package com.app.globalgates.service;

import com.app.globalgates.common.enumeration.NewsType;
import com.app.globalgates.common.enumeration.Status;
import com.app.globalgates.domain.PostVO;
import com.app.globalgates.dto.NewsDTO;
import com.app.globalgates.dto.PostDTO;
import com.app.globalgates.repository.AdminNewsDAO;
import com.app.globalgates.repository.PostDAO;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminNewsService {
    private final AdminNewsDAO adminNewsDAO;
    private final PostDAO postDAO;

    public List<NewsDTO> getAdminNews() {
        return adminNewsDAO.findAll();
    }

    // 메인 피드(view_post_feed)는 tbl_post에서 비롯되므로,
    // 속보 뉴스 카드를 노출하려면 시드 게시글을 함께 만들어 tbl_news.post_id로 연결해야 한다.
    @Transactional
    @CacheEvict(value = "post:list", allEntries = true)
    public void createAdminNews(NewsDTO newsDTO) {
        newsDTO.setNewsType(NewsType.EMERGENCY);

        PostDTO seed = new PostDTO();
        seed.setMemberId(newsDTO.getAdminId());
        seed.setPostStatus(Status.ACTIVE);
        seed.setPostTitle(newsDTO.getNewsTitle());
        seed.setPostContent(newsDTO.getNewsContent());
        postDAO.save(seed);

        newsDTO.setPostId(seed.getId());
        adminNewsDAO.save(newsDTO);
    }

    @Transactional
    @CacheEvict(value = "post:list", allEntries = true)
    public int updateAdminNews(NewsDTO newsDTO) {
        newsDTO.setNewsType(NewsType.EMERGENCY);
        int affected = adminNewsDAO.update(newsDTO);

        Long postId = adminNewsDAO.findPostIdById(newsDTO.getId());
        if (postId != null) {
            PostVO seed = PostVO.builder()
                    .id(postId)
                    .postTitle(newsDTO.getNewsTitle())
                    .postContent(newsDTO.getNewsContent())
                    .build();
            postDAO.setPost(seed);
        }
        return affected;
    }

    @Transactional
    @CacheEvict(value = "post:list", allEntries = true)
    public int deleteAdminNews(Long id) {
        Long postId = adminNewsDAO.findPostIdById(id);
        int affected = adminNewsDAO.delete(id);
        if (postId != null) {
            postDAO.delete(postId);
        }
        return affected;
    }
}
