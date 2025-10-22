Here's a **complete and comprehensive cheat sheet for Harness CI/CD Pipelines**, covering everything from YAML syntax to pipeline structure, triggers, integrations, and best practices.

---

## 🧩 **Harness CI/CD Pipeline Cheat Sheet**

### 📦 **Core Concepts**

- **CI (Continuous Integration)**: Automates build and test processes.
- **CD (Continuous Delivery/Deployment)**: Automates deployment to environments.
- **Pipeline**: A sequence of stages and steps that automate software delivery.
- **Stage**: Logical grouping of steps (e.g., Build, Deploy, Approval).
- **Step**: Individual task (e.g., Shell Script, Docker Build, Kubernetes Deploy).

---

### 🧾 **Basic YAML Structure**

Harness pipelines are defined in YAML. Here's a minimal example:

```yaml
pipeline:
  name: MyPipeline
  identifier: my_pipeline
  projectIdentifier: default
  orgIdentifier: default
  stages:
    - stage:
        name: Build Stage
        identifier: build_stage
        type: CI
        spec:
          execution:
            steps:
              - step:
                  name: Run Build
                  identifier: run_build
                  type: ShellScript
                  spec:
                    shell: Bash
                    source:
                      type: Inline
                      spec:
                        script: echo "Building..."
```

🔹 **Indentation**: Use 2 spaces (4 if preceded by `-`)  
🔹 **Variables**: Use `<+input>` for runtime inputs  
🔹 **Schema Reference**: Harness YAML Schema [1](https://developer.harness.io/docs/platform/pipelines/harness-yaml-quickstart/)

---

### ⚙️ **Pipeline Components**

#### 🧱 **Stages**

- **CI**: Build, test, package
- **CD**: Deploy to environments
- **Approval**: Manual or Jira-based approvals
- **Custom**: Any user-defined logic

#### 🧪 **Steps**

- **ShellScript**: Run shell commands
- **Run**: Execute containers
- **Build**: Compile code
- **Test**: Run unit/integration tests
- **Deploy**: Kubernetes, ECS, etc.

#### 🧩 **Connectors**

Used to integrate with:

- GitHub, GitLab, Bitbucket
- Docker Registry
- Kubernetes clusters
- Artifact repositories

---

### 🚀 **Triggers**

Harness supports multiple trigger types [2](https://www.harness.io/blog/automate-your-ci-cd-pipeline-using-triggers):

| Trigger Type | Description | |------------------|-------------| | **Git Events** | Trigger on commits, PRs, merges | | **Artifact Events** | Trigger on new image/artifact | | **Schedules** | Cron-based triggers | | **Manual** | User-initiated |

Example Git trigger:

```yaml
trigger:
  name: Git Trigger
  type: Git
  spec:
    event: Push
    branch: main
```

---

### 🔐 **Secrets Management**

- Use **Harness Secrets Manager** or integrate with:
    - HashiCorp Vault
    - AWS Secrets Manager
    - GCP Secret Manager
- Reference secrets in YAML:

```yaml
spec:
  script: echo "<+secrets.getValue('my_secret')>"
```

---

### 🧠 **Best Practices**

- ✅ Use **runtime inputs** for flexibility
- ✅ Break pipelines into **modular stages**
- ✅ Use **failure strategies**:

```yaml
failureStrategies:
  - onFailure:
      errors:
        - AllErrors
      action:
        type: Abort
```

- ✅ Enable **parallel execution** for speed
- ✅ Use **approval gates** for production deployments
- ✅ Integrate **monitoring tools** for post-deployment validation

---

### 📊 **Harness CI Intelligence Features**

- **Test Intelligence**: Smart test selection
- **Cache Intelligence**: Speeds up builds
- **Docker Layer Caching**: Optimizes image builds [3](https://developer.harness.io/docs/continuous-integration/get-started/overview/)

---

### 🧰 **Deployment Strategies**

- **Rolling**: Gradual replacement
- **Blue-Green**: Parallel environments
- **Canary**: Incremental rollout with validation [4](https://www.harness.io/blog/ci-cd-pipeline)

---

Would you like this cheat sheet exported as a PDF or tailored to a specific tech stack (e.g., Kubernetes, Docker, Java)?