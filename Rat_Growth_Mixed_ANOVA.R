## ----setup, include=FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  echo = TRUE,
  warning = FALSE,
  message = FALSE,
  fig.width = 6.5,
  fig.height = 4.2,
  fig.align = "center"
)


## ----load-data---------------------------------------------------------------------
# 1. Load required libraries
library(nlmm)
library(tidyverse)
library(rstatix)
library(ggpubr)

# 2. Load dataset
data("rats", package = "nlmm")

# 3. Format factor variables with clear labels
rats <- rats %>%
  mutate(
    id = factor(id),
    trt = factor(
      trt,
      levels = c(1, 2, 3),
      labels = c("Control", "Thiouracil", "Thyroxin")
    ),
    time = factor(
      time,
      levels = 0:4,
      labels = c("Week 0", "Week 1", "Week 2", "Week 3", "Week 4")
    )
  )

# 4. Inspect data structure
str(rats)
dim(rats)
head(rats)
table(rats$trt)


## ----descriptive-stats-------------------------------------------------------------
rats %>%
  group_by(trt, time) %>%
  get_summary_stats(y, type = "mean_sd")


## ----boxplot-----------------------------------------------------------------------
# Boxplot across time points by treatment group
ggboxplot(
  rats,
  x = "time",
  y = "y",
  color = "trt",
  palette = "jco",
  add = "jitter"
) +
  labs(
    title = "Body Weight Distribution Across Weeks by Treatment",
    x = "Measurement Occasion",
    y = "Body Weight (grams)",
    color = "Treatment"
  )


## ----interaction-plot--------------------------------------------------------------
# Interaction plot of mean body weights over time
rats %>%
  group_by(trt, time) %>%
  summarise(mean_weight = mean(y), .groups = "drop") %>%
  ggplot(aes(x = time, y = mean_weight, color = trt, group = trt)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  labs(
    title = "Mean Growth Trajectories by Treatment Group",
    x = "Measurement Occasion",
    y = "Mean Body Weight (grams)",
    color = "Treatment"
  ) +
  theme_minimal() +
  theme(legend.position = "top")


## ----normality-test----------------------------------------------------------------
# Shapiro-Wilk test per Treatment x Time combination
rats %>%
  group_by(trt, time) %>%
  shapiro_test(y)


## ----outlier-detection-------------------------------------------------------------
# Identify univariate extreme outliers
rats %>%
  group_by(trt, time) %>%
  identify_outliers(y)


## ----levene-test-------------------------------------------------------------------
# Conduct Levene's test at each measurement occasion
rats %>%
  group_by(time) %>%
  levene_test(y ~ trt)


## ----box-m-test--------------------------------------------------------------------
# Reshape data to wide format for Box's M test
rats_wide <- rats %>%
  pivot_wider(
    id_cols = c(id, trt),
    names_from = time,
    values_from = y,
    names_prefix = "time_"
  )

# Perform Box's M test (evaluate at alpha = 0.001)
box_m(
  rats_wide %>% select(starts_with("time_")),
  rats_wide$trt
)


## ----mixed-anova-------------------------------------------------------------------
# Fit mixed ANOVA
res.aov <- anova_test(
  data = rats,
  dv = y,
  wid = id,
  between = trt,
  within = time
)

# Display complete ANOVA and Sphericity output
res.aov

# Extract formatted ANOVA table
get_anova_table(res.aov)


## ----simple-main-treatment---------------------------------------------------------
# One-way ANOVA per time point
rats %>%
  group_by(time) %>%
  anova_test(dv = y, wid = id, between = trt) %>%
  get_anova_table() %>%
  knitr::kable(digits = 3)

# Tukey HSD pairwise comparisons per week (full labels, all 15 rows)
rats %>%
  group_by(time) %>%
  tukey_hsd(y ~ trt) %>%
  select(time, group1, group2, estimate, conf.low, conf.high, p.adj, p.adj.signif) %>%
  knitr::kable(digits = 3)



## ----simple-main-time--------------------------------------------------------------
# Repeated measures ANOVA per treatment group
rats %>%
  group_by(trt) %>%
  anova_test(dv = y, wid = id, within = time) %>%
  get_anova_table()

# Paired t-tests between weeks with Holm correction
rats %>%
  group_by(trt) %>%
  pairwise_t_test(
    y ~ time,
    paired = TRUE,
    p.adjust.method = "holm"
  ) %>%
  knitr::kable()

