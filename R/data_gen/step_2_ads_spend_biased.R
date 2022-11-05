## todo 

step_2_ads_spend_biased <- function(my_variables = my_variables,
                                    spend_base,
                                    spend_trend,
                                    spend_temp_var,
                                    spend_temp_coef_mean,
                                    spend_temp_coef_sd,
                                    spend_error_std,
                                    spend_season_diff_week
){
  # calculate some variables to be used in input of data frame
  years <- my_variables[[1]]
  channels_impressions <- my_variables[[2]] # 早川記 こいつをうまく使う
  channels_clicks <- my_variables[[3]]
  frequency_of_campaigns <- my_variables[[4]]
  
  channels <- c(channels_impressions, channels_clicks)
  channels <- channels[!is.na(channels)] # only keep the non-NA channels
  n_channels <- length(channels)
  n_weeks <- years*52
  n_campaigns <- n_weeks/frequency_of_campaigns
  
  # todo 
  
  df_ads_step2_biased <- data.frame(
    matrix(
      nrow = n_campaigns, 
      ncol = n_channels + 1, 
      dimnames = list(c(), c("campaign_id",channels))
    )
  )
  
  campaigns <- 1:n_campaigns
  df_ads_step2_biased[1] = campaigns
  
  channels
  
  campaigns
  campaigns*3.14/26
  
  for(i in 1:n_channels) {
    base <- rep(spend_base[i], n_campaigns) #横線
    trend_cal <- (spend_trend[i] / n_campaigns) * spend_base[i] 
    trend <- trend_cal*campaigns # トレンド
    temp <- spend_temp_var[i] * sin((campaigns - spend_season_diff_week[i])*3.14/26)
    seasonality <- rnorm(1, mean = spend_temp_coef_mean[i], sd = spend_temp_coef_sd[i]) * temp # 季節性
    error <- rnorm(n_campaigns, mean = 0, sd = spend_error_std[i] )
    spend <- base + trend + seasonality + error
    df_ads_step2_biased[i + 1] = spend
  }
  
  
  df_ads_step2_biased <- df_ads_step2_biased %>%
    pivot_longer(
      cols = all_of(channels), 
      names_to = 'channel', 
      values_to = 'spend_channel'
    ) %>%
    group_by(. , campaign_id) %>%
    mutate(total_campaign_spend = sum(spend_channel)) %>%
    mutate(channel_prop_spend = spend_channel / total_campaign_spend) %>%
    ungroup() %>%
    select(campaign_id, channel, total_campaign_spend, channel_prop_spend, spend_channel)
  
  
  return(df_ads_step2_biased)
  
  
}
