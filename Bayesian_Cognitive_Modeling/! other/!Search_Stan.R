# clears workspace: 
rm(list=ls()) 

# Set working directory!

library(rstan)

####################
#  Zakladam to spis na Jags verzi - neohraniceny normal na stmp.  Puvodne byla
#  Jags stmp[i,1] <- 1, ale toto delalo v Jags nejakou chybu, ktera zmizela po 
#  odstraneni tohoto. 
#  Hlavne je problem, ze nemuzu prevest intereg values mezi bloky.  
#
# - zmenit comment znak okolo modelu
#########

model <- '
// Individual Search Orders
data {
  int ns;
  int nq;
  int nc;
  int y[ns,nq];
  int m[83,nc];
  int p[nq,2];
}
parameters {
  real<lower=.5,upper=1> gamma;
  vector[nc] stmp[ns];
}
transformed parameters {
  vector<lower=0,upper=1>[3] ttb;
  real<lower=0,upper=3> t[ns,nq];
  real s[ns,nc];
  
  // One Reason Model, With Different Search Order Per Subject
  for (i in 1:ns) {
    
    // Cue Search Order From Ranking stmp
    s[i] <- sort_indices_asc(stmp[i]);
  
    for (q in 1:nq) {	
      vector[nc] tmp1;
      real tmp2;
      int tmp3;

      // Add Cue Contributions To Mimic TTB Decision
      for (j in 1:nc)
        tmp1[j] <- (m[p[q,1],j] - m[p[q,2],j]) * 2 ^ (s[i,j] - 1);
        
      // Find if Cue Favors First, Second, or Neither Stimulus
      tmp2 <- sum(tmp1);
      tmp3 <- -1 * int_step(-tmp2) + int_step(tmp2);
      t[i,q] <- tmp3 + 2;
    }
  }
  // Choose TTB Decision With Probability Gamma, or Guess
  ttb[1] <- 1 - gamma;
  ttb[2] <- .5;
  ttb[3] <- gamma;
} 
model {
  for (i in 1:ns)
    stmp[i] ~ normal(0,inv_sqrt(.001));

  // Data
  for (q in 1:nq)
    for (i in 1:ns)
      if (t[i,q] == 1.0)
        y[i,q] ~ bernoulli(ttb[1]);
      else if (t[i,q] == 2.0) 
        y[i,q] ~ bernoulli(ttb[2]);
      else if (t[i,q] == 3.0) 
        y[i,q] ~ bernoulli(ttb[3]);
      else 
        print("Error with indexing y");

generated quantities {
  int<lower=0,upper=1> ypred[ns,nq];

  
  for (q in 1:nq)
    for (i in 1:ns)
      if (t[i,q] == 1.0)
        ypred[i,q] <- bernoulli_rng(ttb[1]);
      else if (t[i,q] == 2.0) 
        ypred[i,q] <- bernoulli_rng(ttb[2]);
      else if (t[i,q] == 3.0) 
        ypred[i,q] <- bernoulli_rng(ttb[3]);
      else 
        print("Error with indexing ypred");

}'

load("StopSearchData.RData")  # Load all data for the model

data <- list(nc=nc, nq=nq, ns=ns, p=p, m=m, y=y) # To be passed on to Stan

myinits <- list(
  list(gamma=.75))

parameters <- c("gamma", "s", "ypred")  # Parameters to be monitored

# For a detailed description type "?stan".
samples <- stan(model_code=model,   
                data=data, 
 #               init=myinits,  # If not specified, gives random inits
                pars=parameters,
                iter=1100, 
                chains=1, 
                thin=1,
                warmup=100,  # Stands for burn-in; Default = iter/2
                # seed=123  # Setting seed; Default is random seed
)
# Now the values for the monitored parameters are in the "samples" object, 
# ready for inspection.

print(samples, digits=3)