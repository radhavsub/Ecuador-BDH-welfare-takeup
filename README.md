# Psychological and Informational Obstacles to Ecuador's BDH Take-Up

**An empirical replication and extension of Rinehart and McGuire (2017)**  
**Software:** Stata | **Course:** ECON 644, Empirical Analysis II | **Institution:** University of Maryland, College Park

## Overview

Why do some eligible households not receive social assistance? This project examines take-up of Ecuador's *Bono de Desarrollo Humano* (BDH), a cash transfer program, with particular attention to geographic access, informational constraints, and psychological factors.

The analysis replicates and extends the work of Rinehart and McGuire (2017). It investigates whether households in sparsely populated areas are less likely to receive BDH after accounting for economic need and household characteristics, and whether access to information and subjective attitudes are associated with participation.

## Data

The project uses the **2013–2014 Encuesta de Condiciones de Vida (ECV)**, a nationally representative household living-standards survey conducted by Ecuador's National Institute of Statistics and Census (INEC). The analysis uses the original study's replication dataset, restricting attention to **11,449 households** in the poorest 40% of the consumption distribution.

- **Outcome:** An indicator for whether any household member received BDH in October 2013.
- **Main explanatory variable:** Residence in a low-density parish (fewer than 10 residents per square kilometer).
- **Other variables:** Household consumption, demographic and eligibility characteristics, education, cellphone and internet access, self-perceived poverty, and satisfaction with government.

## Empirical Approach

The analysis is implemented in **Stata** and includes:

1. Descriptive statistics and comparisons between recipient and non-recipient households.
2. Ordinary least squares (linear probability) models with progressively added household, informational, and psychological controls.
3. Probit regressions and marginal effects to interpret changes in predicted take-up probabilities.
4. Interaction models examining whether the association between low-density residence and take-up varies with cellphone access, internet access, government satisfaction, or perceived poverty.

Regression tables report heteroskedasticity-robust standard errors.

## Main Findings

- **Incomplete take-up:** 65.0% of the 11,449 eligible-sample households received BDH in October 2013.
- **Geographic differences:** Low-density residence is positively associated with take-up in the uncontrolled model, but negatively associated after adding household controls. In the full probit specification, the estimated average marginal effect is approximately **−6.17 percentage points**.
- **Self-perceived poverty:** Household heads who report that their household is not poor have an estimated **24.1-percentage-point lower** probability of BDH receipt in the full probit marginal-effects specification, conditional on the model's other covariates.
- **Government satisfaction:** A one-point increase in satisfaction with government (on a 1–10 scale) is associated with approximately **1.27 percentage points higher** predicted take-up.
- **Cellphone access:** The positive low-density × cellphone interaction in the probit model suggests that cellphone access may be associated with a narrower geographic participation gap, although this is not evidence of a causal effect.

## Interpretation and Limitations

These results describe **conditional associations, not causal effects**. In particular, cellphone and internet access may proxy for income or other socioeconomic differences rather than information costs alone. The analysis also relies on the 2013–2014 survey and should not be treated as evidence about present-day program participation.

The findings motivate further research into the role of outreach, administrative access, and perceptions of eligibility in social-program take-up.

## Code and Reproducibility

The Stata `.do` files for this project cover descriptive analysis and the regression specifications described above. To rerun the analysis, obtain the data from the original study's replication materials, set the local input-data path in the scripts, and run them in their documented order.

**Data availability:** The underlying household microdata are not redistributed in this repository. The original authors provide information on research data and replication materials through [James McGuire's data page](https://jmcguire.faculty.wesleyan.edu/welcome/data/).

## Reference

Rinehart, C. S., & McGuire, J. W. (2017). Obstacles to takeup: Ecuador's conditional cash transfer program, the Bono de Desarrollo Humano. *World Development, 97*, 165–177. https://doi.org/10.1016/j.worlddev.2017.04.009

## Author

**Radha Vagheswara Subramanian**  
M.S. Applied Economics, University of Maryland, College Park

*Originally developed as an ECON 644 term project (March 2026).*
