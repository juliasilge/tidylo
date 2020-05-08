
<!-- README.md is generated from README.Rmd. Please edit that file -->



# tidylo: Weighted Tidy Log Odds Ratio

**Authors:** [Julia Silge](https://juliasilge.com/), [Alex Hayes](https://www.alexpghayes.com/), [Tyler Schnoebelen](https://www.letslanguage.org/)<br/>
**License:** [MIT](https://opensource.org/licenses/MIT)


<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/tidylo)](https://CRAN.R-project.org/package=tidylo)
[![Travis build status](https://travis-ci.org/juliasilge/tidylo.svg?branch=master)](https://travis-ci.org/juliasilge/tidylo)
[![AppVeyor build status](https://ci.appveyor.com/api/projects/status/github/juliasilge/tidylo?branch=master&svg=true)](https://ci.appveyor.com/project/juliasilge/tidylo)
[![Codecov test coverage](https://codecov.io/gh/juliasilge/tidylo/branch/master/graph/badge.svg)](https://codecov.io/gh/juliasilge/tidylo?branch=master)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

How can we measure how the usage or frequency of some **feature**, such as words, differs across some group or **set**, such as documents? One option is to use the log odds ratio, but the log odds ratio alone does not account for sampling variability; we haven't counted every feature the same number of times so how do we know which differences are meaningful? 

Enter the **weighted log odds**, which tidylo provides an implementation for, using tidy data principles. In particular, here we use the method outlined in [Monroe, Colaresi, and Quinn (2008)](https://doi.org/10.1093/pan/mpn018) to weight the log odds ratio by a prior. By default, the prior is estimated from the data itself, an empirical Bayes approach, but an uninformative prior is also available.

## Installation

You can install the released version of tidylo from [CRAN](https://CRAN.R-project.org) with:


```r
install.packages("tidylo")
```


Or you can install the development version from GitHub with [remotes](https://github.com/r-lib/remotes):


```r
library(remotes)
install_github("juliasilge/tidylo")
```

## Example

Using weighted log odds is a great approach for text analysis when we want to measure how word usage differs across a set of documents. Let's explore the [six published, completed novels of Jane Austen](https://github.com/juliasilge/janeaustenr) and use the [tidytext](https://github.com/juliasilge/tidytext) package to count up the bigrams (sequences of two adjacent words) in each novel. This weighted log odds approach would work equally well for single words.


```r
library(dplyr)
library(janeaustenr)
library(tidytext)

tidy_bigrams <- austen_books() %>%
     unnest_tokens(bigram, text, token = "ngrams", n = 2)

bigram_counts <- tidy_bigrams %>%
     count(book, bigram, sort = TRUE)

bigram_counts
#> # A tibble: 328,495 x 3
#>    book                bigram     n
#>    <fct>               <chr>  <int>
#>  1 Mansfield Park      of the   748
#>  2 Mansfield Park      to be    643
#>  3 Emma                to be    607
#>  4 Mansfield Park      in the   578
#>  5 Emma                of the   566
#>  6 Pride & Prejudice   of the   464
#>  7 Emma                it was   448
#>  8 Emma                in the   446
#>  9 Pride & Prejudice   to be    443
#> 10 Sense & Sensibility to be    436
#> # … with 328,485 more rows
```

Now let's use the `bind_log_odds()` function from the tidylo package to find the weighted log odds for each bigram. The weighted log odds computed by this function are also [z-scores](https://en.wikipedia.org/wiki/Standard_score) for the log odds; this quantity is useful for comparing frequencies across categories or sets but its relationship to an odds ratio is not straightforward after the weighting. 

What are the bigrams with the highest weighted log odds for these books?


```r
library(tidylo)

bigram_log_odds <- bigram_counts %>%
  bind_log_odds(book, bigram, n) 

bigram_log_odds %>%
  arrange(-log_odds_weighted)
#> # A tibble: 328,495 x 4
#>    book                bigram                n log_odds_weighted
#>    <fct>               <chr>             <int>             <dbl>
#>  1 Mansfield Park      sir thomas          287              28.3
#>  2 Pride & Prejudice   mr darcy            243              27.7
#>  3 Emma                mr knightley        269              27.5
#>  4 Emma                mrs weston          229              25.4
#>  5 Sense & Sensibility mrs jennings        199              25.2
#>  6 Persuasion          captain wentworth   170              25.1
#>  7 Mansfield Park      miss crawford       215              24.5
#>  8 Persuasion          mr elliot           147              23.3
#>  9 Emma                mr elton            190              23.1
#> 10 Emma                miss woodhouse      162              21.3
#> # … with 328,485 more rows
```

The bigrams more likely to come from each book, compared to the others, involve proper nouns. We can make a visualization as well.


```r
library(ggplot2)

bigram_log_odds %>%
  group_by(book) %>%
  top_n(10) %>%
  ungroup %>%
  mutate(bigram = reorder(bigram, log_odds_weighted)) %>%
  ggplot(aes(bigram, log_odds_weighted, fill = book)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~book, scales = "free") +
  coord_flip() +
  labs(x = NULL)
#> Selecting by log_odds_weighted
```

<img src="man/figures/README-bigram_plot-1.png" title="plot of chunk bigram_plot" alt="plot of chunk bigram_plot" width="100%" />

### Community Guidelines

This project is released with a
[Contributor Code of Conduct](https://github.com/juliasilge/tidylo/blob/master/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms. Feedback, bug reports (and fixes!), and feature requests are welcome; file issues or seek support [here](http://github.com/juliasilge/tidylo/issues).

