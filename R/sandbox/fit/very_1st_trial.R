####### Stage1. Data Generation #######
# install siMMMulator 
remotes::install_github(
  repo = "facebookexperimental/siMMMulator"
)

library(siMMMulator)
revenue_per_conv <- 1

my_variables <- step_0_define_basic_parameters(
  years = 5,
  channels_impressions = c("Facebook", "TV"),
  channels_clicks = c(),
  frequency_of_campaigns = 1,
  true_cvr = c(0.001, 0.002),
  revenue_per_conv = revenue_per_conv
)

df_baseline <- step_1_create_baseline(
  my_variables = my_variables,
  base_p = 500000,
  trend_p = 1.8,
  temp_var = 8,
  temp_coef_mean = 50000,
  temp_coef_sd = 5000,
  error_std = 100000)

optional_step_1.5_plot_baseline_sales(df_baseline = df_baseline)

df_ads_step2 <- step_2_ads_spend(
  my_variables = my_variables,
  campaign_spend_mean = 329000,
  campaign_spend_std = 10000,
  max_min_proportion_on_each_channel <- c(0.85, 0.95) #ここで予算の分担を行っている
)

optional_step_2.5_plot_ad_spend(df_ads_step2 = df_ads_step2)


## Step 3 
df_ads_step3 <- step_3_generate_media(
  my_variables = my_variables,
  df_ads_step2 = df_ads_step2,
  true_cpm = c(2, 20),
  true_cpc = c(),
  mean_noisy_cpm_cpc = c(1, 0.05),
  std_noisy_cpm_cpc = c(0.01, 0.15)
)

df_ads_step3
class(df_ads_step3)

df_ads_step3$channel

library(tidyverse)

## imp数の可視化
p3 <- ggplot(
  data =select(
    .data = df_ads_step3,
    c(campaign_id, channel, lifetime_impressions)
  ),
  aes(
    x= campaign_id,
    y = lifetime_impressions,
    group = channel
    )
) + geom_line(aes(color=channel)) + geom_point(aes(color = channel))

p3

# Step4 

df_ads_step4 <- step_4_generate_cvr(
  my_variables = my_variables,
  df_ads_step3 = df_ads_step3,
  mean_noisy_cvr = c(0, 0.0001),
  std_noisy_cvr = c(0.001, 0.002)
)

colnames(df_ads_step4)

p4 <- ggplot(
  data =select(
    .data = df_ads_step4,
    c(campaign_id, channel, noisy_cvr)
  ),
  aes(
    x= campaign_id,
    y = noisy_cvr,
    group = channel
  )
) + geom_line(aes(color=channel)) + geom_point(aes(color = channel))

p4

df_ads_step5a_before_mmm <- step_5a_pivot_to_mmm_format(
  my_variables = my_variables,
  df_ads_step4 = df_ads_step4
)

df_ads_step5b <- step_5b_decay(
  my_variables = my_variables,
  df_ads_step5a_before_mmm = df_ads_step5a_before_mmm,
  true_lambda_decay = c(0.1, 0.2)
)

df_ads_step5c <- step_5c_diminishing_returns(
  my_variables = my_variables,
  df_ads_step5b = df_ads_step5b,
  alpha_saturation = c(4, 3),
  gamma_saturation = c(0.2, 0.3)
)

df_ads_step6 <- step_6_calculating_conversions(
  my_variables = my_variables,
  df_ads_step5c = df_ads_step5c
)

df_ads_step7 <- step_7_expanded_df(
  my_variables = my_variables,
  df_ads_step6 = df_ads_step6,
  df_baseline = df_baseline
)

step_8_calculate_roi(
  my_variables = my_variables,
  df_ads_step7 = df_ads_step7
)

df_final <- step_9_final_df(
  my_variables = my_variables,
  df_ads_step7 = df_ads_step7
)

df_final$baseline_sales <- df_baseline$baseline_sales


df_final

df_final %>% 
  select(., c(DATE, total_revenue, baseline_sales)) %>% 
  tidyr::gather(key = "rev_type", value="rev", total_revenue, baseline_sales) %>%
  ggplot(
    data = .,
    aes(
      x= DATE,
      y = rev,
      group = rev_type
    )
  ) + geom_line(aes(color=rev_type)) + geom_point(aes(color = rev_type))


df_ads_step7

df_final_cv = dplyr::inner_join(df_final, df_ads_step7, by='DATE')
colnames(df_final_cv)[2] <- 'revenue'

####### Stage2. MMM #######
# Robyn
library(Robyn) # remotes::install_github("facebookexperimental/Robyn/R")

# Please, check if you have installed the latest version before running this demo. Update if not
# https://github.com/facebookexperimental/Robyn/blob/main/R/DESCRIPTION#L4
packageVersion("Robyn")

## Force multicore when using RStudio
Sys.setenv(R_FUTURE_FORK_ENABLE = "true")
options(future.fork.enable = TRUE)

library("reticulate") # Load the library

df_final_cv

# Directory where you want to export results to (will create new folders)
robyn_object <- "~/Desktop"

InputCollect <- robyn_inputs(
  dt_input = df_final_cv,
  dt_holidays = dt_prophet_holidays,
  date_var = "DATE", # date format must be "2020-01-01"
  dep_var = "revenue", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (ROI) or "conversion" (CPA)
  prophet_vars = c("trend", "season", "holiday"), # "trend","season", "weekday" & "holiday"
  prophet_country = "DE", # input one country. dt_prophet_holidays includes 59 countries by default
  # context_vars = c("competitor_sales_B", "events"), # e.g. competitors, discount, unemployment etc
  paid_media_spends = c("spend_Facebook.x", "spend_TV.x"), # mandatory input
  paid_media_vars = c("impressions_Facebook.x", "impressions_TV.x"), # mandatory.
  # paid_media_vars must have same order as paid_media_spends. Use media exposure metrics like
  # impressions, GRP etc. If not applicable, use spend instead.
  # factor_vars = c("events"), # force variables in context_vars or organic_vars to be categorical
  window_start = "2017-01-01",
  window_end = "2021-12-19",
  adstock = "geometric" # geometric, weibull_cdf or weibull_pdf.
)
print(InputCollect)

#### 2a-2: Second, define and add hyperparameters
hyper_names(adstock = InputCollect$adstock, all_media = InputCollect$all_media)

## 1. IMPORTANT: set plot = TRUE to see helper plots of hyperparameter's effect in transformation
plot_adstock(plot = TRUE)
plot_saturation(plot = FALSE)

# Run hyper_limits() to check maximum upper and lower bounds by range
# Example hyperparameters ranges for Geometric adstock
hyperparameters <- list(
  spend_Facebook.x_alphas = c(0.5, 3),
  spend_Facebook.x_gammas = c(0.3, 1),
  spend_Facebook.x_thetas = c(0, 0.3),
  spend_TV.x_alphas = c(0.5, 3),
  spend_TV.x_gammas = c(0.3, 1),
  spend_TV.x_thetas = c(0.1, 0.4)
)


#### 2a-3: Third, add hyperparameters into robyn_inputs()

InputCollect <- robyn_inputs(InputCollect = InputCollect, hyperparameters = hyperparameters)
print(InputCollect)


################################################################
#### Step 2b: For known model specification, setup in one single step


#### Check spend exposure fit if available
if (length(InputCollect$exposure_vars) > 0) {
  InputCollect$modNLS$plots$facebook_I
  InputCollect$modNLS$plots$search_clicks_P
}

######################
# Calibration

# calculation of lift, sum(conversion) * revenue_per_cv.
df_range <- df_final_cv %>% filter(DATE >= "2017-01-01" & DATE <= "2017-03-05")
df_range
calib_lift <- sum(df_range[c("conv_Facebook")]) * revenue_per_conv
calib_spend <- sum(df_range[c("spend_Facebook.x")])

calibration_input <- data.frame(
  # channel name must in paid_media_vars
  channel = c("spend_Facebook.x"),
  # liftStartDate must be within input data range
  liftStartDate = as.Date(c("2017-01-01")),
  # liftEndDate must be within input data range
  liftEndDate = as.Date(c("2017-03-05")),
  # Provided value must be tested on same campaign level in model and same metric as dep_var_type
  liftAbs = c(calib_lift),
  # Spend within experiment: should match within a 10% error your spend on date range for each channel from dt_input
  spend = c(calib_spend),
  # Confidence: if frequentist experiment, you may use 1 - pvalue
  confidence = c(0.95),
  # KPI measured: must match your dep_var
  metric = c("revenue"),
  # Either "immediate" or "total". For experimental inputs like Facebook Lift, "immediate" is recommended.
  calibration_scope = c("immediate")
)
InputCollect <- robyn_inputs(InputCollect = InputCollect, calibration_input = calibration_input)


################################################################
#### Step 3: Build initial model
# Try to use nevergrads.
# conda_create("r-reticulate", "python=3.9")
# use_condaenv("r-reticulate")
# conda_install("r-reticulate", "nevergrad", pip=TRUE)
# Sys.setenv(RETICULATE_PYTHON = "/Users/s11616/opt/anaconda3/envs/r-reticulate/bin/python")
## Run all trials and iterations. Use ?robyn_run to check parameter definition
OutputModels <- robyn_run(
  InputCollect = InputCollect, # feed in all model specification
  # cores = NULL, # default to max available
  # add_penalty_factor = FALSE, # Untested feature. Use with caution.
  iterations = 2000, # recommended for the dummy dataset
  trials = 5, # recommended for the dummy dataset
  outputs = FALSE # outputs = FALSE disables direct model output - robyn_outputs()
)
print(OutputModels)

## Check MOO (multi-objective optimization) convergence plots
OutputModels$convergence$moo_distrb_plot
OutputModels$convergence$moo_cloud_plot
# check convergence rules ?robyn_converge

## Calculate Pareto optimality, cluster and export results and plots. See ?robyn_outputs
OutputCollect <- robyn_outputs(
  InputCollect, OutputModels,
  # pareto_fronts = "auto",
  # calibration_constraint = 0.1, # range c(0.01, 0.1) & default at 0.1
  csv_out = "pareto", # "pareto" or "all"
  clusters = TRUE, # Set to TRUE to cluster similar models by ROAS. See ?robyn_clusters
  plot_pareto = TRUE, # Set to FALSE to deactivate plotting and saving model one-pagers
  plot_folder = robyn_object # path for plots export
)
print(OutputCollect)

################################################################
#### Step 4: Select and save the any model

## Compare all model one-pagers and select one that mostly reflects your business reality
print(OutputCollect)
select_model <- "1_105_3" # Pick one of the models from OutputCollect to proceed

#### Since 3.7.1: JSON export and import (faster and lighter than RDS files)
ExportedModel <- robyn_write(InputCollect, OutputCollect, select_model)
print(ExportedModel)

############ WRITE ############
# Manually create JSON file with inputs data only
robyn_write(InputCollect, dir = "~/Desktop")

# Manually create JSON file with inputs and specific model results
robyn_write(InputCollect, OutputCollect, select_model)
