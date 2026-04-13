package com.pet.demo.config;

import com.pet.demo.exception.CustomizeException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.ModelAndView;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@ControllerAdvice
public class CustomizeExceptionHandle {
    private static final Logger logger = LoggerFactory.getLogger(CustomizeExceptionHandle.class);

    @ExceptionHandler(Exception.class)
    ModelAndView handle(HttpServletRequest request, Throwable e, Model model,
                        HttpServletResponse response) {

            logger.error("Exception occurred: ", e);

            if(e instanceof CustomizeException){
                model.addAttribute("message",e.getMessage());
            }
            else{
                model.addAttribute("message","服务器冒烟了，稍后试试！");
            }

            return new ModelAndView("error");

    }
}
