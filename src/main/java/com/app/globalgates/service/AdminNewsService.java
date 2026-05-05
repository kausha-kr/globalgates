package com.app.globalgates.service;

import com.app.globalgates.common.enumeration.NewsType;
import com.app.globalgates.dto.NewsDTO;
import com.app.globalgates.repository.AdminNewsDAO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminNewsService {
    private final AdminNewsDAO adminNewsDAO;

    public List<NewsDTO> getAdminNews() {
        return adminNewsDAO.findAll();
    }

    @Transactional
    public void createAdminNews(NewsDTO newsDTO) {
        newsDTO.setNewsType(NewsType.EMERGENCY);
        adminNewsDAO.save(newsDTO);
    }

    @Transactional
    public void createAdminGeneralNews(NewsDTO newsDTO) {
        newsDTO.setNewsType(NewsType.GENERAL);
        adminNewsDAO.save(newsDTO);
    }

    @Transactional
    public int updateAdminNews(NewsDTO newsDTO) {
        newsDTO.setNewsType(NewsType.EMERGENCY);
        return adminNewsDAO.update(newsDTO);
    }

    @Transactional
    public int deleteAdminNews(Long id) {
        return adminNewsDAO.delete(id);
    }
}
