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
