package com.app.globalgates.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class RootController {

    @GetMapping("/")
    public String redirectRootToJoin() {
        return "redirect:/member/join";
    }
}
