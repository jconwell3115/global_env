---
title: "From Dataset to DataFrame to Deployed: Your First Project with Pandas & Scikit-learn"
source: "https://www.kdnuggets.com/from-dataset-to-dataframe-to-deployed-your-first-project-with-pandas-scikit-learn"
author:
  - "[[Iván Palomares Carrascosa]]"
published:
created: 2025-11-09
description: "In this article, I will take you through a gentle, beginner-friendly machine learning project in which we will build together a regression model that predicts employee income based on socio-economic attributes."
tags:
  - "clippings"
---
In this article, I will take you through a gentle, beginner-friendly machine learning project in which we will build together a regression model that predicts employee income based on socio-economic attributes.

By , KDnuggets Technical Content Specialist on November 7, 2025 in

---

  

![From Dataset to DataFrame to Deployed: Your First Project with Pandas & Scikit-learn](https://www.kdnuggets.com/wp-content/uploads/kdn-ipc-from-app-to-df-to-deployed.png)  
Image by Editor

  

## \# Introduction

  
Eager to start your first, manageable machine learning project with Python's popular libraries **[Pandas](https://pandas.pydata.org/)** and **[Scikit-learn](https://scikit-learn.org/stable/)**, but unsure where to start? Look no further.

In this article, I will take you through a gentle, beginner-friendly machine learning project in which we will build together a regression model that predicts employee income based on socio-economic attributes. Along the way, we will learn some key machine learning concepts and essential tricks.

## \# From Raw Dataset to Clean DataFrame

  
First, just like with any Python-based project, it is a good practice to start by importing the necessary libraries, modules, and components we will use during the whole process:

```
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error
import joblib
```

The following instructions will load a publicly available dataset in [this repository](https://github.com/gakudo-ai/open-datasets/blob/main/employees_dataset_with_missing.csv) into a Pandas `DataFrame` object: a neat data structure to load, analyze, and manage fully structured data, that is, data in tabular format. Once loaded, we look at its basic properties and data types in its attributes.

```
url = "https://raw.githubusercontent.com/gakudo-ai/open-datasets/main/employees_dataset_with_missing.csv"
df = pd.read_csv(url)
print(df.head())
print(df.info())
```

You will notice that the dataset contains 1000 entries or instances — that is, data describing 1000 employees — but for most attributes, like age, income, and so on, there are fewer than 1000 actual values. Why? Because **this dataset has missing values**, a common issue in real-world data, which needs to be dealt with.

**In our project, we will set the goal of predicting an employee’s income based on the rest of the attributes**. Therefore, we will adopt the approach of discarding rows (employees) whose value for this attribute is missing. While for predictor attributes it is sometimes fine to deal with missing values and estimate or impute them, for the target variable, we need fully known labels for training our machine learning model: the catch is that our machine learning model learns by being exposed to examples with known prediction outputs.

There is also a specific instruction to check for missing values only:

```
print(df.isna().sum())
```

So, let's clean our `DataFrame` to be exempt from missing values for the target variable: income. This code will remove entries with missing values, specifically for that attribute.

```
target = "income"
train_df = df.dropna(subset=[target])

X = train_df.drop(columns=[target])
y = train_df[target]
```

So, how about the missing values in the rest of the attributes? We will look after that shortly, but first, we need to separate our dataset into two major subsets: a training set for training the model, and a test set to evaluate our model's performance once trained, consisting of different examples from those seen by the model during training. Scikit-learn provides a single instruction to do this splitting randomly:

```
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
```

The next step goes a step further in turning the data into a great form for training a machine learning model: constructing a preprocessing pipeline. Normally, this preprocessing should distinguish between numeric and categorical features, so that each type of feature is subject to different preprocessing tasks along the pipeline. For instance, numeric features shall be typically scaled, whereas categorical features may be mapped or encoded into numeric ones so that the machine learning model can digest them. For the sake of illustration, the code below demonstrates the full process of building a preprocessing pipeline. It includes the automatic identification of numeric vs. categorical features so that each type can be handled correctly.

```
numeric_features = X.select_dtypes(include=["int64", "float64"]).columns
categorical_features = X.select_dtypes(exclude=["int64", "float64"]).columns

numeric_transformer = Pipeline([
    ("imputer", SimpleImputer(strategy="median"))
])

categorical_transformer = Pipeline([
    ("imputer", SimpleImputer(strategy="most_frequent")),
    ("onehot", OneHotEncoder(handle_unknown="ignore"))
])

preprocessor = ColumnTransformer([
    ("num", numeric_transformer, numeric_features),
    ("cat", categorical_transformer, categorical_features)
])
```

You can learn more about data preprocessing pipelines in [this article](https://machinelearningmastery.com/5-scikit-learn-pipeline-tricks-to-supercharge-your-workflow/).

This pipeline, once applied to the `DataFrame`, will result in a clean, ready-to-use version for machine learning. But we will apply it in the next step, where we will encapsulate both data preprocessing and machine learning model training into one single overarching pipeline.

## \# From Clean DataFrame to Ready-to-Deploy Model

  
Now we will define an overarching pipeline that:

1. Applies the previously defined preprocessing process — saved in the `preprocessor` variable — for both numeric and categorical attributes.
2. Trains a regression model, namely a random forest regression, to predict income using preprocessed training data.

```
model = Pipeline([
    ("preprocessor", preprocessor),
    ("regressor", RandomForestRegressor(random_state=42))
])

model.fit(X_train, y_train)
```

Importantly, the training stage only receives the training subset we created earlier upon splitting, not the whole dataset.

Now, we take the other subset of the data, the test set, and use it to evaluate the model's performance on these example employees. We will use the mean absolute error (MAE) as our evaluation metric:

```
preds = model.predict(X_test)
mae = mean_absolute_error(y_test, preds)
print(f"\nModel MAE: {mae:.2f}")
```

You may get an MAE value of around 13000, which is acceptable but not brilliant, considering that most incomes are in the range of 60-90K. Anyway, not bad for a first machine learning model!

Let me show you, on a final note, how to save your trained model in a file for future deployment.

```
joblib.dump(model, "employee_income_model.joblib")
print("Model saved as employee_income_model.joblib")
```

Having your trained model saved in a `.joblib` file is useful for future deployment, by allowing you to reload and reuse it instantly without having to train it again from scratch. Think of it as “freezing” all your preprocessing pipeline and the trained model into a portable object. Fast options for future use and deployment include plugging it into a simple Python script or notebook, or building a lightweight web app built with tools like **[Streamlit](https://streamlit.io/)**, **[Gradio](https://www.gradio.app/)**, or **[Flask](https://flask.palletsprojects.com/en/3.0.x/)**.

## \# Wrapping Up

  
In this article, we have built together an introductory machine learning model for regression, namely to predict employee incomes, outlining the necessary steps from raw dataset to clean, preprocessed `DataFrame`, and from `DataFrame` to ready-to-deploy model.  
  

****[Iván Palomares Carrascosa](https://www.linkedin.com/in/ivanpc/)**** is a leader, writer, speaker, and adviser in AI, machine learning, deep learning & LLMs. He trains and guides others in harnessing AI in the real world.

  

---

  

[<= Previous post](https://www.kdnuggets.com/2025/11/365careers/free-ai-and-data-courses-with-365-data-science-100-unlimited-access-until-nov-21)

[Next post =>](https://www.kdnuggets.com/building-full-stack-apps-with-firebase-studio)