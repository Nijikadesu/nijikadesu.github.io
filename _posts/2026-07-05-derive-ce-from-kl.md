---
layout: blog_post
title: "Math Foundations: Derive Cross Entropy from KL divergence"
date: 2026-07-05
tags:
  - Computer Vision
  - Math Foundation
---

## Intro
Many beginners get confused about three core concepts in classification loss: KL divergence, entropy $H(P)$, and cross entropy loss. Common confusing questions:
1. What is the mathematical meaning of entropy $H(P)$?
2. How does the term $\sum p(x)\log p(x)$ connect to entropy $H(P)$?
3. Why do we adopt cross entropy instead of MSE for Softmax classification?
4. Why minimizing cross entropy equals minimizing KL divergence?

This blog covers all step-by-step derivations with intuitive explanations to resolve these doubts.

## 1. Pre-requisite Basics
### 1.1 Self-information
For an event with probability $P(x)$:

$$I(x) = -\log P(x)$$

Events with lower probability carry larger "surprise" information.

### 1.2 Entropy $H(P)$
Entropy is the expected self-information of the ground-truth distribution $P$:

$$
H(P) = -\sum_{x} P(x)\log P(x) = \mathbb{E}_{x\sim P}\big[-\log P(x)\big]
$$

- Mathematical meaning: Quantify the inherent uncertainty of distribution $P$.
- Fixed property: $H(P)$ only relies on dataset true labels, irrelevant to model predicted distribution $Q$.
- Edge case: One-hot labels produce $H(P)=0$ (zero uncertainty).

### 1.3 KL Divergence Definition
KL divergence $D_{KL}(P\parallel Q)$ measures the statistical gap between true distribution $P$ and model prediction $Q$:

$$D_{KL}(P\parallel Q) = \sum_{x} P(x) \log\frac{P(x)}{Q(x)}$$

Core property: $D_{KL} \ge 0$; $D_{KL} = 0$ if and only if $P$ and $Q$ are identical distributions.

## 2. Full Mathematical Derivation
Step 1: Split logarithmic fraction using $\log(a/b) = \log a - \log b$

$$D_{KL}(P\parallel Q) = \sum_{x} P(x) \big[ \log P(x) - \log Q(x) \big]$$

Step 2: Expand summation into two separate terms

$$D_{KL}(P\parallel Q) = \sum_{x} P(x)\log P(x) - \sum_{x} P(x)\log Q(x)$$

Step 3: Rearrange entropy definition to substitute $\sum P(x)\log P(x)$
From $H(P) = -\sum_{x}P(x)\log P(x)$, rearrange:

$$\sum_{x} P(x)\log P(x) = -H(P)$$

Substitute back into KL formula:

$$D_{KL}(P\parallel Q) = -H(P) - \sum_{x} P(x)\log Q(x)$$

Step 4: Define Cross Entropy. Cross entropy $CE(P,Q)$ is formally defined as:

$$CE(P,Q) = -\sum_{x} P(x)\log Q(x)$$

Final core relation formula:

$$D_{KL}(P\parallel Q) = CE(P,Q) - H(P)$$

## 3. Answers to Core Confusions
### Q1: What role does $H(P)$ play in KL divergence formula?
$H(P)$ represents the fixed, inherent uncertainty of ground-truth labels. It is a constant value that has no relation to model weights. When optimizing via gradient descent, constants have zero gradient and can be safely discarded.

### Q2: Why optimize cross entropy instead of raw KL divergence?
Minimizing $D_{KL}(P\parallel Q)$ is equivalent to minimizing $CE(P,Q) - H(P)$. Since $H(P)$ is fixed, minimizing cross entropy alone achieves the exact same training objective.
For Softmax classifier single-sample loss with one-hot labels:

$$L_i = -\log P(Y=y_i \mid X=x_i)$$

All zero terms from one-hot encoding vanish, leaving only the negative log probability of the true class.

### Q3: Is MSE a valid alternative loss for Softmax classification?
Theoretically MSE can be used to fit probability outputs, but it suffers severe gradient vanishing when predictions are close to $0$ or $1$ (high confidence). Cross entropy generates clean, stable gradients without decay, making it the standard loss for Softmax/Sigmoid classification tasks.

## 4. Key Takeaways
1. Entropy $H(P)$ measures uncertainty of true label distribution, calculated as the expectation of self-information.
2. KL divergence can be decomposed into cross entropy minus a fixed constant $H(P)$.
3. Cross entropy loss is the practical optimization target for all probabilistic classification models, including Softmax multi-class classifier and logistic regression.
4. Cross entropy is superior to MSE for probability output layers due to stable gradient flow during backpropagation.
