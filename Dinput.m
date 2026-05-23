function y = dinput( text , def )

%  dinput         -  Variante di input
%
%DINPUT  y = dinput( text , def )
%        Espone il messaggio 'text' seguito dal valore 'def' ed attende input
%        dall'utente. Se viene premuto direttamente <return>, y=def (default)
%        Altrimenti viene ritornato il valore immesso.

if nargin<2,
   def = 0;
elseif isempty(def),
   def = 0;
end

y = input( sprintf( [ text, ' [%g] > ' ], def ) );
if isempty( y ),
     y = def;
end

