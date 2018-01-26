library(Rcpp)
library(testthat)
library(rbenchmark)

## the simplest variant using evalCpp
evalCpp("2+2", verbose=TRUE)

## push_back for vector
cppFunction(
  "Rcpp::IntegerVector myFunc(Rcpp::IntegerVector xx) {
    xx.push_back(1);
    xx.push_back(2);
    return(xx);
  }"
)

myVec <- c(4L, 5L)
myFunc(myVec)

## if the input vector is not an IntegerVector, it will be coerced 
myNonIntVec <- c(3.2, 4.4)
myFunc(myNonIntVec) 

## create a list of random numbers following standard normal distribution; the length of the random numbers follows an uniform distribution

cppFunction(
  'Rcpp::List getList(int len, int size, bool debug=0) {
    Rcpp::List res;
    Rcpp:IntegerVector currSize(1);
    Rcpp::NumericVector currVec;
    for(int i=0; i<len; i++) {
      currSize = floor(runif(1)*size)+1;
      if(debug) {
        Rcpp::Rcout << "currSize:" << currSize[0] << std::endl;
      }
      currVec = rnorm(currSize[0], 0, 1);
      res.push_back(currVec);
    }
    return(res);
  }'
)
set.seed(123)
myList <- getList(1000, 10)
table(sapply(myList, length))

## set
cppFunction(
  'Rcpp::IntegerVector mySet() {
     std::set<int> s;
     s.insert(1);
     s.insert(2);
     s.insert(2);
     s.insert(9);
     s.insert(5);
     s.insert(1);
     
     Rcpp::Rcout << "Unique elements in the set" << std::endl;
     for( std::set<int>::iterator it=s.begin(); it!=s.end(); ++it) {
          Rcpp::Rcout << *it << std::endl;
     }

     Rcpp::Rcout << "Distinct pairs" << std::endl;
     for( std::set<int>::iterator it=s.begin(); it!=s.end(); ++it) {
       for( std::set<int>::iterator jt=it; jt!=s.end(); ++jt) {
          if(jt!=it) {
            Rcpp::Rcout << *it << "," << *jt << std::endl;
          }
       }
     }
        

     Rcpp::IntegerVector res;
     for( std::set<int>::iterator it=s.begin(); it!=s.end(); ++it) {
        res.push_back(*it);
     }
     return(res);
   }
')

mySet()

## nested iteration of list
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

## note how better it is to use wrap
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
