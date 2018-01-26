library(Rcpp)
library(testthat)
library(rbenchmark)

cppFunction(
  'Rcpp::List wrapList(int len=1000, int size=500) {
  std::list< std::set<int> > myList;
  
  for(int i=0; i<len; ++i) {
    std::set<int> set;
    for(int j=0; j<size; ++j) {
      set.insert(j % (size-1));
    }
    myList.push_back(set);
  }
  
  // note the magic Rcpp::wrap
  return Rcpp::wrap(myList);
  }'
)

wrapListRes <- wrapList()

cppFunction(
  'Rcpp::List wrapListPreAlloc(int len=1000, int size=500) {
  std::list< std::set<int> > myList(len);
  
  for(std::list< std::set<int> >::iterator it=myList.begin(); it!=myList.end(); ++it) {
    std::set<int> set;
    for(int j=0; j<size; ++j) {
      set.insert(j % (size-1));
    }
    *it = set;
  }
  
  // note the magic Rcpp::wrap
  return Rcpp::wrap(myList);
  }'
)
wrapListRes2 <- wrapListPreAlloc()

wrapListR <- function(len=1000, size=500) {
  lapply(1:len, function(x) {
    unique(seq(0, size) %% (size-1))
  })
}
wrapListResR <- wrapListR()
expect_identical(wrapListRes, wrapListRes2)
expect_equivalent(wrapListRes, wrapListResR)

## actually for this task, R is even faster than C++ implementations
## therefore the old wisedom - do not pre-optimise
benchmark(wrapList=wrapList(),
          wrapListPreAlloc=wrapListPreAlloc(),
          wrapListR=wrapListR())

## note how better it is to use wrap than not
## It is very bad to use .push_back on any Rcpp objects, becuase in this way you will end up copying to and from the ever expanding object as Rcpp data types hide the R object that must be recreated
## see an answer on [StackOverflow](https://stackoverflow.com/questions/37502121/handling-list-in-rcpp?rq=1)

cppFunction(
  'Rcpp::List wrapList_bad(int len=1000, int size=500) {
     std::list< std::set<int> > myList;

     for(int i=0; i<len; ++i) {
       std::set<int> set;
       for(int j=0; j<size; ++j) {
         set.insert(j % (size-1));
       }
       myList.push_back(set);
     }


     // note that the part below re-do the magic Rcpp::wrap
     Rcpp::List res;
     for(std::list< std::set<int> >::iterator lit=myList.begin();lit != myList.end(); ++lit) {
       Rcpp::IntegerVector cv;
       std::set<int> currSet = *lit;
       for(std::set<int>::iterator it=currSet.begin(); it!=currSet.end(); ++it) {
          cv.push_back(*it);
       }
       res.push_back(cv);
     }
     return(res);
  }'
)
wrapListRes <- wrapList_bad()

expect_identical(wrapList(), wrapList_bad())

benchmark(wrapList=wrapList(),
          wrapList_bad=wrapList_bad())
