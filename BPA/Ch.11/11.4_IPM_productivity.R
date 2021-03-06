## 11. Integrated population models
## 11.4. Another example of an IPM:
##       Estimating productivity without explicit productivity data

library(rstan)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
set.seed(123)

## Read data
## The data generation code is in bpa-code.txt, available at
## http://www.vogelwarte.ch/de/projekte/publikationen/bpa/complete-code-and-data-files-of-the-book.html
stan_data <- read_rdump("ipm_prod.data.R")

## Parameters monitored
params <- c("mean_sjuv", "mean_sad", "mean_p", "mean_fec",
            "N1", "Nad", "Ntot", "lambda", "sigma2_y")

## MCMC settings
ni <- 10000
nt <- 6
nb <- 4000
nc <- 4

## Initial values
inits <- lapply(1:nc, function(i)
    list(mean_sjuv = runif(1, 0, 1),
         mean_sad = runif(1, 0, 1),
         mean_p = runif(1, 0, 1),
         mean_fec = runif(1, 0, 10),
         N1 = rpois(stan_data$nyears, 30),
         Nad = rpois(stan_data$nyears, 30),
         sigma_y = runif(1 ,0, 10)))

## Call Stan from R
ipm_prod <- stan("ipm_prod.stan",
                 data = stan_data, init = inits, pars = params,
                 chains = nc, iter = ni, warmup = nb, thin = nt,
                 seed = 4,
                 control = list(adapt_delta = 0.95),
                 open_progress = FALSE)
print(ipm_prod, digits = 3)
