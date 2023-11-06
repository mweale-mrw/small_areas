# small_areas
Programmes used to produce the results in “Consumption and Health-based Indicators of Well-being for Lower Tier Local Authorities in England”.

Using these programmes we derive estimates of economic well-being for local authorities in
England Our measure is designed to reflect life-time consumption, the disutility
of work and unemployment, and health state and life expectancy. Our well-being
metric combines each of these factors using an expected utility framework. Extending earlier work reflect a distinction between expected life in good health and expected life in poor health and to distinguish between private and public consumption. The analysis is presented for lower tier
local authority areas (LTLAs), but it is possible to produce figures for larger geographic areas or for other aggregates of LTLAs such as rural areas or cities. The current results are provided for fiscal year 2015-6, reflecting availability of administrative income data, and are for lower-tier local authority areas (LTLAs) in England. Broadly speaking the LTLAs with the highest well-being are in areas surrounding London while the lowest levels of well-being are found in Northern England.

The stata programmes need to be run in this order

1.	create_aps_lcfsMW22Jun23
This creates a single data set combining relevant data from APS and LCFS
2.	Compute_alpha
This calculates and saves the value of alpha- the share of private consumption in total consumption
3.	Value of life8May2023
This confirms the constant in the utility function and stores it as a matrix. 
4.	Theta_calculations20Mar2023
This calculates and stores the value of theta- the loading put on leisure in the utility fuction
5.	UTLA_GGH to LTLA_GGH
This maps health prevalence and related data from UTLAs to LTLAs
6.	matrices for L and Health Prevalence from ONS dataLTLA27Mar2023annotated
This reads in demographic data and constructs matrices of life years in each age category and health status  by LTLA for men and women separately.
7.	variance twoV4LTLA5May23
This constructs variance matrices for the demographic data
8.	analysis_lcfs_mw22Jun23a
This estimates the models used to infer the consumption and leisure time data for each LTLA.  The parameter tables are saved as tex files
9.	analysis_redo_tables22Jun23a
This sets up the variables to be used in the subsequent calculation of the measures of well-being
10.	varianceLTLA_6Aug23
This generates the outputs and saves them as tex files.
There are two programmes which are used throughout the process
Matin saves matrix variables and matout reads matrices which are stored on disc

