---
title: "Debugging Python in Docker: A Tutorial for Beginners"
source: https://www.kdnuggets.com/debugging-python-in-docker-a-tutorial-for-beginners
author:
  - "[[Bala Priya C]]"
published:
created: 2025-09-02
description: New to running Python in Docker? This step-by-step guide helps you understand and apply debugging techniques in a containerized environment.
tags:
  - clippings
  - Docker
  - Python
---
New to running Python in Docker? This step-by-step guide helps you understand and apply debugging techniques in a containerized environment.

By , KDnuggets Contributing Editor & Technical Content Specialist on August 20, 2025 in

---

  

![Debugging Python in Docker: A Tutorial for Beginners](https://www.kdnuggets.com/wp-content/uploads/bala-python-debug-docker-2.png)  
Image by Author | Ideogram

## \# Introduction

  
**[Docker](https://www.docker.com/)** has simplified how we develop, ship, and run applications by providing consistent environments across different systems. However, this consistency comes with a trade-off: debugging becomes deceptively complex for beginners when your applications — including Python applications — are running inside Docker containers.[![NWU MSDS](https://www.kdnuggets.com/wp-content/uploads/s1-nwu-msds-2509.jpg)  
Five specializations including AI.](https://sps.northwestern.edu/information/data-science-online-masters.html?utm_source=kdnuggets&utm_medium=banner300x250&utm_campaign=kdnuggets_msds_banner300x250_l&utm_term=sep25&utm_content=msds&src=kdnuggets_msds_banner300x250_sepfy26_l)

For those new to Docker, debugging Python applications can feel like trying to fix a car with the hood welded shut. You know something's wrong, but you can't quite see what's happening inside.[![Airia Enterprise AI](https://www.kdnuggets.com/wp-content/uploads/s-airia-2506.png)  
Schedule a demo today](https://airia.com/request-demo/?utm_source=kd_nuggets&utm_medium=display&utm_id=ai_q2)

This beginner-friendly tutorial will teach you how to get started with debugging Python in Docker.

## \# Why is Debugging in Docker Different?

  
Before we dive in, let's understand why Docker makes debugging tricky. When you’re running Python locally on your machine, you can:

- See error messages immediately
- Edit files and run them again
- Use your favorite debugging tools
- Check what files exist and what's in them

But when Python runs inside a Docker container, it's often trickier and less direct, especially if you’re a beginner. The container has its own file system, its own environment, and its own running processes.

## \# Setting Up Our Example

  
Let's start with a simple Python program that has a bug. Don't worry about Docker yet; let's first understand what we're working with.

Create a file called `app.py`:

```
def calculate_sum(numbers):
    total = 0
    for num in numbers:
        total += num
        print(f"Adding {num}, total is now {total}")
    return total

def main():
    numbers = [1, 2, 3, 4, 5]
    result = calculate_sum(numbers)
    print(f"Final result: {result}")
    
    # This line will cause our program to crash!
    division_result = 10 / 0
    print(f"Division result: {division_result}")

if __name__ == "__main__":
    main()
```

If you run this normally with `python3 app.py`, you'll see it calculates the sum correctly but then crashes with a "division by zero" error. Easy to spot and fix, right?

Now let’s see what happens when this simple application runs inside a Docker container.

## \# Creating Your First Docker Container

  
We need to tell Docker how to package our Python program. Create a file called \`Dockerfile\`:

```
FROM python:3.11-slim

WORKDIR /app

COPY app.py .

CMD ["python3", "app.py"]
```

Let me explain each line:

- `FROM python:3.11-slim` tells Docker to start with a pre-made Linux system that already has Python installed
- `WORKDIR /app` creates an \`/app\` folder inside the container and sets it as the working directory
- `COPY app.py .` copies your `app.py` file from your computer into the \`/app\` folder inside the container
- `CMD ["python3", "app.py"]` tells Docker what command to run when the container starts

Now let's build and run this container:

```
docker build -t my-python-app .
docker run my-python-app
```

You'll see the output, including the error, but then the container stops and exits. This leaves you to figure out what went wrong inside the isolated container.

## \# 1. Running an Interactive Debugging Session

  
The first debugging skill you need is learning how to get inside a running container and check for potential problems.

Instead of running your Python program immediately, let's start the container and get a command prompt inside it:

```
docker run -it my-python-app /bin/bash
```

Let me break down these new flags:

- `-i` means "interactive" — it keeps the input stream open so you can type commands
- `-t` allocates a "pseudo-TTY" — basically, it makes the terminal work properly
- `/bin/bash` overrides the normal command and gives you a bash shell instead

Now that you have a terminal inside the container, you can run commands like so:

```
# See what directory you're in
pwd

# List files in the current directory
ls -la

# Look at your Python file
cat app.py

# Run your Python program
python3 app.py
```

You'll also see the error:

```
root@fd1d0355b9e2:/app# python3 app.py
Adding 1, total is now 1
Adding 2, total is now 3
Adding 3, total is now 6
Adding 4, total is now 10
Adding 5, total is now 15
Final result: 15
Traceback (most recent call last):
  File "/app/app.py", line 18, in 
    main()
  File "/app/app.py", line 14, in main
    division_result = 10 / 0
                      ~~~^~~
ZeroDivisionError: division by zero
```

Now you can:

- Edit the file right here in the container (though you'll need to install an editor first)
- Explore the environment to understand what's different
- Test small pieces of code interactively

Fix the division by zero error (maybe change \`10 / 0\` to \`10 / 2\`), save the file, and run it again.

The problem is fixed. When you exit the container, however, you lose track of changes you made. This brings us to our next technique.

## \# 2. Using Volume Mounting for Live Edits

  
Wouldn't it be nice if you could edit files on your computer and have those changes automatically appear inside the container? That's exactly what volume mounting does.

```
docker run -it -v $(pwd):/app my-python-app /bin/bash
```

The new part here is `-v $(pwd):/app`:

- `$(pwd)` outputs the current directory path.
- `:/app` maps your current directory to `/app` inside the container.
- Any file you change on your computer immediately changes inside the container too.

Now you can:

1. Edit `app.py` on your computer using your favorite editor
2. Inside the container, run `python3 app.py` to test your changes
3. Keep editing and testing until it works

Here's a sample output after changing the divisor to 2:

```
root@3790528635bc:/app# python3 app.py
Adding 1, total is now 1
Adding 2, total is now 3
Adding 3, total is now 6
Adding 4, total is now 10
Adding 5, total is now 15
Final result: 15
Division result: 5.0
```

This is useful because you get to use your familiar editing environment on your computer and the exact same environment inside the container as well.

## \# 3. Connecting a Remote Debugger from Your IDE

  
If you're using an Integrated Development Environment (IDE) like **[VS Code](https://code.visualstudio.com/)** or **[PyCharm](https://www.jetbrains.com/pycharm/)**, you can actually connect your IDE's debugger directly to code running inside a Docker container. This gives you the full power of your IDE's debugging tools.

Edit your \`Dockerfile\` like so:

```
FROM python:3.11-slim

WORKDIR /app

# Install the remote debugging library
RUN pip install debugpy

COPY app.py .

# Expose the port that the debugger will use
EXPOSE 5678

# Start the program with debugger support
CMD ["python3", "-m", "debugpy", "--listen", "0.0.0.0:5678", "--wait-for-client", "app.py"]
```

What this does:

- `pip install debugpy` installs Microsoft's **[debugpy](https://github.com/microsoft/debugpy)** library.
- `EXPOSE 5678` tells Docker that our container will use port 5678.
- The `CMD` starts our program through the debugger, listening on port 5678 for a connection. No changes to your Python code are needed.

Build and run the container:

```
docker build -t my-python-app .
docker run -p 5678:5678 my-python-app
```

The `-p 5678:5678` maps port 5678 from inside the container to port 5678 on your computer.

Now in VS Code, you can set up a debug configuration (in `.vscode/launch.json`) to connect to the container:

```
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Remote Attach",
            "type": "python",
            "request": "attach",
            "connect": {
                "host": "localhost",
                "port": 5678
            }
        }
    ]
}
```

When you start debugging in VS Code, it will connect to your container, and you can set breakpoints, inspect variables, and step through code just like you would with local code.

## \# Common Debugging Problems and Solutions

  
⚠️ **"My program works on my computer but not in Docker"**

This usually means there's a difference in the environment. Check:

- Python version differences.
- Missing dependencies.
- Different file paths.
- Environment variables.
- File permissions.

⚠️ **"I can't see my print statements"**

- Use `python -u` to avoid output buffering.
- Make sure you're running with `-it` if you want interactive output.
- Check if your program is actually running as intended (maybe it's exiting early).

⚠️ **"My changes aren't showing up"**

- Make sure you're using volume mounting (`-v`).
- Check that you're editing the right file.
- Verify the file is copied into the container.

⚠️ **"The container exits immediately"**

- Run with `/bin/bash` to inspect the container's state.
- Check the error messages with `docker logs container_name`.
- Make sure your `CMD` in the Dockerfile is correct.

## \# Conclusion

  
You now have a basic toolkit for debugging Python in Docker:

1. Interactive shells (`docker run -it ... /bin/bash`) for exploring and quick fixes
2. Volume mounting (`-v $(pwd):/app`) for editing in your local file system
3. Remote debugging for using your IDE's full capabilities

After this, you can try using Docker Compose for managing complex applications. For now, start with these simple techniques. Most debugging problems can be solved just by getting inside the container and poking around.

The key is to be methodical: *understand what should be happening, figure out what is actually happening, and then bridge the gap between the two*. Happy debugging!  
  

is a developer and technical writer from India. She likes working at the intersection of math, programming, data science, and content creation. Her areas of interest and expertise include DevOps, data science, and natural language processing. She enjoys reading, writing, coding, and coffee! Currently, she's working on learning and sharing her knowledge with the developer community by authoring tutorials, how-to guides, opinion pieces, and more. Bala also creates engaging resource overviews and coding tutorials.

  

---

  

[<= Previous post](https://www.kdnuggets.com/leveraging-pandas-and-sql-together-for-efficient-data-analysis)

[Next post =>](https://www.kdnuggets.com/vibing-with-amazon-kiro)