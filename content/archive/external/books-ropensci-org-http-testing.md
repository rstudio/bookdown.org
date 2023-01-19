---
title: "HTTP testing in R"
author: "Scott Chamberlain, Maëlle Salmon"
date: "2023-01-17"
tags: [Package, Unit Test]
link: "https://books.ropensci.org/http-testing/"
length_weight: "0%"
repo: "ropensci-books/http-testing"
pinned: false
---

Best practice and tips for testing packages interfacing web resources. [...] Are you working on an R package accessing resources on the web, be it a cat facts API, a scientific data source or your system for Customer relationship management?
As with all other packages, appropriate unit testing can make your code more robust.
The unit testing of a package interacting with web resources, however, brings special challenges:
dependence of tests on a good internet connection, testing in the absence of authentication secrets, etc.
Having tests fail due to resources being down or slow, during development  ...
