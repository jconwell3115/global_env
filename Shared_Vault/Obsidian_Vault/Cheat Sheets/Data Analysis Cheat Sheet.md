Here’s a **complete and comprehensive Data Analysis Cheat Sheet** that covers the essential concepts, tools, techniques, and workflows used in data analysis. It’s structured to be practical and easy to reference whether you're a beginner or an experienced analyst.

---

## 📊 **Data Analysis Cheat Sheet**

### 1. **Data Analysis Workflow**

- **Define the Problem**: Understand the business or research question.
- **Collect Data**: From databases, APIs, files (CSV, Excel), web scraping, etc.
- **Clean Data**: Handle missing values, duplicates, outliers, and inconsistent formats.
- **Explore Data**: Use descriptive statistics and visualizations.
- **Model Data**: Apply statistical or machine learning models.
- **Interpret Results**: Translate findings into actionable insights.
- **Communicate Findings**: Use dashboards, reports, or presentations.

---

### 2. **Data Types**

- **Numerical**: Continuous (e.g., height), Discrete (e.g., count)
- **Categorical**: Nominal (e.g., gender), Ordinal (e.g., rating)
- **Datetime**: Timestamps, durations
- **Text**: Unstructured data requiring NLP techniques

---

### 3. **Common Python Libraries**

| Purpose | Library | |--------|---------| | Data manipulation | `pandas`, `numpy` | | Visualization | `matplotlib`, `seaborn`, `plotly` | | Statistics | `scipy`, `statsmodels` | | Machine Learning | `scikit-learn`, `xgboost`, `lightgbm` | | NLP | `nltk`, `spaCy`, `transformers` | | Big Data | `dask`, `pyspark` | | SQL | `sqlite3`, `sqlalchemy`, `pandasql` |

---

### 4. **Data Cleaning Techniques**

- **Missing Values**: `df.fillna()`, `df.dropna()`
- **Duplicates**: `df.drop_duplicates()`
- **Outliers**: Z-score, IQR method
- **Data Types**: `df.astype()`
- **String Cleaning**: `.str.lower()`, `.str.strip()`, `.str.replace()`

---

### 5. **Exploratory Data Analysis (EDA)**

- **Summary Stats**: `df.describe()`, `df.info()`
- **Value Counts**: `df['col'].value_counts()`
- **Correlation**: `df.corr()`, `sns.heatmap()`
- **Visuals**:
    - Histogram: `sns.histplot()`
    - Boxplot: `sns.boxplot()`
    - Scatterplot: `sns.scatterplot()`
    - Pairplot: `sns.pairplot()`

---

### 6. **Statistical Concepts**

- **Mean, Median, Mode**
- **Standard Deviation, Variance**
- **Probability Distributions**: Normal, Binomial, Poisson
- **Hypothesis Testing**: t-test, chi-square test, ANOVA
- **Confidence Intervals**
- **P-value Interpretation**

---

### 7. **Feature Engineering**

- **Encoding**: One-hot, Label encoding
- **Scaling**: StandardScaler, MinMaxScaler
- **Binning**: `pd.cut()`, `pd.qcut()`
- **Datetime Features**: Extract day, month, weekday
- **Text Features**: TF-IDF, word embeddings

---

### 8. **Modeling Techniques**

- **Regression**: Linear, Logistic
- **Classification**: Decision Trees, Random Forest, SVM
- **Clustering**: K-Means, DBSCAN
- **Dimensionality Reduction**: PCA, t-SNE
- **Model Evaluation**:
    - Accuracy, Precision, Recall, F1-score
    - ROC-AUC
    - Confusion Matrix
    - Cross-validation

---

### 9. **SQL Essentials**

```sql
SELECT column FROM table;
WHERE condition;
GROUP BY column;
ORDER BY column DESC;
JOIN types: INNER, LEFT, RIGHT, FULL
```

---

### 10. **Visualization Tips**

- Use **bar charts** for categorical comparisons
- Use **line charts** for trends over time
- Use **scatter plots** for relationships
- Use **box plots** for distribution and outliers
- Use **heatmaps** for correlation matrices

---

### 11. **Reporting & Communication**

- Use **Jupyter Notebooks** for interactive analysis
- Use **Power BI / Tableau** for dashboards
- Use **Markdown** for documentation
- Use **Storytelling**: Context → Insight → Action

---

### 12. **Best Practices**

- Always **document** your process
- Use **version control** (e.g., Git)
- Validate assumptions with **statistical tests**
- Keep **data privacy** in mind
- Automate repetitive tasks with **scripts**

---

Would you like this cheat sheet as a downloadable PDF or formatted for printing? I can generate that for you!