package com.app.globalgates.qa;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

class StaticQaRegressionTest {

    private static String read(String path) throws IOException {
        return Files.readString(Path.of(path));
    }

    @Test
    void communityMainReportSendsReportDtoShapeAndAwaitsResponse() throws IOException {
        String script = read("src/main/resources/static/js/community/event.js");

        assertThat(script).contains("reporterId");
        assertThat(script).contains("targetId");
        assertThat(script).contains("targetType: \"post\"");
        assertThat(script).contains("if (!res.ok)");
    }

    @Test
    void chatServiceAcceptsEmptySuccessfulResponses() throws IOException {
        String script = read("src/main/resources/static/js/chat/service.js");

        assertThat(script).contains("const text = await response.text()");
        assertThat(script).contains("text ? JSON.parse(text) : null");
    }

    @Test
    void exploreNewsListRendersAllAdminNewsFields() throws IOException {
        String script = read("src/main/resources/static/js/explore/layout.js");

        assertThat(script).contains("news.newsCategory");
        assertThat(script).contains("news.newsType");
        assertThat(script).contains("news.newsContent");
        assertThat(script).contains("news.newsSourceUrl");
    }

    @Test
    void bookmarkPageCanMoveNewsBookmarksToFolders() throws IOException {
        String service = read("src/main/resources/static/js/bookmark/service.js");
        String event = read("src/main/resources/static/js/bookmark/event.js");

        assertThat(service).contains("getByMemberAndNews");
        assertThat(service).contains("addNews");
        assertThat(service).contains("moveNewsFolder");
        assertThat(event).contains("activeShareBookmarkType");
        assertThat(event).contains("BookmarkService.moveNewsFolder");
    }

    @Test
    void estimationSchemaAndMapperStayCompatible() throws IOException {
        String ddl = read("src/main/resources/sql/globalgates_full_ddl.sql");
        String mapper = read("src/main/resources/mapper/estimationMapper.xml");

        assertThat(ddl).contains("member_country   varchar(255)");
        assertThat(ddl).contains("member_language  varchar(255)");
        assertThat(ddl).contains("billing_key      varchar(255)");
        assertThat(ddl).contains("amount           bigint");
        assertThat(mapper).contains("cast(#{deadLine} as date)");
    }

    @Test
    void authenticationLogsDoNotExposeCredentialsOrTokens() throws IOException {
        String filter = read("src/main/java/com/app/globalgates/auth/AuthenticationFilter.java");
        String controller = read("src/main/java/com/app/globalgates/controller/member/MemberAPIController.java");
        String aspect = read("src/main/java/com/app/globalgates/aop/LogAspect.java");
        String settingController = read("src/main/java/com/app/globalgates/controller/setting/SettingController.java");
        String settingTemplate = read("src/main/resources/templates/setting/setting.html");
        String mapScript = read("src/main/resources/static/js/setting/google-map.js");

        assertThat(filter).doesNotContain("accessToken: {}", "Token found: {}", "Authentication Success: {}");
        assertThat(controller).doesNotContain("memberDTO: {}", "authentication: {}", "e.printStackTrace()");
        assertThat(aspect).doesNotContain("joinPoint.getArgs()", "Return: {}");
        assertThat(settingController).doesNotContain("model.asMap()");
        assertThat(settingTemplate).doesNotContain("AIza");
        assertThat(mapScript).doesNotContain("AIza");
    }
}
