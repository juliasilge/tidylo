## Test environments
* local R installation, R 4.0.0
* ubuntu 16.04 (on travis-ci), R 4.0.0
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## 0.1.0 Resubmission

### Review 1 - 2020-05-11

> The Description field is intended to be a (one paragraph) description
of what the package does and why it may be useful. Please elaborate.

Changed the Description from:

"Calculate the log odds ratio, weighted by a prior such as that from empirical Bayes estimation, using tidy data principles."

to:

"How can we measure how the usage or frequency of some feature, such as words, differs across some group or set, such as documents? One option is to use the log odds ratio, but the log odds ratio alone does not account for sampling variability; we haven't counted every feature the same number of times so how do we know which differences are meaningful? Enter the weighted log odds, which tidylo provides an implementation for, using tidy data principles. In particular, here we use the method outlined in Monroe, Colaresi, and Quinn (2008) <doi:10.1093/pan/mpn018> to weight the log odds ratio by a prior. By default, the prior is estimated from the data itself, an empirical Bayes approach, but an uninformative prior is also available."


> If there are references describing (the theoretical backgrounds of) the
methods in your package, please add these in the description field of
your DESCRIPTION file in the form
authors (year) <doi:...>
authors (year) <arXiv:...>
authors (year, ISBN:...)
or if those are not available: <https:...>
with no space after 'doi:', 'arXiv:', 'https:' and angle brackets for
auto-linking.

Add to the Description:

"...here we use the method outlined in Monroe, Colaresi, and Quinn (2008) <doi:10.1093/pan/mpn018>"

### Review 2 - 2020-05-16

> Please always write package names, software names and API (application
programming interface) names in single quotes in title and description.
e.g: --> 'tidylow'

Changed the Description from:

"How can we measure how the usage or frequency of some feature, such 
    as words, differs across some group or set, such as documents? One option is 
    to use the log odds ratio, but the log odds ratio alone does not account for 
    sampling variability; we haven't counted every feature the same number of 
    times so how do we know which differences are meaningful? Enter the weighted 
    log odds, which tidylo provides an implementation for, using tidy data 
    principles. In particular, here we use the method outlined in Monroe, 
    Colaresi, and Quinn (2008) <doi:10.1093/pan/mpn018> to weight the log odds 
    ratio by a prior. By default, the prior is estimated from the data itself, 
    an empirical Bayes approach, but an uninformative prior is also available."

to:

"How can we measure how the usage or frequency of some feature, such 
    as words, differs across some group or set, such as documents? One option is 
    to use the log odds ratio, but the log odds ratio alone does not account for 
    sampling variability; we haven't counted every feature the same number of 
    times so how do we know which differences are meaningful? Enter the weighted 
    log odds, which 'tidylo' provides an implementation for, using tidy data 
    principles. In particular, here we use the method outlined in Monroe, 
    Colaresi, and Quinn (2008) <doi:10.1093/pan/mpn018> to weight the log odds 
    ratio by a prior. By default, the prior is estimated from the data itself, 
    an empirical Bayes approach, but an uninformative prior is also available."

> Some authors seem also to be copyright holders [cph].
Please add this information to the Authors@R field.

Changed the Authors@R from:

    c(person(given = "Tyler",
             family = "Schnoebelen",
             role = "aut",
             email = "tjs1976@gmail.com"),
      person(given = "Julia",
             family = "Silge",
             role = c("aut", "cre"),
             email = "julia.silge@gmail.com",
             comment = c(ORCID = "0000-0002-3671-836X")),
      person(given = "Alex",
             family = "Hayes",
             role = "aut",
             email = "alexpghayes@gmail.com",
             comment = c(ORCID = "0000-0002-4985-5160")))

to:

    c(person(given = "Tyler",
             family = "Schnoebelen",
             role = "aut",
             email = "tjs1976@gmail.com"),
      person(given = "Julia",
             family = "Silge",
             role = c("aut", "cre", "cph"),
             email = "julia.silge@gmail.com",
             comment = c(ORCID = "0000-0002-3671-836X")),
      person(given = "Alex",
             family = "Hayes",
             role = "aut",
             email = "alexpghayes@gmail.com",
             comment = c(ORCID = "0000-0002-4985-5160")))
