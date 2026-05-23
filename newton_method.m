function [x,iter]=newton_method(f,x0,maxit,tol)
%newton_method è una funzione che prende in ingresso una funzione f, un initial guess x0, 
%il numero massimo maxit di iterazioni e la 
%tolleranza d'errore tol sulla soluzione e risolve il sistema f(x)=0 
%applicando il metodo iterativo di Newton con Jacobiana esatta.
%In uscita da la soluzione x trovata e il numero iter di iterazioni.

x=x0; %inizializzo la variabile x al valore dell'initial guess
for iter=1:maxit
    
    J=(f(x+tol/100)-f(x))./(tol/100); %calcolo derivata di f nell'intorno di x
    %con un'ampiezza dell'intervallo che è un centesimo della tolleranza
    
    dx=-J\f(x);
    
    if abs(dx)<tol  %se l'incremento dx è inferiore alla tolleranza
                        %la soluzione x è accettabile e quindi finisco le 
                        %iterazioni e ritorno il risultato approssimato
                        %di x
        break;
    end
    
    x=x+dx;
    
end
end