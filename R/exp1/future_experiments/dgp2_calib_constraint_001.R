####### Stage1. Data Generation #######
source('../../data_gen/_step_8_calculater_roi.R')
source('../../data_gen/step_2_ads_spend_biased.R')
library('siMMMulator')
library('tidyr')
library('tidyverse')

# DataGenerationProcess: 2
# iterations: 1,000
# trials: 20
# calibration_constraint: 0.01

dgp_name <- 'dgp2_1000_20_001'
revenue_per_conv <- 1

my_variables <- step_0_define_basic_parameters(
  years = 5,
  channels_impressions = c("Facebook", "TV"),
  channels_clicks = c(),
  frequency_of_campaigns = 1,
  true_cvr = c(0.05, 0.02),
  revenue_per_conv = 1
)


df_baseline <- step_1_create_baseline(
  my_variables = my_variables,
  base_p = 500000,
  trend_p = 0.05,
  temp_var = 8,
  temp_coef_mean = 5000,
  temp_coef_sd = 5000,
  error_std = 5000
)

df_baseline

optional_step_1.5_plot_baseline_sales(df_baseline = df_baseline)

df_ads_step2 <- step_2_ads_spend_biased(
  my_variables = my_variables,
  spend_base <- c(70000, 200000),
  spend_trend <- c(0.0, 0.0),
  spend_temp_var <- c(0.0, 0.0),
  spend_temp_coef_mean <- c(5000, 7000),
  spend_temp_coef_sd <- c(500, 700),
  spend_error_std <- c(100, 100),
  spend_season_diff_week <- c(0, 0)
)
optional_step_2.5_plot_ad_spend(df_ads_step2 = df_ads_step2)

## Step 3
df_ads_step3 <- step_3_generate_media(
  my_variables = my_variables,
  df_ads_step2 = df_ads_step2,
  true_cpm = c(10, 10),
  true_cpc = c(),
  mean_noisy_cpm_cpc = c(1, 0.05),
  std_noisy_cpm_cpc = c(0.01, 0.15)
)
df_ads_step3

## Visualization of imp.
p3 <- ggplot(
  data = select(.data = df_ads_step3,
                c(
                  campaign_id, channel, lifetime_impressions
                )),
  aes(x = campaign_id,
      y = lifetime_impressions,
      group = channel)
) + geom_line(aes(color = channel)) #+ geom_point(aes(color = channel))
p3
df_ads_step4 <- step_4_generate_cvr(
  my_variables = my_variables,
  df_ads_step3 = df_ads_step3,
  mean_noisy_cvr = c(0, 0.000),
  std_noisy_cvr = c(0.0001, 0.0001)
)
colnames(df_ads_step4)
p4 <- ggplot(data = select(.data = df_ads_step4,
                           c(campaign_id, channel, noisy_cvr)),
             aes(x = campaign_id,
                 y = noisy_cvr,
                 group = channel)) + geom_line(aes(color = channel)) #+ geom_point(aes(color = channel))
p4
df_ads_step5a_before_mmm <- step_5a_pivot_to_mmm_format(my_variables = my_variables,
                                                        df_ads_step4 = df_ads_step4)
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
df_ads_step6 <- step_6_calculating_conversions(my_variables = my_variables,
                                               df_ads_step5c = df_ads_step5c)
df_ads_step6
df_ads_step7 <- step_7_expanded_df(
  my_variables = my_variables,
  df_ads_step6 = df_ads_step6,
  df_baseline = df_baseline
)

df_final <- step_9_final_df(my_variables = my_variables,
                            df_ads_step7 = df_ads_step7)
df_final$baseline_sales <- df_baseline$baseline_sales

# todo: for loop
df_final$tv_incremental <-
  df_final$baseline_sales + df_ads_step7$conv_TV
df_final$fb_incremental <-
  df_final$baseline_sales + df_ads_step7$conv_Facebook
df_final %>%
  select(.,
         c(
           DATE,
           total_revenue,
           baseline_sales,
           tv_incremental,
           fb_incremental
         )) %>%
  tidyr::gather(
    key = "rev_type",
    value = "rev",
    total_revenue,
    baseline_sales,
    tv_incremental,
    fb_incremental
  ) %>%
  ggplot(data = .,
         aes(x = DATE,
             y = rev,
             group = rev_type)) + geom_line(aes(color = rev_type)) #+ geom_point(aes(color = rev_type))

true_roi <- step_8_calculate_roi(my_variables = my_variables,
                     df_ads_step7 = df_ads_step7)

df_ads_step7

df_final_cv = dplyr::inner_join(df_final, df_ads_step7[, c("DATE", "conv_Facebook", "conv_TV")], by='DATE')
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


for (use_prophet in c(TRUE, FALSE)) {
  for (calib in list(NULL, c("spend_Facebook"), c("spend_TV"), c("spend_Facebook", "spend_TV"))) {
    
    # Init 
    InputCollect <- NULL
    
    print("==================")
    print("USE_PROPHET: ")
    print(use_prophet)
    print("CALIBRATION: ")
    print(calib)
    print("==================")
    
    # Directory where you want to export results to (will create new folders)
    robyn_object <- paste("~/Desktop/", paste(dgp_name, "/", sep=""), "prophet_", use_prophet, "_calib_", paste(calib, collapse="_"), sep="")
    print(robyn_object)
    dir.create(robyn_object[length(robyn_object)], showWarnings = FALSE, recursive=TRUE)
    
    if (use_prophet) {
      prophet_vars <- c("trend", "season", "holiday") # "trend","season", "weekday" & "holiday"
    } else {
      prophet_vars <- c()
    }
    
    InputCollect <- robyn_inputs(
      dt_input = df_final_cv,
      dt_holidays = dt_prophet_holidays,
      date_var = "DATE", # date format must be "2020-01-01"
      dep_var = "revenue", # there should be only one dependent variable
      dep_var_type = "revenue", # "revenue" (ROI) or "conversion" (CPA)
      prophet_vars = prophet_vars,
      prophet_country = "DE", # input one country. dt_prophet_holidays includes 59 countries by default
      # context_vars = c("competitor_sales_B", "events"), # e.g. competitors, discount, unemployment etc
      paid_media_spends = c("spend_Facebook", "spend_TV"), # mandatory input
      paid_media_vars = c("impressions_Facebook", "impressions_TV"), # mandatory.
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
    
    
    # Run hyper_limits() to check maximum upper and lower bounds by range
    # Example hyperparameters ranges for Geometric adstock
    hyperparameters <- list(
      spend_Facebook_alphas = c(0.5, 3),
      spend_Facebook_gammas = c(0.3, 1),
      spend_Facebook_thetas = c(0, 0.3),
      spend_TV_alphas = c(0.5, 3),
      spend_TV_gammas = c(0.3, 1),
      spend_TV_thetas = c(0.1, 0.4)
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
    calib_lift_f <- sum(df_range[c("conv_Facebook")]) * revenue_per_conv
    calib_spend_f <- sum(df_range[c("spend_Facebook")])
    calib_lift_t <- sum(df_range[c("conv_TV")]) * revenue_per_conv
    calib_spend_t <- sum(df_range[c("spend_TV")])
    
    if (!is.null(calib)) {
      if (length(calib) == 2) {
        liftAbs <- c(calib_lift_f, calib_lift_t)
        spend <- c(calib_spend_f, calib_spend_t)
      } else if (any(calib == "spend_Facebook")) {
        liftAbs <- c(calib_lift_f)
        spend <- c(calib_spend_f)
      } else {
        liftAbs <- c(calib_lift_t)
        spend <- c(calib_spend_t)
      }
      
      calibration_input <- data.frame(
        # channel name must in paid_media_vars
        channel = calib,
        # liftStartDate must be within input data range
        liftStartDate = as.Date(rep("2017-01-01", each=length(calib))),
        # liftEndDate must be within input data range
        liftEndDate = as.Date(rep("2017-03-05", each=length(calib))),
        # Provided value must be tested on same campaign level in model and same metric as dep_var_type
        liftAbs = liftAbs,
        # Spend within experiment: should match within a 10% error your spend on date range for each channel from dt_input
        spend = spend,
        # Confidence: if frequentist experiment, you may use 1 - pvalue
        confidence = rep(0.95, each=length(calib)),
        # KPI measured: must match your dep_var
        metric = rep("revenue", each=length(calib)),
        # Either "immediate" or "total". For experimental inputs like Facebook Lift, "immediate" is recommended.
        calibration_scope = rep("immediate", each=length(calib))
      )
      InputCollect <- robyn_inputs(InputCollect = InputCollect, calibration_input = calibration_input)
    }
    
    ################################################################
    #### Step 3: Build initial model
    # Try to use nevergrads.
    # conda_create("r-reticulate", "python=3.9")
    # use_condaenv("r-reticulate")
    # conda_install("r-reticulate", "nevergrad", pip=TRUE)
    # Sys.setenv(RETICULATE_PYTHON = "/Users/sxxxxxx/opt/anaconda3/envs/r-reticulate/bin/python")
    ## Run all trials and iterations. Use ?robyn_run to check parameter definition
    OutputModels <- robyn_run(
      InputCollect = InputCollect, # feed in all model specification
      # cores = NULL, # default to max available
      # add_penalty_factor = FALSE, # Untested feature. Use with caution.
      iterations = 1000, # recommended for the dummy dataset
      trials = 20, # recommended for the dummy dataset
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
      calibration_constraint = 0.01, # range c(0.01, 0.1) & default at 0.1
      csv_out = "pareto", # "pareto" or "all"
      clusters = TRUE, # Set to TRUE to cluster similar models by ROAS. See ?robyn_clusters
      plot_pareto = TRUE, # Set to FALSE to deactivate plotting and saving model one-pagers
      plot_folder = robyn_object[length(robyn_object)]
      # plot_folder = paste("~/Desktop/", dgp_name, sep=""),# path for plots export
      # plot_folder_sub = paste("prophet_", use_prophet, "_calib_", calib, sep="")
    )
    print(OutputCollect)
    
    ################################################################
    #### Step 4: Select and save the any model
    
    ## Compare all model one-pagers and select one that mostly reflects your business reality
    
    for (select_model in OutputCollect$clusters$models$solID) {
      #### Since 3.7.1: JSON export and import (faster and lighter than RDS files)
      ExportedModel <- robyn_write(InputCollect, OutputCollect, select_model, dir = robyn_object[length(robyn_object)])
      robyn_write(InputCollect, OutputCollect, select_model, dir = robyn_object[length(robyn_object)])
      print(select_model)
      print(ExportedModel)
    }
    
    ############ WRITE ############
    # Manually create JSON file with inputs data only
    robyn_write(InputCollect, dir = robyn_object[length(robyn_object)])
    
    # Manually create JSON file with inputs and specific model results
    robyn_write(InputCollect, OutputCollect, select_model, dir = robyn_object[length(robyn_object)])
    
    write.csv(true_roi, file= paste(robyn_object[length(robyn_object)], "/true_roi.csv", sep=""), row.names=F)
  }
}

