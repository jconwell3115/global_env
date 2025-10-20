---
title: "Every Cloudflare feature, available to everyone"
source: "https://blog.cloudflare.com/enterprise-grade-features-for-all/"
author:
  - "[[Dane Knecht]]"
  - "[[Brendan Irvine-Broque]]"
  - "[[Rita Kozlov]]"
  - "[[Korinne Alpers]]"
  - "[[Micah Wylde]]"
  - "[[Alex Graham]]"
  - "[[Jérôme Schneider]]"
  - "[[Thomas Gauvin]]"
  - "[[Celso Martinho]]"
  - "[[Carly Ramsey]]"
published: 2025-09-25
created: 2025-09-26
description: "Cloudflare is making every feature available to any customer."
tags:
  - "clippings"
---
2025-09-25

5 min read

![](https://cf-assets.www.cloudflare.com/zkvhlag99gkb/w41XDnBIcyQoJVNK47oxx/52b39133688d0702479412f72460f746/unnamed__34_.png)

Over the next year Cloudflare will make nearly every feature we offer available to any customer who wants to buy and use it regardless of whether they are an enterprise account. No need to pick up a phone and talk to a sales team member. No requirement to find time with a solutions engineer in our team to turn on a feature. No contract necessary. We believe that if you want to use something we offer, you should just be able to buy it.

Today’s launch starts by bringing Single Sign-On (SSO) into our dashboard out of our enterprise plan and making it available to any user. That capability is the first of many. We will be sharing updates over the next few months as more and more features become available for purchase on any plan.

We are also making a commitment to ensuring that all future releases will follow this model. The goal is not to restrict new tools to the enterprise tier for some amount of time before making them widely available. We believe helping build a better Internet means making sure the best tools are available to anyone who needs them.

### Enterprise grade for everyone

It’s not enough to build the best tools on the web. At Cloudflare our mission is to help build a better Internet and that means making the tools we build accessible. We believe the best way to make the Internet faster and more secure is to put powerful features into the hands of as many people as possible.

We first launched an Enterprise tier years ago when larger customers came to us looking to scale their usage of Cloudflare in new ways. They needed procurement options beyond a credit card, like invoices, custom contracts, and dedicated support. This offering was a necessary and important step to bring the benefits of our network and tools to large organizations with complex needs.

This created an unintended side effect in how we shipped products. Some of our most powerful and innovative features were launched within an enterprise-only tier. This created a gap, a two-tiered system where some of the most advanced features were reserved only for the largest companies.

It also created a divergence in our product development. Features built for our self-service customers had to be incredibly simple and intuitive from day-one. Features designated “enterprise-only” didn’t always face that same pressure to scale – we could instead rely on our solutions teams or partners to help set up and support.

It’s time to fix that. Starting today, we are doing away with the concept of “enterprise-only” features. Over the coming months and quarters, we will make many of our most advanced capabilities available to all of our customers.

The change will help build a more secure Internet by removing barriers to the adoption of the most advanced tools available. The change improves the experience for all customers. Smaller teams on our self-service plans will have access to the most powerful configuration options we offer. Existing enterprise teams will have easier pathways to adopt new tools without calling their account manager. And our own Product teams have even more reason to continue to make all features we ship easy to use.

Today we are beginning with dashboard SSO with instructions on how to begin setting that up right now below. It is the first of many though and capabilities like apex proxying and expanded upload limits, along with many others of our most requested enterprise features, will follow.

One example of a feature we launched only to enterprise customers because of the complexity in setting it up is SSO. Enterprise teams maintain their own identity provider where they can manage internal employee accounts and how their team members log into different services.

They integrate these identity providers with the tools their employees need so that team members do not need to create and remember a username and password for each and every service. More importantly, the management of identity in a single place gives enterprises the ability to control authentication policies, onboard and offboard users, and hand out licenses for tools.

We first launched our own SSO support [way back in 2018](https://blog.cloudflare.com/introducing-single-sign-on-for-the-cloudflare-dashboard/). In the last seven years we have been helping thousands of enterprise customers manually set this up, but we know that teams of all sizes rely on the security and convenience of an identity provider. As part of this announcement, the first enterprise feature we are making available to everyone is dashboard SSO.

The functionality is available immediately to anyone on any plan. To get started, follow the instructions [here](https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/dash-sso-apps/) to integrate your identity provider with Cloudflare and to then connect your domain with your account. By setting up your identity provider for dashboard SSO you will also be able to begin using the vast majority of our Zero Trust security features, as well, which are available [at no cost](https://www.cloudflare.com/plans/zero-trust-services/) for up to 50 users.

We also know that some teams are too early or distributed to have a full-fledged identity provider but want the convenience and security of managing logins in one place. To that end, we are also excited to launch support for GitHub as a social login provider to the Cloudflare dashboard as part of today’s announcement.

![](https://cf-assets.www.cloudflare.com/zkvhlag99gkb/1BI0r2eZHaNulh9ur0L5HD/386d1f63b0ece9bea08c51c036b6584c/unnamed__35_.png)

We prioritized dashboard SSO because just about every team that uses Cloudflare wants it. This one change helps make nearly every customer safer by allowing them to centrally manage team access. As we burn down the list of previously enterprise-only features, we will continue targeting those that have similar broad impact.

Some capabilities, like Magic Transit, have less broad appeal. The organizations that maintain their own networks and want to deploy Magic Transit tend to already want to be enterprise customers for account management reasons. That said, we still can improve their experience by making tools like Magic Transit available to all plans because we will have to remove some of the friction in the setup that we have historically just solved with people hours from our solution engineers and partners.

We also realize that the way some of these features are priced only made sense with an invoice or enterprise license agreement model. To make this work, we need to revisit how some of our usage metering and billing functions. That will continue to be a priority for us, and we are excited about how this will push us to continue making our packaging and billing even simpler for all customers.

There are some features that we can’t make available to everyone because of non-technical reasons. For example, using our China Network has complicated legal requirements in China that are impossible for us to manage for millions of customers.

### Self-service by default going forward

One thing we are not announcing today is a strategy to continue to release “enterprise-only” features for a while before they eventually make it to the self-service plans. Going forward, to launch something at Cloudflare the team will need to make sure that any customer can buy it off the shelf without talking to someone.

We expect that requirement to improve how all products are built here, not just the more advanced capabilities. We also consider it mission-critical. We have a long history of making the kinds of tools that only the largest businesses could buy available to anyone, from universal SSL [over a decade ago](https://blog.cloudflare.com/introducing-universal-ssl/) to newer features this week that were available for self-service plans immediately like [per-customer bot detection IDs](https://blog.cloudflare.com/per-customer-bot-defenses/) and security of data in transit [between SaaS applications](https://blog.cloudflare.com/saas-to-saas-security/). We are excited to continue this tradition.

### What’s next?

You can get started right now setting up dashboard SSO in your Cloudflare account using the documentation available [here](https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/dash-sso-apps/). We will continue to share updates as previously enterprise-only features are made available to any plan.

Cloudflare's connectivity cloud protects [entire corporate networks](https://www.cloudflare.com/network-services/), helps customers build [Internet-scale applications efficiently](https://workers.cloudflare.com/), accelerates any [website or Internet application](https://www.cloudflare.com/performance/accelerate-internet-applications/), [wards off DDoS attacks](https://www.cloudflare.com/ddos/), keeps [hackers at bay](https://www.cloudflare.com/application-security/), and can help you on [your journey to Zero Trust](https://www.cloudflare.com/products/zero-trust/).  
  
Visit [1.1.1.1](https://one.one.one.one/) from any device to get started with our free app that makes your Internet faster and safer.  
  
To learn more about our mission to help build a better Internet, [start here](https://www.cloudflare.com/learning/what-is-cloudflare/). If you're looking for a new career direction, check out [our open positions](http://www.cloudflare.com/careers).