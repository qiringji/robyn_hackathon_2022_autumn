# robyn_hackathon_2022_autumn

## Inspiration

As [Chan et al. 2017] claim, general MMM does not produce causal results but correlational results.

To tackle with this problem, Robyn allows us to calibrate with the estimated causal effects from RCT or quasi-experiments. But no existing studies clarify the following questions.

- On which media?：
    - We confuse which media we should conduct experiments on or if it's enough to do a lot of experiments only on single media.
- How many times?：
    - No answer exists on how many experiments we conduct on single media to estimate ROI accurately.

We try to adress these two questions by conducting analysis with synthetic data.

## What it does

- We add an implementation of realistic data generation processes to the siMMMulator, which is an open source R-package for generating dataset for MMM.
- We conduct analysis to confirm experiments on multiple media make Robyn's ROI estimation much better.
- We conduct analysis to confirm multi-time experiment on each media make Robyn's ROI estimation accurate.


## How we built it

### Preparation：Add implementations in siMMMulator
#### Correlated ad spending and sales history
- There are a lot of biases in real-world data. The biases make Robyn's ROI estimation inaccurate.
- We add implementations to siMMMulator.
    - Correlation between media spend and organic sales.
    - Correlation between media spends.
    - Cyclic seasonality and events.
- `R/data_gen/`.

![image](https://user-images.githubusercontent.com/40241649/201340102-64a45ceb-7000-41dd-8ebb-36698ec68a6b.png)
![image](https://user-images.githubusercontent.com/40241649/201340149-720149e3-b795-4c85-add8-d08458885bcf.png)

#### causal effect (lift) estimation.
- We also generate causal effect (lift) esimation process.
- Causal effect (lift) estimation usually has error.
- The parameter `true_cvr` in siMMMulator is the average causal effect of a unit impression of each media.
- The variable `noisy_cvr` in siMMMulator is the causal effect of a unit impression of each media on each campaign.
- We use these notations in the following section:
    - $\tau$ : `true_cvr`
    - $\tau_c$  : `noisy_cvr`  
    - $\hat{\tau_c}$: the estimation of `noisy_cvr`

### Experiment #1：Variety of experiments
#### Scripts
- `R/exp1/`

#### Settings
- Goal
    - Prove that calibration improves the accuracy of causal effect estimation.
- Number of media
    - 2 media（TV and Facebook）
- Comparison
    - No calibration（None）
    - Calibration with single media（TV | Facebook）
    - Calibration with All media（TV & Facebook）
- Evaluation metrics
    - Average of absolute percentage error of ROI.
- Assumption:
    - No error exists in the estimation of causal effect from RCT results.

#### Results
##### Summary
- Calibrating two media achieve smallest MAPE of ROI.
- Even though calibration doesn't cover all of media, MAPE of ROI decrease.
- it is better that conduct experiments on as much media as possible.

##### Detail
![image](https://user-images.githubusercontent.com/40241649/201340234-5676808f-8de2-4d89-8fc6-c34effa4d1ce.png)
- MAPE of ROI is calculated as $\frac{1}{M} \sum_m^M |\mathrm{ROI}_m - \hat{\mathrm{ROI}_m}|$. 
- $\mathrm{ROI}_m$ is a ground truth ROI of channel $m$ , and we calculate if from `true_cvr`, `CPM`, and `spend` in siMMMulator. 
- $\hat{\mathrm{ROI}_m}$ is an estimated ROI of channel $m$ and a Robyn's output.
- Each dot is the average MAPE of models after clustering in Robyn, and each bar is the variance. the number of models is from 4 to 7.
- The best result is calibration by the causal estimates on two channels (FB and TV).
- Only calibration on TV or FB has much better than the calibration.

### Experiment #2：Number of experiments
#### Scripts
- `R/exp2/`

#### Settings
- Goal
    - Prove that the calibration with numerous RCTs improves the accuracy of causal effect estimation.
- Comparison
    - Number of RCT results used for calibration (1, 5, 10, 50, 260)
- Evaluation metrics
    - MAPE of ROI

#### Results
##### Summary
- Multi-time experiment on each media make Robyn's ROI estimation accurate.


##### Detail
  
![image](https://user-images.githubusercontent.com/40241649/201340312-fb3c3145-4461-4316-a656-0500b6e9dbf2.png)

- The figure above shows the absolute error of causal effect (lift) estimation. this error is calculated $$\tau - \frac{1}{C}\sum_c^C\hat{\tau}_c$$ where $\tau$ represents true causal effect, $\hat{\tau}_c$ represents causal effect estimation on the campaign $c$, and $C$ represents number of campaigns.
- The figure below shows the MAPE of ROI defined in the precious section.
- The results show a multi-time experiment decreased errors in the causal effect estimation and MAPE of ROI.


## Accomplishments that we're proud of

- We show bellow by conducting analysis with synthetic data.
  1. Experiments on multiple media make Robyn's ROI estimation much better
  2. Multi-time experiment on each media make Robyn's ROI estimation accurate
- In order to verify the accuracy of ROI estimation using generated data close to realistic settings, , we add an implementation to the siMMMulator, which is an open source R-package for generating dataset for MMM.

## What we learned

- In the planning phase of marketing, we just plan the experiment roadmap.
- If we can conduct experiments on all media, it's the best. If cannot, it is better that cover as much media as possible.
- If we can conduct experiments as many as possible on each media, that makes our MMM results more accurate.

## Challenges we ran into

- Creating realistic data generation assumptions.
- Understanding the internal structure (optimization, various parameters) from Robyn code around calibration.

## What's next?

- Theoretical guarantees of our results.
- Implementation of data generation assumptions for complex relationships between organic sales and media spends, etc.
    - Reverse causality：Higher sales allow for a larger budget allocation.
    - Robust extrapolation:：MMM model is fitted to limited historical data and expected to provide insights outside the scope of this data. （e.g., Wide range ad spend）
    - Funnel effects [Angrist and Krueger, 1999]：An ad channel also impacts the level of another ad channel. That will lead to biased estimates.
- Cost-optimal design of number of experiments.


# Refference
- Angrist, J. & Krueger, A. B. (1999). Empirical strategies in labor economics. In O. C. Ashenfelter & D. Card (Eds.), Handbook of labor economics (Vol. 3, pp. 1277–1366).
- Chan, David, and Mike Perry. "Challenges and opportunities in media mix modeling." (2017).