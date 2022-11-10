# robyn_hackathon_2022_autumn

## Inspiration

MMM is designed to guide optimal advertising investment decisions, but MMM has its duality. One side of the goals of MMM is convincing explanation to customers, and another side is a better estimating of ROI. When we are calibrating with results from experiments, we often get two questions.

- On which media?：“Which media should we conduct experiments on? We do a lot of experiments on facebook. Is it enough?"
- How many times?：“How many experiments should we conduct on instagram?”

We try to adress these two questions by conducting analysis with synthetic data.

## What it does

- We add an implementation of realistic data generation processes to the siMMMulator, which is an open source R-package for generating dataset for MMM.
- We conduct experiments on multiple media make Robyn's ROI estimation much better.
- We conduct multi-time experiment on each media make Robyn's ROI estimation accurate.

## How we built it

### Preparation：Add implementations in siMMMulator
- We add implementations to siMMMulator.
    - Correlation between media spend and organic sales.
    - Correlation between media spends.
    - Cyclic seasonality and events.
- See Github repository in detail: `R/data_gen/`.

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
    - No estimating error exists.

#### Results
- Calibrating two media achieve smallest MAPE of ROI.
- Even though calibration doesn't cover all of media, MAPE of ROI decrease.
- it is better that conduct experiments on as much media as possible.

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
- Multi-time experiment on each media make Robyn's ROI estimation accurate.

## Challenges we ran into

- Creating realistic data generation assumptions.    
- Understanding the internal structure (optimization, various parameters) from Robyn code around calibration.

## Accomplishments that we're proud of

- We show bellow by conducting analysis with synthetic data.
  1. Experiments on multiple media make Robyn's ROI estimation much better
  2. Multi-time experiment on each media make Robyn's ROI estimation accurate
- In order to verify the accuracy of ROI estimation using generated data close to realistic settings, , we add an implementation to the siMMMulator, which is an open source R-package for generating dataset for MMM.

## What we learned

- In the planning phase of marketing, we just plan the experiment roadmap.
- If we can conduct experiments on all media, it's the best. If cannot, it is better that cover as much media as possible.
- If we can conduct experiments as many as possible on each media, that makes our MMM results more accurate.

## What's next?

- Theoretical guarantees.
- Implementation of data generation assumptions for complex relationships between organic sales and media spends, etc.
    - Reverse causality：Higher sales allow for a larger budget allocation.
    - Limited range of data：MMM model is fitted to limited historical data and expected to provide insights outside the scope of this data. （e.g., Wide range ad spend）
    - Funnel effects [Angrist and Krueger, 1999]：An ad channel also impacts the level of another ad channel. That will lead to biased estimates.
- Cost-optimal design of number of experiments.

