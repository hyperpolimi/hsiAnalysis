function n=nCryst(cr,lambda,T)

%  nCryst         -  Refraction Indexes look-up table
%
% n = nCryst(cr,lambda,T)  Fornisce gli indici di rifrazione ordinario e straordinario
%                          per un cristallo uniassico sulla base delle equazioni di
%                          Sellmeier; lambda deve essere uno scalare in micron.
%                          T e' la temperatura espressa in gradi C (default: 23 gradi C)
%
% Output:      n = [no ne]        for uniaxial crystals
%              n = [nx+iny nz]    for biaxial crystals
%
%     Il parametro cr indica il cristallo che si sta considerando e puo' valere:
%
%              1  :  ADP
%              2  :  beta-BBO
%              3  :  CLBO
%              4  :  KDP
%              5  :  K*DP o DKDP
%              6  :  Schott BK7 (vetro isotropo)
%              7  :  Fused Silica (vetro isotropo)
%              8  :  Crystal Quartz (uniassico)
%              9  :  Zaffiro (biassico)
%              10 :  LBO (biassico)
%
%              11 :  SF56
%              12 :  LaFn28
%              13 :  LiTaO3 (tantalato)
%              14 :  Borofloat
%              15 :  TeO2
%              16 :  SF10
%              17 :  LiNbO3 (niobato di litio)
%              18 :  KBBF
%              19 :  CaF2
%              20 :  MgF2
%              21 :  LiF
%              22 :  GaAs
%              23 :  YVO4                          |
%              24 :  Si                            |
%              25 :  Ge                            |
%              26 :  TeO2  (alternativo)           |  Materiali per IR
%              27 :  CdTe                          |www.irfilters.rdg.ac.uk
%              28 :  ZnSe                          |
%              29 :  ZnS                           |
%              30 :  TiO2 (rutilo)                 |  -> Marangoni
%              31 :  7% MgO:LiNbO3 
%              32 :  KNbO3 (biassico)
%              33 :  KTP (biassico)
%              34 :  LiIO3
%              35 :  LiIO3 (2)
%              36 :  5% MgO:LiNbO3
%              37 :  GaSe 
%              38 :  Acqua
%              39 :  Calcite
%              40 :  Aria
%              41 :  SF11
%              42 :  alpha-BBO
%              43 :  ZnTe
%              44 :  YAG
%              45 :  CdGeAs2
%              46 :  Argon
%              47 :  Calomel Hg2Cl2
%              48 :  Potassium Bromide KBr
%              49 :  Potassium Chloride KCl
%              50 :  CdSe
%              51 :  CdS
%              52 :  BaF2
%              53 :  KTA
%              54 :  KTA (xz)
%              55 :  ZF4

%              60 :  CLBO modificato
%
%
% Il solo comando nCryst senza argomenti restituisce in formato array di celle l'elenco
% dei vetri e cristalli tabulati nel file. In tale elenco manca l'aria.
%

ElencoCristalli={' ADP';' beta-BBO';' CLBO';' KDP';' K*DP o DKDP';' BK7 Schott';...
    ' Fused Silica';' Crystal Quartz';...
    ' Zaffiro';' LBO';' SF56'; ' LaFN28'; ' LiTaO3 (tantalato)'; ' Borofloat'; ' TeO2'; ' SF10'; ' LiNbO3'; ' KBBF'; ...
    ' CaF2'; ' MgF2'; ' LiF'; ' GaAs';...
    ' YVO4'; ' Si'; ' Ge'; ' TeO2 altenativo'; ' CdTe';...
    ' ZnSe'; ' ZnS'; ' TiO2'; '7% MgO:LiNbO3'; ' KNbO3 (biassico)'; ...
    ' KTP (biassico)'; ' LiIO3'; ' LiIO3 (2)'; '5%MgO:LiNbO3'; ' GaSe';...
    ' Water' ; ' Calcite' ;' Air'; ' SF11'; ' alpha-BBO'; ' ZnTe'; ' YAG';...
    ' CdGeAs2'; ' Argon'; ' Calomel (Hg2Cl2)'; ' Potassium Bromide (kBr)';...
    ' Potassium Chloride (KCl)'; ' CdSe'; ' CdS'; ' BaF2'; 'KTA'; ...
    'KTA(XZ)'; 'ZF4' ; 'CLBO modificato'}';

if nargin<2
    n=ElencoCristalli;
    return;
end;

if nargin<3
    T=20;
end;

[a,b]=size(lambda);

if ne(a,1) && ne(b,1), lambda=lambda(1,1); end;   % lambda deve essere uno scalare

switch cr

    case 1  % ADP

        no=sqrt(2.302842+0.011125165/(lambda.^2-0.013253659)+...
            15.102464*lambda.^2/(lambda.^2-400));

        nE=sqrt(2.163510+0.009616676/(lambda.^2-0.01298912)+...
            5.919896*lambda.^2/(lambda.^2-400));

    case 2  % BBO

        ao=2.7405; bo=0.0184; co=0.0179; do=0.0155;
        ae=2.3730; be=0.0128; ce=0.0156; de=0.0044;

        no=sqrt(ao+bo./(lambda.^2-co)-do.*lambda.^2);
        nE=sqrt(ae+be./(lambda.^2-ce)-de.*lambda.^2);

        
    case 3  % CLBO

        no=sqrt(2.208964+1.0493e-2/(lambda.^2-1.2865e-2)-1.1306e-2*lambda.^2);

        nE=sqrt(2.058791+8.711e-3/(lambda.^2-1.1393e-2)-6.069e-3*lambda.^2);

    case 4  % KDP

        no=sqrt(2.259276+0.01008956./(lambda.^2-0.012942625)+...
            13.00522.*lambda.^2./(lambda.^2-400));

        nE=sqrt(2.132668+0.008637494./(lambda.^2-0.012281043)+...
            3.2279924.*lambda.^2./(lambda.^2-400));

    case 5  % K*DP o DKDP

        no=sqrt(1.661145+0.586015*lambda.^2/(lambda.^2-0.016017)+...
            0.691194*lambda.^2/(lambda.^2-30));

        nE=sqrt(1.687499+0.44751*lambda.^2/(lambda.^2-0.017039)+...
            0.596212*lambda.^2/(lambda.^2-30));

    case 6  % Schott BK7

        B1=1.03961212;    B2=2.31792344e-1; B3=1.01046945;
        C1=6.00069867e-3; C2=2.00179144e-2; C3=1.03560653e2;

        n=sqrt(1+B1*lambda.^2/(lambda.^2-C1)+B2*lambda.^2/(lambda.^2-C2)+...
            B3*lambda.^2/(lambda.^2-C3));

        no=n; nE=n;

    case 7  % Fused Silica

        B1=6.961663e-1;   B2=4.079426e-1;   B3=8.974794e-1;
        C1=4.67914826e-3; C2=1.35120631e-2; C3=9.79340025e1;

        n=sqrt(1+B1*lambda.^2/(lambda.^2-C1)+B2*lambda.^2/(lambda.^2-C2)+...
            B3*lambda.^2/(lambda.^2-C3));

        no=n; nE=n;

    case 8  % Crystal Quartz

        % Indici straordinari
        B1=2.3849;    B2=-1.259e-2;   B3=1.079e-2;
        C1=1.6518e-4; C2=-1.94741e-6; C3=9.36476e-8;

        nE=sqrt(B1+B2*lambda.^2+B3*lambda^(-2)+C1*lambda^(-4)+C2*lambda^(-6)+C3*lambda^(-8));

        % Indici ordinari
        B1=2.35728;    B2=-1.17e-2;    B3=1.054e-2;
        C1=1.34143e-4; C2=-4.45368e-7; C3=5.92362e-8;

        no=sqrt(B1+B2*lambda.^2+B3*lambda^(-2)+C1*lambda^(-4)+C2*lambda^(-6)+C3*lambda^(-8));

    case 9  % Zaffiro

        % Indici straordinari
        B1=1.5039759;     B2=5.50691410e-1; B3=6.59273790;
        C1=5.48041129e-3; C2=1.47994281e-2; C3=4.02895140e2;

        nE=sqrt(1+B1*lambda.^2/(lambda.^2-C1)+B2*lambda.^2/(lambda.^2-C2)+B3*lambda.^2/(lambda.^2-C3));

        B1=1.43134930;    B2=6.50547130e-1; B3=5.34140210;
        C1=5.27992610e-3; C2=1.42382647e-2; C3=3.25017834e2;

        no=sqrt(1+B1*lambda.^2/(lambda.^2-C1)+B2*lambda.^2/(lambda.^2-C2)+B3*lambda.^2/(lambda.^2-C3));

    case 10  % LBO

        nx=sqrt(2.4542+0.01125/(lambda.^2-0.01135)-0.01388*lambda.^2);

        ny=sqrt(2.5390+0.01277/(lambda.^2-0.01189)-0.01848*lambda.^2);

        nz=sqrt(2.5865+0.01310/(lambda.^2-0.01223)-0.01861*lambda.^2);

        no=nx+1i*ny;
        nE=nz;


    case 11 % SF56
        B1=1.73562085;    B2=3.17487012e-1; B3=1.95398203;
        C1=1.29624742e-2; C2=6.12884288e-2; C3=1.61559441e2;

        n=sqrt(1+B1*lambda.^2/(lambda.^2-C1)+B2*lambda.^2/(lambda.^2-C2)+B3*lambda.^2/(lambda.^2-C3));

        no=n; nE=n;


    case 12 % LaFN28

        B1=-1.62479;    B2=0.35274;  B3=2.0709;
        C1=-852.04719;  C2=33.58031; C3=0.01247;

        n=sqrt(1+B1*lambda.^2/(lambda.^2-C1)+B2*lambda.^2/(lambda.^2-C2)+B3*lambda.^2/(lambda.^2-C3));

        no=n; nE=n;


    case 13 % LiTaO3 Tantalato da OL 28, p.194 (2003)

        A=4.502483;
        B=0.007294;
        C=0.185087;
        D=-0.02357;
        E=0.073423;
        F=0.199595;
        G=0.001;
        H=7.99724;

        %         A1=4.51224;
        %         A2=0.0847522;
        %         A3=0.19876;
        %         A4=-0.0239046;
        %
        %         B1=4.52999;
        %         B2=0.0844313;
        %         B3=0.20344;
        %         B4=-0.0237909;4

        %T = 160;

        b=3.483933e-8*(T+273.15).^2;
        c=1.607839e-8*(T+273.15).^2;

        nE=sqrt(A+(B+b)./(lambda.^2-(C+c).^2)+E./(lambda.^2-F.^2)+G./(lambda.^2-H.^2)+D*lambda.^2); % OL 28, p.194 (2003) indice solo straordinario
        no=nE;
        % no=sqrt(A1+A2./(lambda.^2-A3.^2)+A4.*lambda.^2); % indice ordinario - J. Appl. Pys. 80, 6561, 1996
        % nE=sqrt(B1+B2./(lambda.^2-B3.^2)+B4.*lambda.^2); % indice straordinario - J. Appl. Pys. 80, 6561, 1996

        %     A=4.51003265985021;
        %     B=0.08098825217233;
        %     C=0.20846733195735;
        %     D=-0.02603973989162;
        %
        %     n=sqrt(A+B./(lambda.^2-C.^2)+D*lambda.^2);


    case 14 % Borofloat

        %   B1=0.785;    B2=0.38277;  B3=-0.04529;
        %   C1=0.01444;  C2=-0.01269; C3=-0.034339;

        B1=1.13316;    B2=0;  B3=0;
        C1=0.00938;  C2=0; C3=0;

        %   n=sqrt(1+B1*lambda.^2/(lambda.^2-C1)+B2*lambda.^2/(lambda.^2-C2)+B3*lambda.^2/(lambda.^2-C3));
        n=sqrt(1+B1*lambda.^2/(lambda.^2-C1));

        no=n; nE=n;

    case 15  % TeO2

        % Indici straordinari
        B1=2.584;     B2=1.157;
        C1=0.1342.^2;    C2=0.2638.^2;

        nE=sqrt(1+B1*lambda.^2/(lambda.^2-C1)+B2*lambda.^2/(lambda.^2-C2));

        B1=2.823;     B2=1.542;
        C1=(0.1342).^2;    C2=(0.2631).^2;

        no=sqrt(1+B1*lambda.^2/(lambda.^2-C1)+B2*lambda.^2/(lambda.^2-C2));


    case 16  % SF10


        B1=1.61625977;    B2=2.59229334e-1; B3=1.07762317;
        C1=1.27534559e-2; C2=5.81983954e-2; C3=1.1660768e2;

        n=sqrt(1+B1*lambda.^2/(lambda.^2-C1)+B2*lambda.^2/(lambda.^2-C2)+B3*lambda.^2/(lambda.^2-C3));

        no=n; nE=n;


    case 17  % LiNbO3
        
        %         Ao=4.9048; Bo=0.11768; Co=0.04750; Do=0.027169;
        %         Ae=4.5820; Be=0.099169; Ce=0.04443; De=0.021950;
        %
        %         no=sqrt(Ao+Bo/(lambda.^2-Co)-Do*lambda.^2);
        %         nE=sqrt(Ae+Be/(lambda.^2-Ce)-De*lambda.^2);
        
        % Valida fino a 4 micron
        
        T=21;
        
        F=(T-24.5).*(T+570.5);
        nE=sqrt(4.582+(0.09921+5.2716*10^(-8).*F)./(lambda.^2-(0.21090-4.9143*10^(-8).*F).^2)+2.2971*10^(-7).*F-0.02194.*lambda.^2);
        
        F=(T-24.5).*(T+570.82);
        no=sqrt(4.9048+(0.11775+2.2314*10^(-8).*F)./(lambda.^2-(0.21802-2.9671*10^(-8).*F).^2)+2.1429*10^(-8).*F-0.027153.*lambda.^2);
        
        %         % Jundt (opt. Lett. vol. 22, 1553 - 1997)
        %         a1=5.35583;
        %         a2=.100473;
        %         a3=.20692;
        %         a4=100;
        %         a5=11.34927;
        %         a6=1.5334e-2;
        %         b1=4.629e-7;
        %         b2=3.862e-8;
        %         b3=-.89e-8;
        %         b4=2.657e-5;
        %
        %
        %         nE=sqrt(a1+b1*F+(a2+b2*F)./(lambda.^2-(a3+b3*F).^2)+(a4+b4*F)./(lambda.^2-a5^2)-a6*lambda.^2);


    case 18  % KBBF

        Ao=1; Bo=1.169725; Co=0.00624;   Do=0.009904;
        Ae=1; Be=0.956611; Ce=0.0061926; De=0.027849;

        no=sqrt(Ao+Bo*lambda.^2/(lambda.^2-Co)-Do*lambda.^2);
        nE=sqrt(Ae+Be*lambda.^2/(lambda.^2-Ce)-De*lambda.^2);

    case 19 % CaF2 - Dati del 2002 estrapolati da misure da 130 nm a 2.326 micron
        % valido a 20�C

        A1=4.437e-1;    A2=4.449e-1;    A3=1.501e-1;    A4=8.853;
        C1=1.78e-3;     C2=7.885e-3;    C3=1.241e-2;    C4=2.75e3;

        n=sqrt(1+A1.*lambda.^2./(lambda.^2-C1)+A2.*lambda.^2./(lambda.^2-C2)+...
            A3.*lambda.^2./(lambda.^2-C3)+A4.*lambda.^2./(lambda.^2-C4));
        no=n;
        nE=n;

    case 20 % MgF2 - dati del 1984 estrapolati da misure da 200 nm a 7 micron

        Ao1=0.48755108;     Ao2=0.39875031;     Ao3=2.3120353;
        Co1=(0.04338408)^2; Co2=(0.09461442)^2; Co3=(23.793604)^2;

        Ae1=0.41344023;     Ae2=0.50497499;     Ae3=2.4904862;
        Ce1=(0.03684262)^2; Ce2=(0.09076162)^2; Ce3=(23.771995)^2;

        no=sqrt(1+Ao1.*lambda.^2./(lambda.^2-Co1)+Ao2.*lambda.^2./(lambda.^2-Co2)+...
            Ao3.*lambda.^2./(lambda.^2-Co3));

        nE=sqrt(1+Ae1.*lambda.^2./(lambda.^2-Ce1)+Ae2.*lambda.^2./(lambda.^2-Ce2)+...
            Ae3.*lambda.^2./(lambda.^2-Ce3));

    case 21 % LiF - dati raccolti dal sito http://www.crystran.co.uk e interpolati col file LiFsellmeier (2/11/2004)

        A1=0.2076;      A2=0.7157;      A3=3.00759;
        C1=9.65e-3;     C2=4.47e-3;     C3=484.87401;

        n=sqrt(1+A1.*lambda.^2./(lambda.^2-C1)+A2.*lambda.^2./(lambda.^2-C2)+...
            A3.*lambda.^2./(lambda.^2-C3));
        no=n;
        nE=n;


    case 22 % GaAs - JOURNAL OF APPLIED PHYSICS 94 (2003)
        
        DT=22-T; % Deviation from 22�C
                
        l1=0.4431307+0.000050564*DT;
        l2=0.8746453+0.0001913*DT-4.882e-7*DT^2;
        l3=36.9166-0.011622*DT;
        
        g0=5.372514;
        g1=27.83972;
        g2=0.031764+4.350e-5*DT+4.664e-7*DT^2;
        g3=0.00143636;
        
        %         A=8.950;
        %         B=2.054;
        %         C=0.390;
        %
        %         n=sqrt(A+B.*lambda.^2/(lambda.^2-C));
        
        n=sqrt(g0+g1.*lambda.^2*l1^2/(lambda.^2-l1^2)+...
                  g2.*lambda.^2*l2^2/(lambda.^2-l2^2)+...
                  g3.*lambda.^2*l3^2/(lambda.^2-l3^2));
        
        no=n;
        nE=n;

    case 23 % YVO4

        A1=3.77834;    B1=0.069736;     C1=0.04724;    D1=-0.0108133;
        A2=4.59905;    B2=0.110534;     C2=0.04813;    D2=-0.0122676;

        no=sqrt(A1+B1./(lambda.^2-C1)+D1*lambda);
        nE=sqrt(A2+B2./(lambda.^2-C2)+D2*lambda);

    case 24 % Si

%         E=1.16858e1; A=9.39816e-1;  B=8.10461e-3;  l1=1.1071;
% 
%         n=sqrt(E+A./lambda.^2+(B*l1^2)./(lambda.^2-l1^2)); Unknown source
        
        n = sqrt( 1 + 10.6684293.*lambda.^2./(lambda.^2-0.301516485^2) + ...
            0.003043475*lambda.^2./(lambda.^2-1.13475115^2) + 1.54133408*lambda.^2./(lambda.^2-1104.0^2) );

        % Handbook of Optics, 3rd edition, Vol. 4. McGraw-Hill 2009

        no=n;
        nE=n;

    case 25 % Ge
        % il Ge taglia nel vicino IR

        T=300;

        A=-6.040e-3*T+11.05128;
        B=9.295e-3*T+4.00536;
        C=-5.392e-4*T+0.599034;
        D=4.151e-4*T+0.09145;
        E=1.51408*T+3426.5;

        n=sqrt(A+(B*lambda.^2)./(lambda.^2-C)+(D*lambda.^2)./(lambda.^2-E));

        no=n;
        nE=n;

    case 26 % TeO2 alternativo

        Ao=3.71789; Bo=0.07544; Co=0.19619; Do=4.61196;
        Ae=4.33449; Be=0.14739; Ce=0.20242; De=4.93667;

        no=sqrt(1+(Ao*lambda.^2)./(lambda.^2-Co^2)+(Bo*lambda.^2)./(lambda.^2-Do^2));
        nE=sqrt(1+(Ae*lambda.^2)./(lambda.^2-Ce^2)+(Be*lambda.^2)./(lambda.^2-De^2));

    case 27 % CdTe  % N. P. Barnes and M. S. Piltch, "Temperature-dependent Sellmeier coefficients and coherence length for cadmium telluride*," J. Opt. Soc. Am. 67, 628-629 (1977)

        T=300;

        A=-2.973e-4*T+3.8466;
        B=8.057e-4*T+3.2215;
        C=-1.10e-4*T+0.1866;
        D=-2.160e-2*T+12.718;
        E=-3.160e1*T+18753;
        
        n=sqrt(A+(B*lambda.^2)./(lambda.^2-C)+(D*lambda.^2)./(lambda.^2-E));
        
        no=n;
        nE=n;
        
    case 28 % ZnSe 
        
        T=300;
        
        % Wrong at 17 microns
        %         A=4;
        %         B=1.9;
        %         C=0.113;
        %
        %         n=sqrt(A+(B*lambda.^2)./(lambda.^2-C)); % errore sperimentale � 0.002
        
        % B. Tatian. Fitting refractive-index data with the Sellmeier dispersion formula, Appl. Opt. 23, 4477-4485 (1984) fits data from
	% J. Connolly, B. diBenedetto, and R. Donadio. Specifications of Raytran material, Proc. SPIE, 181, 141-144 (1979)
        A1=4.45813734;     A2=4.67216334e-1; A3=2.89566290;
        B1=2.00859853e-1;  B2=3.91371166e-1; B3=4.71362108e+1;
        
        n=sqrt(1+(A1*lambda.^2)./(lambda.^2-B1^2)+(A2*lambda.^2)./(lambda.^2-B2^2)+(A3*lambda.^2)./(lambda.^2-B3^2));
        
% %         % from G. Hawkins, R. Hunneman
% %         % Infrared Physics & Technology 45 (2004) 69�79
% %         A=1.509e-4*T+2.407; B=1.801e-5*T-2.564e-4; C=1.300e-6*T-1.308e-5; D=-3.878e-8*T-1.480e-5;
% %         n=A+B*lambda+C*lambda.^2+D*lambda.^3;

        no=n;
        nE=n;
        
    case 29 % ZnS
        
        A1=3.60981117;  A2=4.90409060e-1;  A3=2.73290892;
        C1=1.69807804e-1; C2=3.02036761e-1;  C3=3.38906653e1;

        n=sqrt(1+A1.*lambda.^2./(lambda.^2-C1^2)+A2.*lambda.^2./(lambda.^2-C2^2)+...
            A3.*lambda.^2./(lambda.^2-C3^2));

        no=n;
        nE=n;

    case 30 % TiO2 Fit dati sperimentali

        B = 0.23278006304849;
        C = 0.08100392082020;
        D =-0.03720107393751;
        A = 5.96187765161566;

        n=sqrt(A+B./(lambda.^2-C)+D*lambda.^2);

        no=n;
        nE=n;

    case 31 % 7%MgO:LiNbO3 (Lin et al., IEEE J. Quantum Electron. 32, 124-126 1996)

        A = 4.86687;
        B = 0.11916;
        C = 0.04263;
        D =-0.02751;

        no=sqrt(A+B./(lambda.^2-C)+D*lambda.^2);

        A = 4.54686;
        B = 0.09478;
        C = 0.04539;
        D =-0.02672;

       nE=sqrt(A+B./(lambda.^2-C)+D*lambda.^2);

       plot(lambda,no,lambda,nE);
       
    case 32 % KNbO3 (biassico, G. Ghosh, APL 65, 3311 1994)

        A = 2.5499454;
        B = 2.2847207;
        C = 5.6363148e-2;
        D = 6.0453039;
        E = 250;

        na=sqrt(A+B/(1-C/lambda^2)+D/(1-E/lambda^2));
        
        A = 2.6318668;
        B = 2.3549226;
        C = 6.4391208e-2;
        D = 6.8615403;
        E = 250;

        nb=sqrt(A+B/(1-C/lambda^2)+D/(1-E/lambda^2));

        A = 2.5605749;
        B = 1.8596424;
        C = 5.4154821e-2;
        D = 4.6675402;
        E = 250;

        nc=sqrt(A+B/(1-C/lambda^2)+D/(1-E/lambda^2));

        no=nc+1i*na;
        nE=nb;


%         nx=sqrt(1+3.38361*lambda.^2/(lambda.^2-0.03448));
%         ny=sqrt(1+3.79361*lambda.^2/(lambda.^2-0.03877));
%         nz=sqrt(1+3.93281*lambda.^2/(lambda.^2-0.04486));
%         no=nx+i*ny;
%         nE=nz;

    case 33 % KTP (biassico, Kato et al., IEEE J. Quantum Electron. 27, 1137 1991)

        A = 3.0065;
        B = 0.03901;
        C = 0.04251;
        D = -0.01327;

        nx=sqrt(A+B/(lambda^2-C)+D*lambda^2);

        A = 3.0333;
        B = 0.04154;
        C = 0.04547;
        D = -0.01408;

        ny=sqrt(A+B/(lambda^2-C)+D*lambda^2);

        A = 3.3134;
        B = 0.05694;
        C = 0.05658;
        D = -0.01682;

        nz=sqrt(A+B/(lambda^2-C)+D*lambda^2);  %% E' il pi� alto

        no=nx+1i*ny;
        nE=nz;
        
   case 34 % LiIO3, K. Kato: IEEE J. QE-21, 119 (1985)

        A = 2.083648;
        B = 1.332068;
        C = 0.035306;
        D =-0.008525;
        
        no=sqrt(A+(B.*lambda.^2)./(lambda.^2-C)+D*lambda.^2);

        A = 1.673463;
        B = 1.245229;
        C = 0.028224;
        D =-0.003641;

        nE=sqrt(A+(B.*lambda.^2)./(lambda.^2-C)+D*lambda.^2);
         
    case 35 % LiIO3 (2) V. I. Kabelka et al.: Kvantovaya Elektron. 2, 434 (1975)
        A = 3.415716;
        B = 0.047031;
        C = 0.035306;
        D =-0.008801;
        
        no=sqrt(A+B./(lambda.^2-C)+D*lambda.^2);
        
        A = 2.918692;
        B = 0.035145;
        C = 0.028224;
        D =-0.003641;

        nE=sqrt(A+B./(lambda.^2-C)+D*lambda.^2);

    case 36 % 5% MgO:LiNbO3 (Zelmon JOSA B 14 p.3319, ad una temperatura di 21�C, valida fino a 5 micron

        A=2.2454;
        B=.01242;
        C=1.3005;
        D=.05313;
        E=6.8972;
        F=331.33;
        nE=sqrt(1+A*lambda.^2./(lambda.^2-B)+C*lambda.^2./(lambda.^2-D)+E*lambda.^2./(lambda.^2-F));

        A=2.4272;
        B=.01478;
        C=1.4617;
        D=0.05612;
        E=9.6536;
        F=371.216;
        no=sqrt(1+A*lambda.^2./(lambda.^2-B)+C*lambda.^2./(lambda.^2-D)+E*lambda.^2./(lambda.^2-F));
               
    case 37  % GaSe, seleniuro di Gallio
        
        % from OPTICS EXPRESS 14, 10644 (2006), valide da 2.4 a 35 micron 
        
        % Indici straordinari
        A1=5.187;    B1=0.4634;   C1=-0.232;
        D1=0.1083; E1=1.8105; F1=1801.65;
        
        nE=sqrt(A1+B1*lambda.^-2+C1*lambda.^(-4)+D1*lambda.^(-6)+E1*lambda.^2/(lambda.^2-F1));
        
        % Indici ordinari
        A2=6.8517;    B2=0.4558;   C2=0.0143;
        D2=0.0043;    E2=3.6187;   F2=2210.7;
        
        no=sqrt(A2+B2*lambda.^-2+C2*lambda.^(-4)+D2*lambda.^(-6)+E2*lambda.^2/(lambda.^2-F2));
        
%        both approaches are very similar: less than 2% difference

%         % from OPTICS COMMUNICATIONS 118, 375 (1995), valide da 0.6 a 18 micron 
%         
%         % Indici straordinari
%         A1=5.760;    B1=0.3879;   C1=-0.2288;
%         D1=0.1223; E1=1.855; F1=1780;
%         
%         nE=sqrt(A1+B1*lambda.^-2+C1*lambda.^(-4)+D1*lambda.^(-6)+E1*lambda.^2/(lambda.^2-F1));
%         
%         % Indici ordinari 
%         A2=7.443;    B2=0.4050;   C2=0.0186;
%         D2=0.0061;    E2=3.1485;   F2=2194;
%         
%         no=sqrt(A2+B2*lambda.^-2+C2*lambda.^(-4)+D2*lambda.^(-6)+E2*lambda.^2/(lambda.^2-F2));
        
    case 38 % Water Masumura APPLIED OPTICS 46  (June 2007)
        
        % Coeff. per 20�C
        
        A1=5.684027565e-1;
        A2=1.726177391e-1;
        A3=2.086189578e-2;
        A4=1.130748688e-1;
        B1=5.101829712e-3;
        B2=1.821153936e-2;
        B3=2.620722293e-2;
        B4=1.069792721e1;
        
        n=sqrt(1+A1*lambda.^2./(lambda.^2-B1)+A2*lambda.^2./(lambda.^2-B2)+...
            A3*lambda.^2./(lambda.^2-B3)+A4*lambda.^2./(lambda.^2-B4));

        no=n; nE=n;
        
    case 39  % Calcite, from CASIX website
        
        no = sqrt(2.69705 + 0.0192064/(lambda.^2 - 0.01820) - 0.0151624*lambda.^2);
        nE = sqrt(2.18438 + 0.0087309/(lambda.^2 - 0.01018) - 0.0024411*lambda.^2);
  
    case 40 % Aria

        A1=0.00057378;
        B1=595260e-8;

        n=sqrt(1+A1*lambda.^2./(lambda.^2-B1));

        no=n; nE=n;

        % Inserire aria con coeff di Ciddar
        
    case 41 % SF11 % Fonte sconosciuta
        
        A=1.73848403; B=0.01360686; C=0.31116897;
        D=0.06159605; E=1.17490871; F=121.922711;
        
        n=sqrt(1+A*lambda.^2./(lambda.^2-B)+C*lambda.^2./(lambda.^2-D)+...
            E*lambda.^2./(lambda.^2-F));
        
        no=n; nE=n;

    case 42 % alpha-BBO
        
        no=sqrt(2.7471+0.01878./(lambda.^2-0.01822)-0.01354.*lambda.^2);
        nE=sqrt(2.3174+0.01224./(lambda.^2-0.01667)-0.01516.*lambda.^2);
        
    case 43 % ZnTe
        
        if lambda<60 % Valid from 0.56 to 30 microns and from 184 to 541
        % microns
        no=sqrt(9.92 + 0.42530./(lambda.^2-0.37766^2) +...
            2.63580./(lambda.^2/56.5^2-1));
        end;

        if lambda>=60
            
            T=T+273.15; % in K
            ATO=5.409; BTO=-0.0457; CTO=-0.0341;
            Adc=9.624; Bdc=0.1583; Cdc=0.1318;
            
            NuTO=ATO+BTO*(T/255)+CTO*(T/255)^2;
            edc=Adc+Bdc*(T/255)+Cdc*(T/255)^2;
            
            einf=6.7;
            
            Nu=(3e8./(lambda*1e-6))/1e12; % in THz
            
            no=sqrt(einf + ((edc-einf)*NuTO^2) ./ (NuTO^2-Nu.^2));
            
        end;
        
        nE=no;

    case 44  % YAG
        
        % David E. Zelmon, David L. Small and Ralph Page
        % Refractive-index measurements of undoped yttrium aluminum garnet from 0.4 to 5.0 um
        % Applied Optics, Vol.37, No.21, Pag.4933-4935, 20 July 1998
        
        A=2.282;     B=0.01185;      C=3.27644;     D=282.734;
        
        n=sqrt(1+A*lambda.^2/(lambda.^2-B)+C*lambda.^2/(lambda.^2-D));
        
        no=n; nE=n;
        
    case 45  % CdGeAs2
        
        % Handbook of Optics, 3rd edition, Vol. 4. McGraw-Hill 2009
        
        nE = sqrt( 11.8018 + 1.2152*lambda.^2./(lambda.^2-2.6971) + 1.6922*lambda.^2./(lambda.^2-1370) );
        no = sqrt( 10.1064 + 2.2988*lambda.^2./(lambda.^2-1.0872) + 1.6247*lambda.^2./(lambda.^2-1370) );
        
    case 46 % Argon
        
        B1=20332.29*1e-8; C1=206.12e-6; B2=34458.31e-8; C2=8.066e-3;
        p0=1e5; % Pascal
        T0=273;  % Kelvin
        
        p=1.013e5;
        T=300;
        
        n=sqrt(1+ p/p0*T0/T*(B1.*lambda.^2/(lambda.^2-C1)+B2*lambda.^2/(lambda.^2-C2)) );
        
        no=n; nE=n;
        
    case 47  % Calomel (da Z. B. Perekalina, C. Barta, I. Gretora, A. B. Wasiljew, and I. D.Kislowskij, Opt. Spectrosc. USSR 42, 653– 655 (1977)
        % o anche: Milton Gottlieb, A. P. Goutzoulis, and N. B. Singh, "Fabrication and characterization of mercurous chloride acoustooptic devices," Appl. Opt. 26, 4681-4687 (1987)
        
        no = sqrt( 1 + 2.595*lambda.^2./(lambda.^2-0.03648) );
        nE = sqrt( 1 + 2.490*lambda.^2./(lambda.^2-0.08237) + 2.479*lambda.^2./(lambda.^2-0.03803) );
        
    case 48 % KBr Potassium Bromide 0.5-20 micron
        
        n = sqrt( 1.39408 + 0.79221*lambda.^2./(lambda.^2-0.146^2) + 0.01981*lambda.^2./(lambda.^2-0.173^2) + ...
            0.15587*lambda.^2./(lambda.^2-0.187^2) + 0.17673*lambda.^2./(lambda.^2-60.61^2) + 2.06217*lambda.^2./(lambda.^2-87.72^2) );
        % Handbook of Optics, 3rd edition, Vol. 4. McGraw-Hill 2009
        
        no=n; nE=n;
        
    case 49 % KCL Potassium Chloride 0.5-20 micron
            
        n = sqrt( 1.26486 + 0.30523*lambda.^2./(lambda.^2-0.100^2) + ...
            0.41620*lambda.^2./(lambda.^2-0.131^2) + ...
            0.18870*lambda.^2./(lambda.^2-0.162^2) + 2.6200*lambda.^2./(lambda.^2-70.42^2) ); 
        
        no=n; nE=n;
        
    case 50 % CdSe (1-22 micron))
        
        no = sqrt( 4.2243 + 1.7680*lambda.^2/(lambda.^2-0.2270) + 3.1200*lambda.^2/(lambda.^2-3380) );
        nE = sqrt( 4.2009 + 1.8875*lambda.^2/(lambda.^2-0.2171) + 3.6461*lambda.^2/(lambda.^2-3629) );
        
    case 51 % CdS  
        
        % (0.51~1.4 micron)
        % no = sqrt( 5.1792 + 0.23504/(lambda.^2-0.083591) + 0.036927/(lambda.^2-0.23504) );
        % nE = sqrt( 5.2599 + 0.20865/(lambda.^2-0.10799) + 0.027527/(lambda.^2-0.23305) );
        
        % (2.5~15 micron)
        % From
        % http://www.issp.ac.ru/lpcbc/DANDP/CdS%20&%20CdSe%20birefringence%20&%20Sellmeier.html
        no = sqrt( 3.7255 + 1.4491*lambda.^2/(lambda.^2-0.16339) + 1.2612*lambda.^2/(lambda.^2-733.21) );
        nE = sqrt( 3.6522 + 1.5975*lambda.^2/(lambda.^2-0.14526) + 1.4869*lambda.^2/(lambda.^2-794.56) );
        
    case 52
        
        no=sqrt(1+0.643356./(1-(0.057789./lambda).^2)+0.506762./(1-(0.10968./lambda).^2)+3.8261./(1-(46.3864./lambda).^2));
        nE=no;
       
        
    case 53 % KTA, from J. Opt. Soc. Am. B 17, 775-780 (2000)
        
        Ax=2.1495;
        Bx=1.0203;
        Cx=0.042378;
        Dx=0.5531;
        Ex=72.3045;
        px=1.9951;
        qx=1.9567;
        
        Ay=2.1308;
        By=1.0564;
        Cy=0.042523;
        Dy=0.6927;
        Ey=54.8505;
        py=2.0017;
        qy=1.7261;
        
        Az=2.1931;
        Bz=1.2382;
        Cz=0.059171;
        Dz=0.5088;
        Ez=53.2898;
        pz=1.8920;
        qz=2.0000;
        
        nx=sqrt(...
            Ax+Bx.*lambda.^px./(lambda.^px-Cx)+...
            Dx.*lambda.^qx./(lambda.^qx-Ex)...
            );
        
        ny=sqrt(...
            Ay+By.*lambda.^py./(lambda.^py-Cy)+...
            Dy.*lambda.^qy./(lambda.^qy-Ey)...
            );
        
        nz=sqrt(...
            Az+Bz.*lambda.^pz./(lambda.^pz-Cz)+...
            Dz.*lambda.^qz./(lambda.^qz-Ez)...
            );
        
        no=nx+1i*ny;
        nE=nz;
        
    case 54 % KTA, XZ, from J. Opt. Soc. Am. B 17, 775-780 (2000)
        
        Ax=2.1495;
        Bx=1.0203;
        Cx=0.042378;
        Dx=0.5531;
        Ex=72.3045;
        px=1.9951;
        qx=1.9567;
        
        Ay=2.1308;
        By=1.0564;
        Cy=0.042523;
        Dy=0.6927;
        Ey=54.8505;
        py=2.0017;
        qy=1.7261;
        
        Az=2.1931;
        Bz=1.2382;
        Cz=0.059171;
        Dz=0.5088;
        Ez=53.2898;
        pz=1.8920;
        qz=2.0000;
        
        nx=sqrt(...
            Ax+Bx.*lambda.^px./(lambda.^px-Cx)+...
            Dx.*lambda.^qx./(lambda.^qx-Ex)...
            );
        
        ny=sqrt(...
            Ay+By.*lambda.^py./(lambda.^py-Cy)+...
            Dy.*lambda.^qy./(lambda.^qy-Ey)...
            );
        
        nz=sqrt(...
            Az+Bz.*lambda.^pz./(lambda.^pz-Cz)+...
            Dz.*lambda.^qz./(lambda.^qz-Ez)...
            );
        
        no=nx;
        nE=nz;
        
    case 55 % ZF4
                
        A0 = 2.87833860;
        A1 = - 1.18585043e-2;
        A2 = 3.41292688e-2;
        A3 = 1.67815401e-3;
        A4 = - 5.56455694e-5;
        A5 = 1.43620134e-5;
        
        n=sqrt(A0 + A1.*lambda.^2 + A2.*lambda.^-2 + A3.*lambda.^-4 + A4.*lambda.^-6 + A5.*lambda.^-8);
        
        no=n; nE=n;
        
        
    case 60  % CLBO modificato
        
        Ao=2.2049;   Bo=1.10259e-2;  Co=0.018119;  Do=6.95625e-5;
        Ae=2.05936;  Be=8.64948e-3;  Ce=0.0128929;  De=2.67532e-5;

        A1o=2.14318; B1o=0.158749;   C1o=-1.37559;  D1o=6.2375e-4;
        A1e=2.04195; B1e=2.73245e-2; C1e=-0.286672; D1e=3.42718e-4;

        if lambda<0.633

            o1=Ao;
            o2=Bo/(lambda.^2-Co);
            o3=Do*lambda.^2;

            e1=Ae;
            e2=Be/(lambda.^2-Ce);
            e3=De*lambda.^2;

            no=sqrt(o1+o2-o3);
            nE=sqrt(e1+e2-e3);

        else

            o1=A1o;
            o2=B1o/(lambda.^2-C1o);
            o3=D1o*lambda.^2;

            e1=A1e;
            e2=B1e/(lambda.^2-C1e);
            e3=D1e*lambda.^2;

            no=sqrt(o1+o2-o3);
            nE=sqrt(e1+e2-e3);

        end;

end; % switch

%plot(lambda,no,lambda,nE);

n=[no nE];
