---
title: "Introduction to the Doom Repository"
author: "Robert Ness"
date: "2025-05-12T21:28:35Z"
tags: [Network]
link: "https://bookdown.org/robertness/doom_tour/"
length_weight: "8.6%"
pinned: false
---

Robert Ness This tour examines Linux DOOM 1.10’s architecture, from its build system and platform abstraction layers through its core engine components: memory management, resource loading, rendering, game logic, physics, AI, UI, sound, and networking. The next steps examine how DOOM initializes, starting with the build system and following through to the main entry point. This Makefile compiles DOOM for Linux, building object files in linux/ and linking them with X11, networking, and math libraries. The code is currently Linux-only but designed to be portable. The rendering model uses ...
