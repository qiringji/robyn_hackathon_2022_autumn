# Copyright (c) Meta Platforms, Inc. and affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

####################################################################

#' Step 2: Generate Ad Spend
#'
#' Simulates how much to spend on each ad campaign and channel
#'
#' @param my_variables A list that was created after running step 0. It stores the inputs you've specified.
#' @param campaign_spend_mean A numeric, the average amount of money spent on a campaign, must be in same currency as baseline sales generated in step 1
#' @param campaign_spend_std A numeric, the standard deviation of money spent on a campaign, must be in same currency as baseline sales generated in step 1
#' @param max_min_proportion_on_each_channel A vector of numerics specifying the minimum and maximum percentages of total spend allocated to each channel, should be in the same order as channels specified (channels that use impressions first followed by channels that use clicks), length should be 2 times (number of total channels - 1)
#'
#' @return A data frame with amounts of money spent on each campaign and media channel
#'
#' @importFrom dplyr mutate
#' @importFrom magrittr %>%
#' @importFrom stats runif
#'
#' @export
#'
#' @examples
#' \dontrun{
#' step_2_ads_spend(
#' my_variables = my_variables,
#' campaign_spend_mean = 329000,
#' campaign_spend_std = 100000,
#' max_min_proportion_on_each_channel <- c(0.45, 0.55,
#' 0.15, 0.25,
#' 0.1, 0.2)
#' )
#' }

step_2_ads_spend_biased <- function(my_variables = my_variables,
                                    # 早川記 入力として 複数の base, 複数のtrend, 複数のvarをもらうようにする
                                    channel_spend_base,
                                    channel_spend_trend,
                                    channel_spend_var
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
  
  # Display error messages for invalid inputs
  
  ## それぞれの次元がchannnel_impressions + channel_clicksの次元と整合性があることを確認
  
  # initialize local variables to use later on
  total_campaign_spend <- NA
  channel_prop_spend <- NA
  channel_prop_spend <- NA
  total_campaign_spend <- NA
  
  
  
    
  # specify amount spent on each campaign according to a normal distribution
  campaign_spends <- rnorm(n_campaigns, mean = campaign_spend_mean, sd = campaign_spend_std)
  
  # 早川記 全体のspend自体がランダムに決まるが、これをやめたい気がする
  
  
  # if campaign spend number is negative, automatically make it 0
  campaign_spends[campaign_spends<0] <- 0
  
  
  # specify the amount spend on each channel for each campaign
  ## proportions spent on each channel are randomly generated proportions drawn from a uniform distribution of numbers between inputs user identifies
  proportion_strings_list <- vector(mode = "list", length = n_campaigns)
  for(i in 1:n_campaigns) { # replace 1 with n_campaigns
    total_proportion_campaign <- 0
    for (j in 1:(n_channels-1)) {
      proportion_strings_list[[i]][j] <- runif(1, min = max_min_proportion_on_each_channel[(2*j)-1], max = max_min_proportion_on_each_channel[2*j]) # 早川記 maxとminの割合からproportionのリストを生成
      total_proportion_campaign <- total_proportion_campaign + proportion_strings_list[[i]][j]
    }
    proportion_strings_list[[i]][n_channels] <- 1 - total_proportion_campaign
  }
  
  ## output
  output <- data.frame(campaign_id = rep(1:n_campaigns, each = n_channels),
                       channel = rep(channels, n_campaigns),
                       total_campaign_spend = rep(campaign_spends, each = n_channels),
                       channel_prop_spend = unlist(proportion_strings_list, use.names = FALSE)) %>%
    mutate(spend_channel = total_campaign_spend*channel_prop_spend) # calculate the spend on each channel #ここで計算している。
  
  print("You have completed running step 2: Simulating ad spend.")
  
  
  # 最後このフォーマットに直す
  #campaign_id  channel total_campaign_spend channel_prop_spend spend_channel
  #1             1 Facebook             337370.8         0.91295098     308003.01
  #2             1       TV             337370.8         0.08704902      29367.80
  #3             2 Facebook             329931.2         0.86609924     285753.16
  #4             2       TV             329931.2         0.13390076      44178.04
  #5             3 Facebook             322245.0         0.94809211     305517.96
  
  
  return(output)
  
  
}
