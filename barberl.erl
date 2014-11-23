%--------------------------------------------------------------------
%
% Copyright (c) 2011 Mike French
%
% This software is released under the MIT license
% http://www.opensource.org/licenses/mit-license.php
%
%--------------------------------------------------------------------

-module( barberl ).

-export( [start/0, shop/7, barber/0] ).

start() ->
  random:seed( now() ),
  Barber = spawn_link( ?MODULE, barber, [] ),
  Shop   = spawn_link( ?MODULE,   shop, [self(),open,Barber,empty,[],0,0] ),
  [ begin wait(100,200), Shop ! { self(), walkin, C } end || C <- lists:seq(1,20) ],
  Shop ! { self(), close },
    receive { Shop, closed, Cut, NoCut } ->
      io:format( "[~4s] Tally: Cut ~b No cut ~b ~n", ["Sim",Cut,NoCut] )
  end,
  ok.

shop( Sim, closed, Barber, empty, [], Cut, NoCut ) ->
  trace( "Shop", "Closed" ),  
  Sim ! Barber ! { self(), closed, Cut, NoCut };
shop( Sim, State, Barber, empty, [C|Rest], Cut, NoCut ) ->
  trace( "Shop", "Sending customer to barber", C ),
  Barber ! { self(), cut_hair, C },
  shop( Sim, State, Barber, C, Rest, Cut, NoCut );
shop( Sim, State, Barber, Chair, Queue, Cut, NoCut ) ->
  receive
    { Sim, walkin, C } when (State == closed) or (length(Queue) == 3) ->
        trace( "Shop", "Turning away customer", C ),
        shop( Sim, State, Barber, Chair, Queue, Cut, NoCut+1 );
    { Sim, walkin, C } ->
        trace( "Shop", "Queueing customer", C ),
        shop( Sim, State, Barber, Chair, Queue++[C], Cut, NoCut );
    { Barber, done, Chair } ->
        trace( "Shop", "Customer leaving", Chair ),
        shop( Sim, State, Barber, empty, Queue, Cut+1, NoCut );
    { Sim, close } ->
        trace( "Shop", "Closing" ),
        shop( Sim, closed, Barber, Chair, Queue, Cut, NoCut )
  end.

barber() ->
  receive
    { Shop, cut_hair, C } ->
        trace( "Barb","Start  cutting hair of customer", C ),
        wait( 100, 400 ),
        trace( "Barb","Finish cutting hair of customer", C ),
        Shop ! { self(), done, C },
        barber();
    { _Shop, closed, _Cut, _NoCut } ->
        trace( "Barb", "Going home" )
  end.

wait( Min, Range ) when (Min > 0) and (Range > 0) ->
  timer:sleep( Min + random:uniform(Range+1) - 1 ).

trace( Entity, Msg    ) -> io:format( "[~4s] ~-31s   ~n", [Entity,Msg]   ).
trace( Entity, Msg, C ) -> io:format( "[~4s] ~-31s ~b~n", [Entity,Msg,C] ).

%--------------------------------------------------------------------
