# install siMMMulator 
remotes::install_github(
  repo = "facebookexperimental/siMMMulator"
)

library(siMMMulator)

my_variables <- step_0_define_basic_parameters(
  years = 5,
  channels_impressions = c("Facebook", "TV"),
  channels_clicks = c(),
  frequency_of_campaigns = 1,
  true_cvr = c(0.001, 0.002),
  revenue_per_conv = 1
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

df_final_cv.column

# Robyn
library(Robyn) # remotes::install_github("facebookexperimental/Robyn/R")

# Please, check if you have installed the latest version before running this demo. Update if not
# https://github.com/facebookexperimental/Robyn/blob/main/R/DESCRIPTION#L4
packageVersion("Robyn")

## Force multicore when using RStudio
Sys.setenv(R_FUTURE_FORK_ENABLE = "true")
options(future.fork.enable = TRUE)

library("reticulate") # Load the library

# Directory where you want to export results to (will create new folders)
robyn_object <- "~/Desktop"

InputCollect <- robyn_inputs(
  dt_input = df_final_cv,
  dt_holidays = dt_prophet_holidays,
  date_var = "DATE", # date format must be "2020-01-01"
  dep_var = "total_revenue.x", # there should be only one dependent variable
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

################################################################
#### Step 3: Build initial model

## Run all trials and iterations. Use ?robyn_run to check parameter definition
OutputModels <- robyn_run(
  InputCollect = InputCollect, # feed in all model specification
  # cores = NULL, # default to max available
  # add_penalty_factor = FALSE, # Untested feature. Use with caution.
  iterations = 500, # recommended for the dummy dataset
  trials = 2, # recommended for the dummy dataset
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
select_model <- "1_11_12" # Pick one of the models from OutputCollect to proceed

#### Since 3.7.1: JSON export and import (faster and lighter than RDS files)
ExportedModel <- robyn_write(InputCollect, OutputCollect, select_model)
print(ExportedModel)

################################################################
#### Step 5: Get budget allocation based on the selected model above

## Budget allocation result requires further validation. Please use this recommendation with caution.
## Don't interpret budget allocation result if selected model above doesn't meet business expectation.

# Check media summary for selected model
print(ExportedModel)

# Run ?robyn_allocator to check parameter definition
# Run the "max_historical_response" scenario: "What's the revenue lift potential with the
# same historical spend level and what is the spend mix?"
AllocatorCollect1 <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  scenario = "max_historical_response",
  channel_constr_low = 0.7,
  channel_constr_up = c(1.2, 1.5),
  export = TRUE,
  date_min = "2017-01-01",
  date_max = "2021-12-19"
)
print(AllocatorCollect1)
# plot(AllocatorCollect1)

# Run the "max_response_expected_spend" scenario: "What's the maximum response for a given
# total spend based on historical saturation and what is the spend mix?" "optmSpendShareUnit"
# is the optimum spend share.
AllocatorCollect2 <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  scenario = "max_response_expected_spend",
  channel_constr_low = c(0.7, 0.7),
  channel_constr_up = c(1.2, 1.5),
  expected_spend = 1000000, # Total spend to be simulated
  expected_spend_days = 7, # Duration of expected_spend in days
  export = TRUE
)
print(AllocatorCollect2)
AllocatorCollect2$dt_optimOut
# plot(AllocatorCollect2)

## A csv is exported into the folder for further usage. Check schema here:
## https://github.com/facebookexperimental/Robyn/blob/main/demo/schema.R

## QA optimal response
# Pick any media variable: InputCollect$all_media
select_media <- "spend_Facebook.x"
# For paid_media_spends set metric_value as your optimal spend
metric_value <- AllocatorCollect1$dt_optimOut$optmSpendUnit[
  AllocatorCollect1$dt_optimOut$channels == select_media
]; metric_value
# # For paid_media_vars and organic_vars, manually pick a value
# metric_value <- 10000

if (TRUE) {
  optimal_response_allocator <- AllocatorCollect1$dt_optimOut$optmResponseUnit[
    AllocatorCollect1$dt_optimOut$channels == select_media
  ]
  optimal_response <- robyn_response(
    InputCollect = InputCollect,
    OutputCollect = OutputCollect,
    select_model = select_model,
    select_build = 0,
    media_metric = select_media,
    metric_value = metric_value
  )
  plot(optimal_response$plot)
  if (length(optimal_response_allocator) > 0) {
    cat("QA if results from robyn_allocator and robyn_response agree: ")
    cat(round(optimal_response_allocator) == round(optimal_response$response), "( ")
    cat(optimal_response$response, "==", optimal_response_allocator, ")\n")
  }
}

################################################################
#### Step 6: Model refresh based on selected model and saved results "Alpha" [v3.7.1]

## Must run robyn_write() (manually or automatically) to export any model first, before refreshing.
## The robyn_refresh() function is suitable for updating within "reasonable periods".
## Two situations are considered better to rebuild model:
## 1. most data is new. If initial model has 100 weeks and 80 weeks new data is added in refresh,
## it might be better to rebuild the model. Rule of thumb: 50% of data or less can be new.
## 2. new variables are added.

# Provide JSON file with your InputCollect and ExportedModel specifications
# It can be any model, initial or a refresh model
json_file <- "~/Desktop/Robyn_202211042030_init/RobynModel-1_11_12.json"
RobynRefresh <- robyn_refresh(
  json_file = json_file,
  dt_input = df_final_cv,
  dt_holidays = dt_prophet_holidays,
  refresh_steps = 13,
  refresh_iters = 1000, # 1k is an estimation
  refresh_trials = 1
)


################################################################
#### Step 7: Get budget allocation recommendation based on selected refresh runs

# Run ?robyn_allocator to check parameter definition
AllocatorCollect <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  scenario = "max_response_expected_spend",
  channel_constr_low = c(0.7, 0.7),
  channel_constr_up = c(1.2, 1.5),
  expected_spend = 2000000, # Total spend to be simulated
  expected_spend_days = 14 # Duration of expected_spend in days
)
print(AllocatorCollect)
# plot(AllocatorCollect)

################################################################
#### Step 8: get marginal returns


# Get response for 80k from result saved in robyn_object
Spend1 <- 60000
Response1 <- robyn_response(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  media_metric = "impressions_Facebook.x",
  metric_value = Spend1
)
Response1$response / Spend1 # ROI for search 80k
Response1$plot


# Get response for +10%
Spend2 <- Spend1 * 1.1
Response2 <- robyn_response(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  media_metric = "impressions_Facebook.x",
  metric_value = Spend2
)
Response2$response / Spend2 # ROI for search 81k
Response2$plot

# Marginal ROI of next 1000$ from 80k spend level for search
(Response2$response - Response1$response) / (Spend2 - Spend1)

## Example of getting paid media exposure response curves
imps <- 50000000
response_imps <- robyn_response(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  media_metric = "impressions_Facebook.x",
  metric_value = imps
)
response_imps$response / imps * 1000
response_imps$plot

## Example of getting organic media exposure response curves
sendings <- 30000
response_sending <- robyn_response(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  media_metric = "impressions_Facebook.x",
  metric_value = sendings
)
response_sending$response / sendings * 1000
response_sending$plot


############ WRITE ############
# Manually create JSON file with inputs data only
robyn_write(InputCollect, dir = "~/Desktop")

# Manually create JSON file with inputs and specific model results
robyn_write(InputCollect, OutputCollect, select_model)


# TODO: calculate lift (sum * revenue_per_cv)
df_final_cv %>% filter(DATE >= "2017-01-01" & DATE <= "2017-03-05")

######################
# Calibration
calibration_input <- data.frame(
   # channel name must in paid_media_vars
   channel = c("spend_Facebook.x"),
   # liftStartDate must be within input data range
   liftStartDate = as.Date(c("2018-05-01")),
   # liftEndDate must be within input data range
   liftEndDate = as.Date(c("2017-03-05")),
   # Provided value must be tested on same campaign level in model and same metric as dep_var_type
   liftAbs = c(400000),
   # Spend within experiment: should match within a 10% error your spend on date range for each channel from dt_input
   spend = c(421000),
   # Confidence: if frequentist experiment, you may use 1 - pvalue
   confidence = c(0.95),
   # KPI measured: must match your dep_var
   metric = c("revenue"),
   # Either "immediate" or "total". For experimental inputs like Facebook Lift, "immediate" is recommended.
   calibration_scope = c("immediate")
 )
InputCollect <- robyn_inputs(InputCollect = InputCollect, calibration_input = calibration_input)

# TODO：refresh