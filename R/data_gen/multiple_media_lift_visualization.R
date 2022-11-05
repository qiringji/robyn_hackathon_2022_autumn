library(siMMMulator)
library(tidyverse)

my_variables <- step_0_define_basic_parameters(
  years = 5,
  channels_impressions = c("Facebook", "TV"),
  channels_clicks = c(),
  frequency_of_campaigns = 1,
  true_cvr = c(0.015, 0.02),
  revenue_per_conv = 1
)


df_baseline <- step_1_create_baseline(
  my_variables = my_variables,
  base_p = 500000,
  trend_p = 1.05,
  temp_var = 8,
  temp_coef_mean = 5000,
  temp_coef_sd = 500,
  error_std = 5000
)
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
  true_cpm = c(6, 20),
  true_cpc = c(),
  mean_noisy_cpm_cpc = c(1, 0.05),
  std_noisy_cpm_cpc = c(0.01, 0.15)
)
df_ads_step3
typeof(dframe_ads_step3)
class(df_ads_step3)
df_ads_step3$channel
## imp数の可視化
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
  mean_noisy_cvr = c(0, 0.0001),
  std_noisy_cvr = c(0.001, 0.002)
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
step_8_calculate_roi(my_variables = my_variables,
                     df_ads_step7 = df_ads_step7)
df_final <- step_9_final_df(my_variables = my_variables,
                            df_ads_step7 = df_ads_step7)
df_final$baseline_sales <- df_baseline$baseline_sales
# todo: これをfor文的にやる方法
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

