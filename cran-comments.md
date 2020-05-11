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
