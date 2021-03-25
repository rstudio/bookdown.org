---
title: "HTTP testing in R"
author: "Scott Chamberlain, Maëlle Salmon"
date: "2021-03-22"
tags: [Package, Unit Test]
link: "https://books.ropensci.org/http-testing/"
length_weight: "0%"
pinned: false
---

Are you working on a R package accessing resources on the web, be it a cat facts API, a scientific data source or your system for Customer relationship management?
As for all other packages, appropriate unit testing can make your code more robust.
The unit testing of a package interacting with web resources, however, brings special challenges:
dependence of tests on a good internet connection, testing in the absence of authentication secrets, etc.
Having tests fail due to resources being down or slow, during development or on CRAN, means a time loss for everyone involved (slower development, ...
