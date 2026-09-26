package com.app.globalgates.aop;


import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
@Aspect
@Configuration
@Slf4j
public class LogAspect {
    @Around("logStatusAnnotated()")
    public Object around(ProceedingJoinPoint joinPoint) throws Throwable{
        String methodName = joinPoint.getSignature().getName();
        String className = joinPoint.getTarget().getClass().getSimpleName();
        log.info("▶ [{}#{}] 호출", className, methodName);
        Object result = joinPoint.proceed();
        log.info("◀ [{}#{}] 완료", className, methodName);
        return result;
    }

    @AfterReturning(value = "logStatusWithReturnAnnotated()", returning = "returnValue")
    public void afterReturning(JoinPoint joinPoint, Object returnValue) throws IOException {
        String methodName = joinPoint.getSignature().getName();
        String className = joinPoint.getTarget().getClass().getSimpleName();
        log.info("▶ [{}#{}] 호출", className, methodName);
        log.info("◀ [{}#{}] 완료", className, methodName);
    }

    @Pointcut("@annotation(com.app.globalgates.aop.annotation.LogStatus)")
    public void logStatusAnnotated(){}

    @Pointcut("@annotation(com.app.globalgates.aop.annotation.LogStatusWithReturn)")
    public void logStatusWithReturnAnnotated(){}
}

















