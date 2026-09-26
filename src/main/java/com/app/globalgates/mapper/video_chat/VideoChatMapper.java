package com.app.globalgates.mapper.video_chat;

import com.app.globalgates.domain.video_chat.VideoChatVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Optional;

@Mapper
public interface VideoChatMapper {
//    채팅방이 있는지 조회
    public Optional<VideoChatVO> selectSession(@Param("conversationId") Long conversationId);
//    채팅방 생성
    public void insertVideoSession(VideoChatVO videoChatVO);
//    채팅방 통화 종료 반영
    public void updateSessionEnd(@Param("conversationId") Long conversationId);

}
