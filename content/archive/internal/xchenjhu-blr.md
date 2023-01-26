---
title: "Bayesian Linear Regression"
author: "Xiang Chen, Dr. Sudipto Banerjee"
date: "2023-01-23T17:58:56Z"
tags: [Bayesian, Tutorial]
link: "https://bookdown.org/xchenjhu/blr/"
length_weight: "3.4%"
repo: "rstudio/bookdown-demo"
pinned: false
---

This is a tutorial for Bayesian Linear Regressione. [...] Theorem 1.1 (Bayes' theorem) For events \(A, B\) and \(P(B) \neq 0\), we have \[P(A\mid B) = \frac{P(B \mid A) P(A)}{P(B)}\] We denote \(U\) as unknown parameters and \(K\) as known parameters. We call \(P(U)\) prior and \(P(K|U)\) likelihood. The Bayes’ theorem gives us the posterior distribution of unknown parameters given the known parameters \[ P(U \mid K) \propto P(U) \cdot P(K \mid U)\] Let \(K = \left\{y_{n \times 1}, X_{n \times p} \right\}\) and assume \(y \sim N\left( X \beta, \sigma^{2} V\right)\), where \(V\) is known and ...
