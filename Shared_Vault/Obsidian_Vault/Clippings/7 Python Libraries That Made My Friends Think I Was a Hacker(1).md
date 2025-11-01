---
title: "7 Python Libraries That Made My Friends Think I Was a Hacker"
source: "https://python.plainenglish.io/7-python-libraries-that-made-my-friends-think-i-was-a-hacker-7da1a22550a9"
author:
  - "[[Maria Ali]]"
published: 2025-09-04
created: 2025-09-07
description: "7 Python Libraries That Made My Friends Think I Was a Hacker Simple imports that looked like complex wizardry to everyone else. Non-members can read for free from here. A couple of years ago, I was …"
tags:
  - "clippings"
---
[Sitemap](https://python.plainenglish.io/sitemap/sitemap.xml)## [Python in Plain English](https://python.plainenglish.io/?source=post_page---publication_nav-78073def27b8-7da1a22550a9---------------------------------------)

[Follow publication](https://medium.com/m/signin?actionUrl=https%3A%2F%2Fmedium.com%2F_%2Fsubscribe%2Fcollection%2Fpython-in-plain-english&operation=register&redirect=https%3A%2F%2Fpython.plainenglish.io%2F7-python-libraries-that-made-my-friends-think-i-was-a-hacker-7da1a22550a9&collection=Python+in+Plain+English&collectionId=78073def27b8&source=post_page---publication_nav-78073def27b8-7da1a22550a9---------------------publication_nav------------------)

[![Python in Plain English](https://miro.medium.com/v2/resize:fill:76:76/1*VA3oGfprJgj5fRsTjXp6fA@2x.png)](https://python.plainenglish.io/?source=post_page---post_publication_sidebar-78073def27b8-7da1a22550a9---------------------------------------)

New Python content every day. Follow to join our 3.5M+ monthly readers.

[Follow publication](https://medium.com/m/signin?actionUrl=https%3A%2F%2Fmedium.com%2F_%2Fsubscribe%2Fcollection%2Fpython-in-plain-english&operation=register&redirect=https%3A%2F%2Fpython.plainenglish.io%2F7-python-libraries-that-made-my-friends-think-i-was-a-hacker-7da1a22550a9&collection=Python+in+Plain+English&collectionId=78073def27b8&source=post_page---post_publication_sidebar-78073def27b8-7da1a22550a9---------------------post_publication_sidebar------------------)

![](https://miro.medium.com/v2/resize:fit:640/format:webp/0*h0VraEbmg_xtjaJw)

AI-Generated Image

> **Non-members can read for free from** [**here.**](https://medium.com/@maryashoukataly/7da1a22550a9?sk=20eaaef724cf62c273df600ead93a705)

A couple of years ago, I was sitting in a cramped college library trying to look productive. In reality, I was automating the most boring part of my day, renaming files my professor uploaded with names like *Assignment(1)\_final\_v2(3).pdf*. My friend walked by, saw my terminal spitting out renamed files like clockwork, and whispered,

> “Yo, are you hacking?”

I wasn’t hacking. But Python made me look like I was. That day, I realized something: The right libraries can turn the most tedious, brain-numbing tasks into slick little tricks that look straight out of a hacker movie.

> **A beginner-friendly Python guide made for non-programmers.** [**Start learning**](https://abdulahad28.gumroad.com/l/irehc) **Python the easy way!**

Here are seven of those libraries. Not the usual suspects you’ve seen everywhere, these are the ones that made me look like I was doing black magic with code.

## Faker: Generating Fake Data Like a Spy

Sometimes you just need fake identities. I once used Faker to populate a test database with “students” for a project demo. By the time my script finished, I had a classroom full of names, emails, and addresses that looked creepily real.

```c
from faker import Faker
fake = Faker()
for _ in range(3):
    print(fake.name(), "|", fake.email())
```

Output? Three random humans who don’t exist. To the untrained eye, I’d just spun up an entire secret network.

## TQDM: Progress Bars That Impress

One of the simplest flexes is slapping a progress bar on any loop. I added `tqdm` to a file-processing script, and suddenly people thought I was running some top-secret algorithm.

```c
from tqdm import tqdm
import time
for _ in tqdm(range(10)):
    time.sleep(0.1)
```

That’s it. A few lines, and your terminal looks alive. It’s amazing how much respect you get when your script “looks busy.”

## PyFiglet: ASCII Art for Instant Hacker Vibes

Nothing screams “hacker terminal” like giant ASCII letters taking over your screen. I once added a banner with my name to a project just for the aesthetic.

```c
import pyfiglet
banner = pyfiglet.figlet_format("Maria")
print(banner)
```

Now, instead of boring logs, my terminal looked like a scene from Mr. Robot.

## Colorama: Painting the Terminal

Plain white text is for amateurs. I discovered `colorama` while customizing logs, and it instantly gave my scripts personality.

```c
from colorama import Fore, Style
print(Fore.RED + "Warning!" + Style.RESET_ALL)
print(Fore.GREEN + "Task Completed")
```

Suddenly, my output looked polished — like a tool built by someone who knew what they were doing (even when I didn’t).

## Schedule: Automating Like a Pro

Once, I set up a script to automatically send me reminders to stand up during long coding sessions. My roommate saw my laptop buzzing at the same time every day and assumed I was running some underground cron job.

```c
import schedule, time
def break_time():
    print("Stand up and stretch!")
schedule.every(10).seconds.do(break_time)
while True:
    schedule.run_pending()
    time.sleep(1)
```

In reality, it was just Python babysitting me.

## Paramiko: Remote Control Without Touching the Keyboard

When I first used `paramiko` to SSH into a server with Python, I felt like I’d unlocked a cheat code. Typing commands manually? Nah, my script did it for me.

```c
import paramiko
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect("hostname", username="user", password="pass")
stdin, stdout, stderr = ssh.exec_command("ls")
print(stdout.read().decode())
ssh.close()
```

That moment, when I ran a command on a remote machine without leaving my Python script, made me feel unstoppable.

## PyInputPlus: Smarter User Input

I once wrote a script for my classmates where the input box didn’t just accept anything, it validated answers, forced choices, and even retried until they got it right. Suddenly, people thought I was building professional software.

```c
import pyinputplus as pyip
age = pyip.inputInt("Enter your age: ", min=1, max=100)
print("You entered:", age)
```

Instead of messy `input()` hacks, I had clean, bulletproof interactions.

## Conclusion:

These libraries aren’t just tools, they’re illusions. They turn everyday Python scripts into something that looks far more complex and impressive than it really is.

Once you start using them, you’ll realize that most “hacker magic” is just automation sprinkled with a little flair.

Don’t just collect libraries. Use them to solve tiny annoyances in your own life. That’s how you go from writing code to looking like you’re bending the matrix.

***Read my other articles:***## [This One Coding Habit Quietly Doubled My Productivity](https://medium.com/codrift/this-one-coding-habit-quietly-doubled-my-productivity-4476a1c3f03a?source=post_page-----7da1a22550a9---------------------------------------)

It’s not a new framework or library; it’s something every developer can start doing today.

medium.com

[View original](https://medium.com/codrift/this-one-coding-habit-quietly-doubled-my-productivity-4476a1c3f03a?source=post_page-----7da1a22550a9---------------------------------------)## [The 5 Python Libraries That Saved My Broken Codebase](https://python.plainenglish.io/the-5-python-libraries-that-saved-my-broken-codebase-def97ad4f542?source=post_page-----7da1a22550a9---------------------------------------)

How I fixed chaos with tools I didn’t even know existed

python.plainenglish.io

[View original](https://python.plainenglish.io/the-5-python-libraries-that-saved-my-broken-codebase-def97ad4f542?source=post_page-----7da1a22550a9---------------------------------------)## [5 Python Playwright Hacks That Made Me Forget About Selenium Forever](https://medium.com/codrift/5-python-playwright-hacks-that-made-me-forget-about-selenium-forever-da2eb8df6a08?source=post_page-----7da1a22550a9---------------------------------------)

Faster, cleaner, and smarter, here’s why I’ll never go back.

medium.com

[View original](https://medium.com/codrift/5-python-playwright-hacks-that-made-me-forget-about-selenium-forever-da2eb8df6a08?source=post_page-----7da1a22550a9---------------------------------------)## [Can Python Really Make You Money? I Put It to the Test](https://medium.com/codrift/can-python-really-make-you-money-i-put-it-to-the-test-e54bb46e4a74?source=post_page-----7da1a22550a9---------------------------------------)

A no-fluff breakdown of what worked, what failed, and what I’d do differently.

medium.com

[View original](https://medium.com/codrift/can-python-really-make-you-money-i-put-it-to-the-test-e54bb46e4a74?source=post_page-----7da1a22550a9---------------------------------------)

***Want a pack of prompts that work for you and save hours?*** [***click here***](https://abdulahad28.gumroad.com/l/rwnlrm)

> ***Ready to go from Java beginner to confident developer?*** [***Start here***](https://gumroad.com/a/1035515539/QqjGH)***.***

*Want more posts like this? Drop a “YES” in the comment, and I’ll share more coding tricks like this one.*

*Want to support me? Give 50 claps on this post and follow me.*

*Thanks for reading!*

## A message from our Founder

**Hey,** [**Sunil**](https://linkedin.com/in/sunilsandhu) **here.** I wanted to take a moment to thank you for reading until the end and for being a part of this community.

Did you know that our team run these publications as a volunteer effort to over 3.5m monthly readers? **We don’t receive any funding, we do this to support the community. ❤️**

If you want to show some love, please take a moment to **follow me on** [**LinkedIn**](https://linkedin.com/in/sunilsandhu)**,** [**TikTok**](https://tiktok.com/@messyfounder), [**Instagram**](https://instagram.com/sunilsandhu). You can also subscribe to our [**weekly newsletter**](https://newsletter.plainenglish.io/).

And before you go, don’t forget to **clap** and **follow** the writer️!

[![Python in Plain English](https://miro.medium.com/v2/resize:fill:96:96/1*VA3oGfprJgj5fRsTjXp6fA@2x.png)](https://python.plainenglish.io/?source=post_page---post_publication_info--7da1a22550a9---------------------------------------)

[![Python in Plain English](https://miro.medium.com/v2/resize:fill:128:128/1*VA3oGfprJgj5fRsTjXp6fA@2x.png)](https://python.plainenglish.io/?source=post_page---post_publication_info--7da1a22550a9---------------------------------------)

[Last published 3 hours ago](https://python.plainenglish.io/the-python-library-that-cuts-my-coding-time-in-half-66ae1873cf20?source=post_page---post_publication_info--7da1a22550a9---------------------------------------)

New Python content every day. Follow to join our 3.5M+ monthly readers.

Freelancer | Software Engineer | Programmer

## Responses (1)

To respond to this story,  
get the free Medium app.

[Open in app](https://rsci.app.link/?%24canonical_url=https%3A%2F%2Fmedium.com%2Fp%2F7da1a22550a9&%7Efeature=LoOpenInAppButton&%7Echannel=ShowPostUnderCollection&%7Estage=responsesSidebar&source=post_page---post_responses--7da1a22550a9---------------------------------------)

6

## More from Maria Ali and Python in Plain English

## Recommended from Medium

[

See more recommendations

](https://medium.com/?source=post_page---read_next_recirc--7da1a22550a9---------------------------------------)