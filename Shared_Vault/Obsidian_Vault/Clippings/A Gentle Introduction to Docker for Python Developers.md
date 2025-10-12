---
title: "A Gentle Introduction to Docker for Python Developers"
source: "https://www.kdnuggets.com/a-gentle-introduction-to-docker-for-python-developers"
author:
  - "[[Bala Priya C]]"
published:
created: 2025-09-10
description: "Learn how Docker can help Python developers create isolated, consistent environments that simplify everything from development to deployment."
tags:
  - "clippings"
---
Learn how Docker can help Python developers create isolated, consistent environments that simplify everything from development to deployment.

By , KDnuggets Contributing Editor & Technical Content Specialist on September 9, 2025 in

---

  

![A Gentle Introduction to Docker for Python Developers](https://www.kdnuggets.com/wp-content/uploads/bala-docker-for-python-devs.jpeg)  
Image by Author | Ideogram

  

## \# Introduction

  
You just pushed your Python app to production, and suddenly everything breaks. The app worked perfectly on your laptop, passed all tests in CI, but now it's throwing mysterious import errors in production. Sound familiar? Or maybe you're onboarding a new developer who spends three days just trying to get your project running locally. They're on Windows, you developed on Mac, the production server runs Ubuntu, and somehow everyone has different Python versions and conflicting package installations.[![Blackwell Server Edition](https://www.kdnuggets.com/wp-content/uploads/s1-pny-2504-1.jpg)  
Learn more](https://www.pny.com/nvidia-rtx-pro-6000-blackwell?iscommercial=true&utm_source=KDNuggets+Banner+300x250&utm_medium=Web+Banners&utm_campaign=Blackwell+Server&utm_id=RTX+PRO+6000)

We've all been there, frantically debugging environment-specific issues instead of building features. **[Docker](https://www.docker.com/)** solves this mess by packaging your entire application environment into a container that runs identically everywhere. No more "works on my machine" excuses. No more spending weekends debugging deployment issues. This article introduces you to Docker and how you can use Docker to simplify application development. You'll also learn how to containerize a simple Python application using Docker.[![Blackwell Server Edition](https://www.kdnuggets.com/wp-content/uploads/s1-pny-2504-1.jpg)  
Learn more](https://www.pny.com/nvidia-rtx-pro-6000-blackwell?iscommercial=true&utm_source=KDNuggets+Banner+300x250&utm_medium=Web+Banners&utm_campaign=Blackwell+Server&utm_id=RTX+PRO+6000)

🔗 **[Link to the code on GitHub](https://github.com/balapriyac/python-basics/tree/main/intro-to-docker)**

## \# How Docker Works and Why You Need It

  
Think of Docker as analogous to shipping containers, but for your code. When you containerize a Python app, you're not just packaging your code. You're packaging the entire runtime environment: the specific Python version, all your dependencies, system libraries, environment variables, and even the operating system your app expects.

The result? Your app runs the same way on your laptop, your colleague's Windows machine, the staging server, and production. Every time. But how do you do that?

Well, when you're containerizing Python apps with Docker, you do the following. You package your app into a portable artifact called an "image". Then, you start "containers" — running instances of images — and run your applications in the containerized environment.

## \# Building a Python Web API

  
Instead of starting with toy examples, let's containerize a realistic Python application. We'll build a simple **[FastAPI](https://fastapi.tiangolo.com/)** -based todo API (with **[Uvicorn](https://www.uvicorn.org/)** as the ASGI server) that demonstrates the patterns you'll use in real projects, and use **[Pydantic](https://docs.pydantic.dev/)** for data validation.

In your project directory, create a requirements.txt file:

```
fastapi==0.116.1
uvicorn[standard]==0.35.0
pydantic==2.11.7
```

Now let's create the basic app structure:

```
# app.py
from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
import os

app = FastAPI(title="Todo API")
todos = []
next_id = 1
```

Add data models:

```
class TodoCreate(BaseModel):
    title: str
    completed: bool = False

class Todo(BaseModel):
    id: int
    title: str
    completed: bool
```

Create a health check endpoint:

```
@app.get("/")
def health_check():
    return {
        "status": "healthy",
        "environment": os.getenv("ENVIRONMENT", "development"),
        "python_version": os.getenv("PYTHON_VERSION", "unknown")
    }
```

Add the core todo functionality:

```
@app.get("/todos", response_model=List[Todo])
def list_todos():
    return todos

@app.post("/todos", response_model=Todo)
def create_todo(todo_data: TodoCreate):
    global next_id
    new_todo = Todo(
        id=next_id,
        title=todo_data.title,
        completed=todo_data.completed
    )
    todos.append(new_todo)
    next_id += 1
    return new_todo

@app.delete("/todos/{todo_id}")
def delete_todo(todo_id: int):
    global todos
    todos = [t for t in todos if t.id != todo_id]
    return {"message": "Todo deleted"}
```

Finally, add the server startup code:

```
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

If you run this locally with `pip install -r requirements.txt && python app.py`, you'll have an API running locally. Now let's proceed to containerize the application.

## \# Writing Your First Dockerfile

  
You have your app, you have a list of requirements, and the specific environment for your app to run. So how do you go from these disparate components into one Docker image that contains both your code and dependencies? You can specify this by writing a Dockerfile for your application.

Think of it as a recipe to build an image from the different components of your project. Create a Dockerfile in your project directory (no extension).

```
# Start with a base Python image:
FROM python:3.11-slim

# Set environment variables:
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    ENVIRONMENT=production \
    PYTHON_VERSION=3.11

# Set up the working directory:
WORKDIR /app

# Install dependencies (this order is important for caching):
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy your application code:
COPY . .

# Expose the port and set the startup command:
EXPOSE 8000
CMD ["python", "app.py"]
```

This Dockerfile builds a Python web application container. It uses Python 3.11 (slim version) image as the base, sets up a working directory, installs dependencies from requirements.txt, copies the app code, exposes port 8000, and runs the application with `python app.py`. The structure follows best practices by installing dependencies before copying code to use **[Docker's layer caching](https://www.kdnuggets.com/how-to-leverage-docker-cache-for-optimizing-build-speeds)**.

## \# Building and Running Your First Container

  
Now let's build and run our containerized application:

```
# Build the Docker image
docker build -t my-todo-app .

# Run the container
docker run -p 8000:8000 my-todo-app
```

When you run `docker build`, you'll see that each line in your Dockerfile is built as a layer. The first build might take a bit as Docker downloads the base Python image and installs your dependencies.

> ⚠️ Use `docker buildx build` to build an image from the instructions in the Dockerfile using BuildKit.

The `-t my-todo-app` flag tags your image with a better name instead of a random hash. The `-p 8000:8000` part maps port 8000 inside the container to port 8000 on your host machine.

You can visit `http://localhost:8000` to see if your API is running inside a container. The same container will run identically on any machine that has Docker installed.

## \# Essential Docker Commands for Daily Use

  
Here are the Docker commands you'll use most often:

```
# Build an image
docker build -t myapp .

# Run a container in the background
docker run -d -p 8000:8000 --name myapp-container myapp

# View running containers
docker ps

# View container logs
docker logs myapp-container

# Get a shell inside a running container
docker exec -it myapp-container /bin/sh

# Stop and remove containers
docker stop myapp-container
docker rm myapp-container

# Clean up unused containers, networks, images
docker system prune
```

## \# Some Docker Best Practices That Matter

  
After working with Docker in production, here are the practices that actually make a difference.

Always use specific version tags for base images:

```
# Instead of this
FROM python:3.11

# Use this
FROM python:3.11.7-slim
```

Create a.dockerignore file to exclude unnecessary files:

```
__pycache__
*.pyc
.git
.pytest_cache
node_modules
.venv
.env
README.md
```

Keep your images lean by cleaning up package managers:

```
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*
```

Always run containers as non-root users in production.

## \# Wrapping Up

  
This tutorial covered the fundamentals, but Docker's ecosystem is vast. Here are the next areas to explore. For production deployments, learn about container orchestration platforms like **[Kubernetes](https://kubernetes.io/)** or cloud-specific services like **[AWS Elastic Container Service (ECS)](https://aws.amazon.com/ecs/)**, **[Google Cloud Run](https://cloud.google.com/run)**, or **[Azure Container Instances](https://learn.microsoft.com/azure/container-instances/)**.

Explore Docker's security features, including secrets management, image scanning, and rootless Docker. Learn about optimizing Docker images for faster builds and smaller sizes. Set up automated build-and-deploy pipelines using continuous integration/continuous delivery (CI/CD) systems such as **[GitHub Actions](https://github.com/features/actions)** and **[GitLab CI](https://docs.gitlab.com/ee/ci/)**.

Happy learning!  
  

is a developer and technical writer from India. She likes working at the intersection of math, programming, data science, and content creation. Her areas of interest and expertise include DevOps, data science, and natural language processing. She enjoys reading, writing, coding, and coffee! Currently, she's working on learning and sharing her knowledge with the developer community by authoring tutorials, how-to guides, opinion pieces, and more. Bala also creates engaging resource overviews and coding tutorials.

  

---

  

[<= Previous post](https://www.kdnuggets.com/ray-or-dask-a-practical-guide-for-data-scientists)

[Next post =>](https://www.kdnuggets.com/5-portfolio-mistakes-that-keep-data-scientists-from-getting-hired)