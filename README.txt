
Sleeping Barber in Erlang
-------------------------

References

  The problem was originally taken from here:

    http://www.bestinclass.dk/index.clj/2009/09/scala-vs-clojure-round-2-concurrency.html
  
  inspired by an O'Reilly chapter about a Scala version:
 
    http://programming-scala.labs.oreilly.com/ch09.html
  
  and the full description is given here:
 
    http://en.wikipedia.org/wiki/Sleeping_barber_problem
    
Problem Summary
 
  There is a barber shop comprising 
    - 1 barber with a chair for haircutting
    - 3 chairs for waiting customers
    
  The barber sleeps between customers and is awoken when one enters the shop.
  A customer entering an empty shop can proceed directly to the barber's chair.
  If customers come in while he's working, they take a seat, 
  if no seats are available they are turned away.
  The shop eventually closes, any more new customers will be turned away,
  but those already in the queue will still be served.
  When the shop has closed and there are no more customers in the queue,
  the barber goes home.

Program Requirements

  A concurrent simulation should model the shop, barber and customers
  with randomized delays and timings between significant events,
  such as arrival of customers and time to cut hair.
  
  The program should print out events as they happen,
  with a summary at the end totalling the number of haircuts,
  and the number of customers that were turned away.

Erlang Approach

  There are many ways this could be implemented in Erlang.
  
  I have chosen to model the shop and the barber as asynchronous processes.
  
  Customers do not have any real behaviour, so I have modelled them as
  unique integer identifiers passed in messages and recorded in process state,
  but the individual status of customers hair (long/short) is not recorded.
  
  There is a main simulation process that: 
    - creates the barber
    - opens the shop
    - trickles the customers into the shop
    - finally, closes the shop. 
  
  The shop will queue customers, send customers to the barber, 
  and record the tally of haircuts and customers turned away.
  The shop maintains an open/closed state and the barber's chair 
  is either empty or holds the integer id of the current customer.
  The queue is a list of up to 3 seated customer ids.
  
  The barber will start work, sleep, cut hair and eventually go home.
  
Variants

  Empty Shop Optimization
  
    Here is a 4-line clause to implement the optimization for a
    new customer in an empty shop to go straight to the barber's chair.
    Insert this into the shop process ahead of the existing walkin clause.

      { Sim, walkin, C } when (Chair == empty) ->
          trace( "Shop", "Sending customer to barber", C ),
          Barber ! { self(), cut_hair, C },
          shop( Sim, State, Barber, C, [], Cut, NoCut );
        
  Customer Tuple
  
    It would easy to turn the customer integer id into a tuple,
    containing an id and a boolean state for long/short hair.
    
  Customer Process
  
    It would also be trivial to make customers into processes.
    The customer would have a single piece of state for long/short hair.
    The simulation would spawn customers with long hair.
    The customer PIDs would replace the integer id.
    The barber would send the customer a 'cut' message when he had
    finished cutting their hair, and they would change state to short hair.
        
Code Size

  The solution is 49 SLOC, of which 12 are for printing.

Usage

  At the erlang shell:
  
    > c(barberl).
    {ok,barberl}
    
    > barberl:start().
    [Shop] Queueing customer               1
    ...
    [ Sim] Tally: Cut 16 No cut 4 
    ok
    > 


  
