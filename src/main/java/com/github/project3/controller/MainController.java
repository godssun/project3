package com.github.project3.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MainController {

	@GetMapping("/hello")
	public String helloWorld(){
		return "CICD test4";
	}
}